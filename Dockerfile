# Thin wrapper around the upstream microclaw image that adds the docker CLI.
# Microclaw's sandbox backend shells out to `docker` (or `podman`) as a
# subprocess to spawn sibling containers via the host's docker socket; the
# upstream image ships the daemon-side wiring (group_add etc. handled by
# compose) but not the CLI binary itself.
FROM ghcr.io/microclaw/microclaw:latest

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io \
 && rm -rf /var/lib/apt/lists/*
USER microclaw
