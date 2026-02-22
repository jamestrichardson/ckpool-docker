# ckpool-docker

Docker image for [ckpool](https://github.com/jamestrichardson/ckpool) — an ultra low overhead massively scalable Bitcoin mining pool by Con Kolivas.

Built on Debian Bookworm slim with [s6-overlay](https://github.com/just-containers/s6-overlay) for process supervision.

The image is automatically built and published to the [GitHub Container Registry](https://ghcr.io) whenever code is merged to `main`.

## Usage

### Quick start

The easiest way to get started is by using the provided `docker-compose.yml` and `run.sh` script.

```bash
# 1. Clone the repo
git clone https://github.com/jamestrichardson/ckpool-docker.git
cd ckpool-docker

# 2. Configure environment
cp .env.example .env

# 3. Edit .env (set your BTC address and Bitcoin Core RPC details)
${EDITOR:-nano} .env

# 4. Start both bitcoind and ckpool
./run.sh --pull
```

> **Note:** The `run.sh` script is just a wrapper around `docker compose up -d`. You can use standard `docker compose` commands if you prefer.

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

### Docker Compose (Recommended)

The included `docker-compose.yml` launches both `bitcoind` (using [kylemanna/bitcoind](https://hub.docker.com/r/kylemanna/bitcoind/)) and `ckpool`. This is the easiest way to ensure they can talk to each other.

```bash
# Manage both together
./run.sh --pull    # start
./run.sh --logs    # view logs
./run.sh --stop    # shut down
```

## Volumes

| Mount path | Description |
|---|---|
| `/config` | Required. Contains `ckpool.conf` and runtime-generated logs/state. |

### Configuring persistence

The `docker-compose.yml` uses the `BITCOIND_DATA_PATH` and `CONFIG_PATH` variables from your `.env` file to mount host directories:

```dotenv
# .env examples
BITCOIND_DATA_PATH=/mnt/storage/bitcoin
CONFIG_PATH=/srv/ckpool/config
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
