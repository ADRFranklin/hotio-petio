FROM node:14.15.1-alpine3.12 as builder

RUN apk add --no-cache git curl python3 build-base
ARG GITHUB_TOKEN
ARG VERSION
RUN mkdir /source && \
    curl -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" -fsSL "https://github.com/petio-team/petio/archive/${VERSION}.tar.gz" | tar xzf - -C "/source" --strip-components=1 && \
    mkdir /build && \
    cp /source/petio.js /build/ && \
    cp /source/router.js /build/ && \
    cp /source/package.json /build/ && \
    cd /build && \
    npm install && \
    cp -R /source/frontend /build/ && \
    cp -R /source/admin /build/ && \
    cp -R /source/api /build/ && \
    cd /build/frontend && \
    npm install && npm run build && \
    cd /build/admin && \
    npm install && npm run build && \
    cd /build/api && \
    npm install && \
    cd /build && \
    mkdir /build/views && \
    mv /build/frontend/build /build/views/frontend && rm -rf /build/frontend && \
    mv /build/admin/build /build/views/admin && rm -rf /build/admin && \
    chmod -R u=rwX,go=rX /build


FROM ghcr.io/hotio/base@sha256:cebb8cd25b2e363f9d63f062833af6b8fc475b6c3ce9f898f1a681930cfd3fc1
EXPOSE 7777
RUN apk add --no-cache nodejs
COPY --from=builder /build/ /app/
RUN ln -s "${CONFIG_DIR}/logs/" "${APP_DIR}/logs" && \
    ln -s "${CONFIG_DIR}" "${APP_DIR}/api/config"
COPY root/ /
