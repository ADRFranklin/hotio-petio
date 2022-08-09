FROM --platform=linux/amd64 node:16.13.2-alpine3.15 as builder

RUN apk add --no-cache git curl python3 build-base
ARG GITHUB_TOKEN
ARG VERSION
RUN mkdir /source && \
    curl -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" -fsSL "https://github.com/petio-team/petio/archive/${VERSION}.tar.gz" | tar xzf - -C "/source" --strip-components=1 && \
    npm i -g typescript && \
    cd /source/pkg/admin && \
    npm i --legacy-peer-deps && \
    npm run build && \
    cd /source/pkg/frontend && \
    npm i --legacy-peer-deps && \
    npm run build && \
    cd /source/pkg/api && \
    npm i --legacy-peer-deps && \
    npm run build && \
    chmod -R u=rwX,go=rX /source/pkg


FROM cr.hotio.dev/hotio/base@sha256:395f6abf5a3965353a307032ca2dc4dafa66a048b1358211dec6d6b6fb8d2ed7
EXPOSE 7777
RUN apk add --no-cache nodejs

COPY --from=builder /source/pkg/frontend/build /app/views/frontend
COPY --from=builder /source/pkg/admin/build /app/views/admin
COPY --from=builder /source/pkg/api/dist /app/api
COPY --from=builder /source/pkg/api/node_modules /app/api/node_modules

COPY root/ /
