ARG HYRAX_IMAGE_VERSION=hyrax-v5.2.0
FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION AS hyku-web

USER root
RUN git config --system --add safe.directory \*
ENV PATH="/app/samvera/bin:${PATH}"

USER app
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV MALLOC_CONF='dirty_decay_ms:1000,narenas:2,background_thread:true'

ENV TESSDATA_PREFIX=/app/samvera/tessdata
ADD https://github.com/tesseract-ocr/tessdata_best/blob/main/eng.traineddata?raw=true /app/samvera/tessdata/eng_best.traineddata

############### KNAPSACK SPECIFIC CODE ###################
# This means bundler inject looks at /app/samvera/.bundler.d for overrides
ENV HOME=/app/samvera
# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true
RUN bundle install --jobs "$(nproc)"
############## END KNAPSACK SPECIFIC CODE ################

RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install
CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker