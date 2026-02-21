# syntax=docker/dockerfile:1

# Build stage - compile ckpool from source
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    git \
    libcap-dev \
    libtool \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/jamestrichardson/ckpool.git /tmp/ckpool

WORKDIR /tmp/ckpool

RUN ./autogen.sh && \
    ./configure --prefix=/app && \
    make && \
    make install

# Runtime stage
FROM debian:bookworm-slim

ARG S6_OVERLAY_VERSION="3.2.1.0"
# TARGETARCH is set automatically by Docker BuildKit (amd64, arm64, arm, etc.)
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    libcap2 \
    tzdata \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Map Docker's TARGETARCH to s6-overlay's archive naming and install
RUN case "${TARGETARCH}" in \
      amd64)   S6_ARCH="x86_64"  ;; \
      arm64)   S6_ARCH="aarch64" ;; \
      arm)     S6_ARCH="armhf"   ;; \
      386)     S6_ARCH="i486"    ;; \
      *)       S6_ARCH="${TARGETARCH}" ;; \
    esac \
    && wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
            -O /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && wget -q "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
            -O /tmp/s6-overlay-${S6_ARCH}.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz \
    && rm -rf /tmp/s6-overlay-*.tar.xz

COPY --from=builder /app/bin/ckpool /app/bin/ckpool
COPY --from=builder /app/bin/ckpmsg /app/bin/ckpmsg
COPY --from=builder /app/bin/notifier /app/bin/notifier

COPY root/ /

VOLUME /config

EXPOSE 3333

ENTRYPOINT ["/init"]
