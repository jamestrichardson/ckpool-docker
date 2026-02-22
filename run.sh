#!/usr/bin/env bash

# ckpool-docker run script
# Helps you launch the Bitcoin mining pool with the correct environment variables.

set -e

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"
IMAGE_NAME="ghcr.io/jamestrichardson/ckpool-docker:latest"

# 1. Check for .env file and load it
if [[ -f "${ENV_FILE}" ]]; then
    echo "==> Loading configuration from .env"
    # shellcheck disable=SC2046
    export $(grep -v '^#' "${ENV_FILE}" | xargs)
else
    echo "==> Warning: .env not found. Using script defaults."
    echo "    To customize, copy .env.example to .env and edit."
fi

# 2. Set defaults for any missing variables
BTCSOLO="${BTCSOLO:-true}"
BTC_ADDRESS="${BTC_ADDRESS:-}"
BTC_RPC_URL="${BTC_RPC_URL:-bitcoind:8332}"
BTC_RPC_USER="${BTC_RPC_USER:-rpcuser}"
BTC_RPC_PASS="${BTC_RPC_PASS:-rpcpassword}"
POOL_SIG="${POOL_SIG:-/FamilyPool/}"
SERVER_URL="${SERVER_URL:-0.0.0.0:3333}"
MIN_DIFF="${MIN_DIFF:-256}"
START_DIFF="${START_DIFF:-256}"
MAX_DIFF="${MAX_DIFF:-0}"
LOG_DIR="${LOG_DIR:-/config/logs}"
DROP_IDLE="${DROP_IDLE:-3600}"
UPDATE_INTERVAL="${UPDATE_INTERVAL:-30}"
DONATION="${DONATION:-0}"
CONFIG_PATH="${CONFIG_PATH:-/srv/ckpool/config}"

# 3. Handle command line arguments
PULL_IMAGE=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --pull) PULL_IMAGE=true; shift ;;
        -h|--help)
            echo "Usage: ./run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --pull    Pull latest image from registry before starting"
            echo "  -h, --help  Display this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# 4. Pull image if requested
if [[ "${PULL_IMAGE}" = true ]]; then
    echo "==> Pulling latest image: ${IMAGE_NAME}"
    docker pull "${IMAGE_NAME}"
fi

# 5. Stop and remove existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^ckpool$"; then
    echo "==> Stopping and removing existing 'ckpool' container"
    docker stop ckpool >/dev/null
    docker rm ckpool >/dev/null
fi

# 6. Ensure host config path exists
echo "==> Ensuring config directory exists: ${CONFIG_PATH}"
mkdir -p "${CONFIG_PATH}"

# 7. Start the container
echo "==> Starting 'ckpool' container in $([[ "${BTCSOLO}" = "true" ]] && echo "BTCSOLO" || echo "POOL") mode"

docker run -d \
  --name ckpool \
  --restart unless-stopped \
  -v "${CONFIG_PATH}:/config" \
  -p 3333:3333 \
  -e BTCSOLO="${BTCSOLO}" \
  -e BTC_ADDRESS="${BTC_ADDRESS}" \
  -e BTC_RPC_URL="${BTC_RPC_URL}" \
  -e BTC_RPC_USER="${BTC_RPC_USER}" \
  -e BTC_RPC_PASS="${BTC_RPC_PASS}" \
  -e POOL_SIG="${POOL_SIG}" \
  -e SERVER_URL="${SERVER_URL}" \
  -e MIN_DIFF="${MIN_DIFF}" \
  -e START_DIFF="${START_DIFF}" \
  -e MAX_DIFF="${MAX_DIFF}" \
  -e LOG_DIR="${LOG_DIR}" \
  -e DROP_IDLE="${DROP_IDLE}" \
  -e UPDATE_INTERVAL="${UPDATE_INTERVAL}" \
  -e DONATION="${DONATION}" \
  "${IMAGE_NAME}"

echo "==> Done! Follow logs with: docker logs -f ckpool"
