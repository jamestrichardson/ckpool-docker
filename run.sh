#!/usr/bin/env bash

# ckpool-docker-compose management script
# Helps you launch the Bitcoin node and mining pool together.

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

# 1. Check for .env file
if [[ ! -f "${ENV_FILE}" ]]; then
    echo "==> Error: .env file not found."
    echo "    Please copy .env.example to .env and edit it first."
    exit 1
fi

# 2. Parse command line arguments
COMMAND="up -d"
PULL_IMAGE=false

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --pull) PULL_IMAGE=true; shift ;;
        --stop) COMMAND="down"; shift ;;
        --logs) COMMAND="logs -f"; shift ;;
        -h|--help)
            echo "Usage: ./run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --pull    Pull latest images before starting"
            echo "  --stop    Stop and remove containers (docker compose down)"
            echo "  --logs    Follow container logs"
            echo "  -h, --help  Display this help message"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# 3. Handle pulling if requested
if [[ "${PULL_IMAGE}" = true ]]; then
    echo "==> Pulling latest images from registry..."
    docker compose pull
fi

# 4. Final execution
echo "==> Running: docker compose ${COMMAND}"

# Ensure paths exist for volumes before starting
# (This avoids docker creating them as root directories)
set -a
source "${ENV_FILE}"
set +a

mkdir -p "${BITCOIND_DATA_PATH:-/srv/bitcoin}"
mkdir -p "${CONFIG_PATH:-/srv/ckpool/config}"

docker compose ${COMMAND}

if [[ "${COMMAND}" == "up -d" ]]; then
  echo "==> Services started successfully!"
  echo "    Track logs with: ./run.sh --logs"
fi
