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
    libcap2-bin \
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

# Install runtime deps, download and verify s6-overlay, then clean up download tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    libcap2 \
    tzdata \
    curl \
    xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && case "${TARGETARCH}" in \
         amd64)   S6_ARCH="x86_64"  ;; \
         arm64)   S6_ARCH="aarch64" ;; \
         arm)     S6_ARCH="armhf"   ;; \
         386)     S6_ARCH="i486"    ;; \
         *)       S6_ARCH="${TARGETARCH}" ;; \
       esac \
    && echo "==> TARGETARCH=${TARGETARCH} S6_ARCH=${S6_ARCH} S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION}" \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" \
            -o /tmp/s6-overlay-noarch.tar.xz \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" \
            -o /tmp/s6-overlay-${S6_ARCH}.tar.xz \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" \
            -o /tmp/s6-overlay-symlinks-noarch.tar.xz \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" \
            -o /tmp/s6-overlay-symlinks-arch.tar.xz \
    && echo "==> Extracting s6-overlay tarballs" \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz \
    && rm -rf /tmp/s6-overlay-*.tar.xz \
    && apt-get purge -y --auto-remove curl xz-utils \
    && test -x /command/with-contenv  || { echo "ERROR: s6-overlay noarch not installed correctly"; exit 1; } \
    && test -x /command/s6-supervise  || { echo "ERROR: s6-overlay arch not installed correctly"; exit 1; } \
    && test -L /usr/bin/with-contenv  || { echo "ERROR: s6-overlay symlinks not installed correctly"; exit 1; }

COPY --from=builder /app/bin/ckpool /app/bin/ckpool
COPY --from=builder /app/bin/ckpmsg /app/bin/ckpmsg
COPY --from=builder /app/bin/notifier /app/bin/notifier

COPY root/ /
COPY config/ckpool.conf.example /defaults/ckpool.conf.example

# ── Runtime environment – override any of these with -e at docker run ─────────
# Mining mode: true = BTCSOLO (each miner paid to their own address)
#              false = Pool mode (all rewards to BTC_ADDRESS)
ENV BTCSOLO="true"
# Your Bitcoin wallet address (required when BTCSOLO=false)
ENV BTC_ADDRESS=""
# Bitcoin Core RPC connection
ENV BTC_RPC_URL="bitcoind:8332"
ENV BTC_RPC_USER="rpcuser"
ENV BTC_RPC_PASS="rpcpassword"
# Vanity string embedded in the coinbase of any block found
ENV POOL_SIG="/ckpool/"
# Stratum bind address
ENV SERVER_URL="0.0.0.0:3333"
# Difficulty settings (vardiff auto-tunes miners within these bounds)
ENV MIN_DIFF="256"
ENV START_DIFF="256"
ENV MAX_DIFF="0"
# Log directory inside the container
ENV LOG_DIR="/config/logs"
# Drop miners idle for this many seconds (0 to disable)
ENV DROP_IDLE="3600"
# Seconds between stratum work updates sent to miners
ENV UPDATE_INTERVAL="30"
# Optional extra donation % to ckpool developer (default 0)
ENV DONATION="0"

VOLUME /config

EXPOSE 3333

ENTRYPOINT ["/init"]
