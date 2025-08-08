ARG BASE_TAG=${BASE_TAG:-latest}
FROM ghcr.io/samvera/hyku/base:${BASE_TAG} AS hyku-knap-base
# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
RUN ln -sf /app/samvera/bundler.d /app/.bundler.d
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true

RUN jobs=$(nproc) && \
    if [ "$jobs" -gt 2 ]; then jobs=2; fi && \
    bundle install --jobs "$jobs" --retry 3

USER root

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    wget https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata -O /usr/share/tesseract-ocr/5/tessdata/eng_best.traineddata && \
    git config --global --add safe.directory "/app/samvera"

USER app

FROM hyku-knap-base AS hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install

CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker

FROM solr:8.3 AS hyku-solr
ENV SOLR_USER="solr" \
    SOLR_GROUP="solr"
USER root
COPY --chown=solr:solr solr/security.json /var/solr/data/security.json
USER $SOLR_USER