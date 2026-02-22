# ckpool-docker

Docker image for [ckpool](https://github.com/jamestrichardson/ckpool) — an ultra low overhead massively scalable Bitcoin mining pool by Con Kolivas.

Built on Debian Bookworm slim with [s6-overlay](https://github.com/just-containers/s6-overlay) for process supervision.

The image is automatically built and published to the [GitHub Container Registry](https://ghcr.io) whenever code is merged to `main`.

## Usage

### Quick start

```bash
docker run -d \
  --name ckpool \
  -v /path/to/config:/config \
  -p 3333:3333 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

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

ckpool is configured entirely through a single JSON config file. Place it at `/config/ckpool.conf` on the host before starting the container.

Refer to the [ckpool README](https://github.com/jamestrichardson/ckpool/blob/master/README) and the [example config](https://github.com/jamestrichardson/ckpool/blob/master/ckpool.conf) for all available options.

### Minimum viable config

```json
{
  "btcd": [{
    "url": "127.0.0.1:8332",
    "auth": "rpcuser",
    "pass": "rpcpassword"
  }],
  "btcaddress": "your-bitcoin-address",
  "btcsig": "",
  "serverurl": ["0.0.0.0:3333"],
  "mindiff": 1,
  "startdiff": 42,
  "maxdiff": 0,
  "logdir": "/config/logs"
}
```

## Volumes

| Mount path | Description |
|---|---|
| `/config` | Required. Contains `ckpool.conf` and runtime-generated logs/state. |

### Mounting the config directory

Bind-mount a host directory so your config and logs persist across container restarts:

```bash
# Create the config directory on the host
mkdir -p /srv/ckpool/config

# Copy your config into it
cp ckpool.conf /srv/ckpool/config/ckpool.conf

# Run the container
docker run -d \
  --name ckpool \
  -v /srv/ckpool/config:/config \
  -p 3333:3333 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

### Using a named volume

If you prefer Docker-managed storage instead of a bind mount:

```bash
docker volume create ckpool-config

docker run -d \
  --name ckpool \
  -v ckpool-config:/config \
  -p 3333:3333 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

Copy your config into the named volume before starting:

```bash
docker run --rm \
  -v ckpool-config:/config \
  -v /path/to/your/ckpool.conf:/src/ckpool.conf:ro \
  debian:bookworm-slim \
  cp /src/ckpool.conf /config/ckpool.conf
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
