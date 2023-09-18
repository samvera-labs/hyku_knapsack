FROM ghcr.io/samvera/hyku/base:latest as hyku-web
ARG APP_PATH
COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
RUN git config --global --add safe.directory /app/samvera && \
  bundle install --jobs "$(nproc)"

COPY --chown=1001:101 $APP_PATH/bin/db-migrate-seed.sh /app/samvera/
# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera

RUN RAILS_ENV=production SECRET_KEY_BASE=`bin/rake secret` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile && yarn install
CMD ./bin/web

FROM hyku-web as hyku-worker
CMD ./bin/worker
