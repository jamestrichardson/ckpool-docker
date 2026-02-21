# ckpool-docker

Docker image for [ckpool](https://github.com/jamestrichardson/ckpool) — an ultra low overhead massively scalable Bitcoin mining pool by Con Kolivas.

Built with [Alpine Linux](https://alpinelinux.org/) and [s6-overlay](https://github.com/just-containers/s6-overlay), following the [linuxserver.io](https://www.linuxserver.io/) image style.

The image is automatically built and published to the [GitHub Container Registry](https://ghcr.io) whenever code is merged to `main`.

## Usage

```bash
docker run -d \
  --name ckpool \
  -v /path/to/config:/config \
  -p 3333:3333 \
  ghcr.io/jamestrichardson/ckpool-docker:latest
```

### Configuration

Place your `ckpool.conf` in the mounted `/config` directory before starting the container. Refer to the [ckpool README](https://github.com/jamestrichardson/ckpool/blob/master/README) and the [example config](https://github.com/jamestrichardson/ckpool/blob/master/ckpool.conf) for configuration options.

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
