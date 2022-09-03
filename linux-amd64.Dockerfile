FROM --platform=linux/amd64 node:18.8.0-alpine3.15 as builder

RUN apk add --no-cache git curl python3 build-base
ARG GITHUB_TOKEN
ARG VERSION
RUN mkdir /source && \
    curl -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" -fsSL "https://github.com/petio-team/petio/archive/${VERSION}.tar.gz" | tar xzf - -C "/source" --strip-components=1 && \
    yarn add typescript && \
    yarn workspaces focus --all && \
    yarn workspace frontend run build && \
    yarn workspace admin run build && \
    yarn workspace api run build:prod && \
    chmod -R u=rwX,go=rX /source/pkg


FROM cr.hotio.dev/hotio/base@sha256:2d9fc1f1bab038667b32091957c25ad15301f73f9392c742c0ab273da68a18ed
EXPOSE 7777
RUN apk add --no-cache nodejs

COPY --from=builder /source/pkg/frontend/build /app/views/frontend
COPY --from=builder /source/pkg/admin/build /app/views/admin
COPY --from=builder /source/pkg/api/dist /app/api
COPY --from=builder /source/pkg/api/package.json /app/api/package.json

COPY root/ /