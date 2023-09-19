FROM ghcr.io/samvera/hyku/base:latest as hyku-web

# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
CMD ./bin/web

FROM hyku-web as hyku-worker
CMD ./bin/worker
