# ckpool-docker

Docker image for [ckpool](https://github.com/jamestrichardson/ckpool) — an ultra low overhead massively scalable Bitcoin mining pool by Con Kolivas.

Built on Debian Bookworm slim with [s6-overlay](https://github.com/just-containers/s6-overlay) for process supervision.

The image is automatically built and published to the [GitHub Container Registry](https://ghcr.io) whenever code is merged to `main`.

## Usage

### Quick start

The easiest way to get started is by using the provided `run.sh` script.

```bash
# 1. Clone the repo
git clone https://github.com/jamestrichardson/ckpool-docker.git
cd ckpool-docker

# 2. Configure environment
cp .env.example .env

# 3. Edit .env (set your BTC address and Bitcoin Core RPC details)
${EDITOR:-nano} .env

# 4. Start the container (optionally pull the latest version)
./run.sh --pull
```

> If you're on **BTCSOLO** (default), miners set their **username to their own Bitcoin address**. When a block is found their reward goes directly to their wallet — no manual splitting needed.

> If you're using **Pool mode** (`BTCSOLO=false`), all rewards go to the `BTC_ADDRESS` you set in the `.env` file. You split the rewards manually.


### Available tags

| Tag | Description |
|-----|-------------|
| `latest` | Latest build from `main` |
| `sha-<commit>` | Pinned to a specific commit SHA |
| `<major>.<minor>.<patch>` | Specific release version |

### Supported architectures

| Architecture | Docker platform |
|---|---|
| x86-64 | `linux/amd64` |
| ARM 64-bit | `linux/arm64` |

## Configuration

The container generates `/config/ckpool.conf` from environment variables on every start. Set variables with `-e` at `docker run` or via the `environment:` key in Docker Compose. Values in `/config/logs` and other runtime output persist across restarts via the mounted `/config` volume.

For advanced users who need options not exposed as env vars, the bundled [example config](config/ckpool.conf.example) can be used as a reference.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `BTCSOLO` | `true` | `true` = BTCSOLO mode: each miner's rewards go directly to their own address. `false` = Pool mode: all rewards go to `BTC_ADDRESS`. |
| `BTC_ADDRESS` | _(empty)_ | Your Bitcoin wallet address. Required when `BTCSOLO=false`. Ignored in BTCSOLO mode. |
| `BTC_RPC_URL` | `bitcoind:8332` | Host and port of your Bitcoin Core RPC endpoint. |
| `BTC_RPC_USER` | `rpcuser` | Bitcoin Core RPC username. |
| `BTC_RPC_PASS` | `rpcpassword` | Bitcoin Core RPC password. |
| `POOL_SIG` | `/ckpool/` | Vanity string embedded in the coinbase of any block found by your pool. |
| `SERVER_URL` | `0.0.0.0:3333` | Address and port miners connect to. |
| `MIN_DIFF` | `256` | Minimum difficulty vardiff will assign. Lower to `64` for weak hardware. |
| `START_DIFF` | `256` | Starting difficulty for new miners before vardiff adjusts them. |
| `MAX_DIFF` | `0` | Maximum difficulty cap. `0` means no cap. |
| `LOG_DIR` | `/config/logs` | Directory inside the container where pool logs are written. |
| `DROP_IDLE` | `3600` | Drop miners that submit no shares for this many seconds. `0` to disable. |
| `UPDATE_INTERVAL` | `30` | Seconds between new work updates sent to miners. |
| `DONATION` | `0` | Optional extra donation percentage to the ckpool developer. |

> **Note:** `127.0.0.1` in `BTC_RPC_URL` refers to the container itself, not your host.
> See [Connecting to Bitcoin Core](#connecting-to-bitcoin-core) below for how to reach bitcoind.

### Connecting to Bitcoin Core

ckpool needs to reach a Bitcoin Core node via RPC. How you reference it in `btcd.url` depends on where Bitcoin Core is running:

#### Bitcoin Core on the host machine

Use `host.docker.internal` (Docker Desktop on macOS/Windows) or the Docker bridge IP (Linux):

```bash
# Linux: find the host's docker0 bridge IP
ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'
# typically 172.17.0.1
```

```json
"btcd": [{ "url": "172.17.0.1:8332", "auth": "rpcuser", "pass": "rpcpassword" }]
```

Or use `--network host` so the container shares the host network stack, allowing `127.0.0.1`:

```bash
docker run -d \
  --name ckpool \
  --network host \
  -v /srv/ckpool/config:/config \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

> With `--network host`, `-p` flags are not used — ports are bound directly on the host.

#### Bitcoin Core in another Docker container

Put both containers on the same user-defined network and reference Bitcoin Core by its container name:

```bash
docker network create bitcoin-net

docker run -d --name bitcoind --network bitcoin-net <bitcoind-image>

docker run -d \
  --name ckpool \
  --network bitcoin-net \
  -v /srv/ckpool/config:/config \
  -p 3333:3333 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

```json
"btcd": [{ "url": "bitcoind:8332", "auth": "rpcuser", "pass": "rpcpassword" }]
```

#### Bitcoin Core via Docker Compose (recommended)

See the [Docker Compose](#docker-compose) section below for a complete example.

## Volumes

| Mount path | Description |
|---|---|
| `/config` | Required. Contains `ckpool.conf` and runtime-generated logs/state. |

### Mounting the config directory

Bind-mount a host directory so logs persist across container restarts:

```bash
mkdir -p /srv/ckpool/config

docker run -d \
  --name ckpool \
  -v /srv/ckpool/config:/config \
  -p 3333:3333 \
  -e BTC_RPC_URL=172.17.0.1:8332 \
  -e BTC_RPC_USER=rpcuser \
  -e BTC_RPC_PASS=rpcpassword \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

### Using a named volume

```bash
docker volume create ckpool-config

docker run -d \
  --name ckpool \
  -v ckpool-config:/config \
  -p 3333:3333 \
  -e BTC_RPC_URL=172.17.0.1:8332 \
  -e BTC_RPC_USER=rpcuser \
  -e BTC_RPC_PASS=rpcpassword \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `3333` | TCP | Stratum mining port (connect miners here) |

Expose additional ports if your config defines multiple `serverurl` entries:

```bash
docker run -d \
  --name ckpool \
  -v /srv/ckpool/config:/config \
  -p 3333:3333 \
  -p 3334:3334 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

## Docker Compose

### ckpool only (Bitcoin Core running elsewhere)

```yaml
services:
  ckpool:
    image: ghcr.io/jamestrichardson/ckpool-docker:latest
    container_name: ckpool
    restart: unless-stopped
    volumes:
      - /srv/ckpool/config:/config
    ports:
      - "3333:3333"
    environment:
      - BTCSOLO=true
      - BTC_RPC_URL=172.17.0.1:8332
      - BTC_RPC_USER=rpcuser
      - BTC_RPC_PASS=rpcpassword
      - POOL_SIG=/FamilyPool/
```

### ckpool + Bitcoin Core together

```yaml
services:
  bitcoind:
    image: lncm/bitcoind:v27.0
    container_name: bitcoind
    restart: unless-stopped
    volumes:
      - bitcoind-data:/data/.bitcoin
    command:
      - -rpcuser=rpcuser
      - -rpcpassword=rpcpassword
      - -rpcallowip=0.0.0.0/0
      - -rpcbind=0.0.0.0

  ckpool:
    image: ghcr.io/jamestrichardson/ckpool-docker:latest
    container_name: ckpool
    restart: unless-stopped
    depends_on:
      - bitcoind
    volumes:
      - /srv/ckpool/config:/config
    ports:
      - "3333:3333"
    environment:
      - BTCSOLO=true
      - BTC_RPC_URL=bitcoind:8332
      - BTC_RPC_USER=rpcuser
      - BTC_RPC_PASS=rpcpassword
      - POOL_SIG=/FamilyPool/

volumes:
  bitcoind-data:
```

Compose places both services on a shared network so `bitcoind` resolves as a hostname automatically.

## Logs

ckpool writes logs to `logdir` as defined in your config. If you set `"logdir": "/config/logs"`, logs will be visible on the host at your bind-mount path.

To follow live container output:

```bash
docker logs -f ckpool
```

## Development

### Conventional Commits

This project enforces [Conventional Commits](https://www.conventionalcommits.org/). Install [pre-commit](https://pre-commit.com/) and set up the hook:

```bash
pip install pre-commit
pre-commit install --hook-type commit-msg
```

All commit messages must follow the format: `type(scope): description`

Examples: `feat: add multi-arch build`, `fix: correct s6 service dependency`, `docs: update README`

### Publishing

The Docker image is built and pushed to `ghcr.io/jamestrichardson/ckpool-docker` automatically on every merge to `main`.
