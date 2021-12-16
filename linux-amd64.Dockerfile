FROM --platform=linux/amd64 node:16.3.0-alpine3.13 as builder

RUN apk add --no-cache git curl python3 build-base
ARG GITHUB_TOKEN
ARG VERSION
RUN mkdir /source && \
    curl -u "${GITHUB_ACTOR}:${GITHUB_TOKEN}" -fsSL "https://github.com/petio-team/petio/archive/${VERSION}.tar.gz" | tar xzf - -C "/source" --strip-components=1

WORKDIR /build
RUN cp /source/petio.js . && \
    cp /source/router.js . && \
    cp /source/package.json . && \
    npm install && \
    cp -R /source/frontend . && \
    cp -R /source/admin . && \
    cp -R /source/api .

WORKDIR /build/frontend
RUN npm install && \
    npm run build

WORKDIR /build/admin
RUN npm install --legacy-peer-deps && \
    npm run build

WORKDIR /build/api
RUN npm install --legacy-peer-deps

WORKDIR /build/views
RUN mv /build/frontend/build /build/views/frontend && \
    rm -rf /build/frontend && \
    mv /build/admin/build /build/views/admin && \
    rm -rf /build/admin && \
    chmod -R u=rwX,go=rX /build


FROM cr.hotio.dev/hotio/base@sha256:a5b4a850b6128d497dd55ea28290133352a80b9992a29e0a6e7918b4021d2ab5
EXPOSE 7777
RUN apk add --no-cache nodejs
COPY --from=builder /build/ /app/
RUN ln -s "${CONFIG_DIR}/logs/" "${APP_DIR}/logs" && \
    ln -s "${CONFIG_DIR}" "${APP_DIR}/api/config"
COPY root/ /
