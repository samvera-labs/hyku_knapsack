FROM ghcr.io/samvera/hyku/base:latest AS hyku-knap-base

# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
COPY --chown=1001:101 bundler.d/ /app/.bundler.d/
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true
ENV BUNDLE_BUNDLER_INJECT__GEM_PATH=/app/samvera/bundler.d

RUN bundle install --jobs "$(nproc)"

# Ensure root permissions for installing Tesseract data
USER root

# Install "best" training data for Tesseract
RUN echo "📚 Installing Tesseract Best (training data)!" && \
    wget https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata -O /usr/share/tessdata/eng_best.traineddata && \
    git config --global --add safe.directory /app/samvera

# Knapsack workaround for instllation of ghostscript a requirement of pdf derivative creation process.
# It is installed in Hyku's Dockerfile but still doesn't get installed in the knapsack. Might be a path issue.
RUN apt-get update && \
    apt-get install -y ghostscript

# Switch back to the non-root user for running the application
USER app

FROM hyku-knap-base AS hyku-web
RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install

CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker
