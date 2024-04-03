FROM ghcr.io/samvera/hyku/base:latest as hyku-knap-base

# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
COPY --chown=1001:101 bundler.d/ /app/.bundler.d/
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true

RUN bundle install --jobs "$(nproc)"

# Ensure root permissions for installing Tesseract data
USER root

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    wget https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata -O /usr/share/tessdata/eng_best.traineddata

# Switch back to the non-root user for running the application
USER app

FROM hyku-knap-base as hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install

CMD ./bin/web

FROM hyku-web as hyku-worker
CMD ./bin/worker
