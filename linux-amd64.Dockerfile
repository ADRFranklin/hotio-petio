FROM --platform=linux/amd64 node:16.13.2-alpine3.15 as builder

RUN apk add --no-cache git curl python3 build-base
ARG GITHUB_TOKEN
ARG VERSION
RUN mkdir /source && \
    curl -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" -fsSL "https://github.com/petio-team/petio/archive/${VERSION}.tar.gz" | tar xzf - -C "/source" --strip-components=1 && \
    npm i -g typescript ts-node && \
    cd /source/pkg/admin && \
    npm i && \
    npm run build && \
    cd /source/pkg/frontend && \
    npm i && \
    npm run build && \
    cd /source/pkg/api && \
    npm i && \
    chmod -R u=rwX,go=rX /source/pkg


FROM cr.hotio.dev/hotio/base@sha256:a5b4a850b6128d497dd55ea28290133352a80b9992a29e0a6e7918b4021d2ab5
EXPOSE 7777
RUN apk add --no-cache nodejs

COPY --from=builder /source/pkg/frontend/build /app/views/frontend
COPY --from=builder /source/pkg/admin/build /app/views/admin
COPY --from=builder /source/pkg/api/dist /app/api
COPY --from=builder /source/pkg/api/node_modules /app/api/node_modules

RUN ln -s "${CONFIG_DIR}/logs/" "${APP_DIR}/logs" && \
    ln -s "${CONFIG_DIR}" "${APP_DIR}/api/config" && \
    ln -s "${CONFIG_DIR}/imdb_dump.txt" "${APP_DIR}/api/imdb_dump.txt"

COPY root/ /
