# syntax=docker/dockerfile:1

# Build stage - compile ckpool from source
FROM alpine:3.21 AS builder

RUN apk add --no-cache \
    autoconf \
    automake \
    build-base \
    git \
    libcap \
    libcap-dev \
    libtool \
    pkgconf

RUN git clone https://github.com/jamestrichardson/ckpool.git /tmp/ckpool

WORKDIR /tmp/ckpool

RUN ./autogen.sh && \
    ./configure --prefix=/app && \
    make && \
    make install

# Runtime stage
FROM alpine:3.21

ARG S6_OVERLAY_VERSION="3.2.1.0"

RUN apk add --no-cache \
    bash \
    libcap \
    tzdata \
    xz && \
    ARCH=$(uname -m) && \
    wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -O /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz" -O /tmp/s6-overlay-arch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm -rf /tmp/*.tar.xz && \
    apk del xz

COPY --from=builder /app/bin/ckpool /app/bin/ckpool
COPY --from=builder /app/bin/ckpmsg /app/bin/ckpmsg
COPY --from=builder /app/bin/notifier /app/bin/notifier

COPY root/ /

VOLUME /config

EXPOSE 3333

ENTRYPOINT ["/init"]
