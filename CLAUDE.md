# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A deployment-only directory for running the upstream `ghcr.io/microclaw/microclaw:latest` container. There is no application source here — only the compose file, the runtime config, and the bind-mounted state directories. Treat this as ops/config, not a codebase.

## Commands

- Bring up the stack: `./up.sh` (preferred). Renders `microclaw.config.yaml.template` → `microclaw.config.yaml` with env-var substitution via `yq … envsubst(nu)`, chmods the output to `640`, then `docker compose up -d --force-recreate`. Requires `yq` (mikefarah Go binary, not the Python `yq` of the same name) on `PATH`.
- Stop: `docker compose down`
- Logs: `docker compose logs -f`
- Pull a newer image: `docker compose pull && ./up.sh`

`.env` (gitignored) holds every `${VAR}` referenced in the template (at minimum `ANTHROPIC_API_TOKEN`, `DISCORD_BOT_TOKEN`) plus optionally `DOCKER_GID`. It is consumed by `up.sh` for template substitution — *not* by compose for env passthrough. The `(nu)` mode of `envsubst` makes the render fail loudly if any referenced var is unset.

## Architecture notes that aren't obvious from a single file

- **Container runs as non-root** (`uid=10001 microclaw`). Bind-mounted files must be readable by that uid. `microclaw.config.yaml` should be `chown jess:10001 && chmod 640` so it's owner-rw + group-r (and only the container's gid matches that group on this host). `data/` and `tmp/` are `0777` because the container writes into them as uid 10001.
- **Docker-in-Docker via host socket.** `/var/run/docker.sock` is bind-mounted so microclaw's sandbox backend can spawn sibling containers on the host. Because the container is non-root, `group_add` injects the host's `docker` group GID (defaults to `973`, the value on this host — override via `DOCKER_GID` in `.env` on other hosts) so the non-root user can open the socket. This is "Docker outside of Docker"; sandbox containers are siblings, not children. The sandbox is configured in `microclaw.config.yaml` under `sandbox:` (`backend: auto`, `image: ubuntu:26.04`, `security_profile: hardened`).
- **`microclaw.config.yaml` does NOT support `${VAR}` interpolation at runtime** — microclaw passes the string `${DISCORD_BOT_TOKEN}` verbatim to Discord (causes gateway 4004 "Authentication failed"). We work around this by treating `microclaw.config.yaml.template` as the source of truth (committed, contains `${VAR}` placeholders) and generating `microclaw.config.yaml` (gitignored, contains literal secrets) via `up.sh` at deploy time. Never edit `microclaw.config.yaml` directly — your changes will be clobbered on next `./up.sh`. Anthropic's SDK may pick up `ANTHROPIC_API_KEY` from the env independently, which can make a stale or unsubstituted `api_key` *appear* to work — don't be misled.
- **Tool-access allowlist for the agent**: `sandbox-path-allowlist.txt` at the repo root is the version-controlled source. `up.sh` copies it into `data/sandbox-path-allowlist.txt` on each deploy (because `data/` is gitignored, the root copy is what's tracked), and the file ends up inside the container at `/home/microclaw/.microclaw/sandbox-path-allowlist.txt` — microclaw's default location — via the `./data:/home/microclaw/.microclaw` mount. It lists the absolute paths the agent's file tools are allowed to touch (currently `working_dir` only, so the agent cannot read `/app/microclaw.config.yaml` or other host-mounted files). Relative paths in agent file tools always resolve from `working_dir` regardless.
- **State layout under `data/`**: `runtime/` (microclaw's persistent state), `skills/` (loaded skills), `working_dir/` (agent scratch). This is what gets mounted to `/home/microclaw/.microclaw` inside the container; the path is also referenced as `data_dir` in `microclaw.config.yaml`. `tmp/` mounts to `/app/tmp`.
- **Port 10961** is bound to `127.0.0.1` only — the web channel is not exposed externally by design.

## Gotchas

- The image has an ENTRYPOINT set to the microclaw binary, so `docker run … <cmd>` passes `<cmd>` as a microclaw subcommand. To run arbitrary commands (e.g. `id`, `sh`) use `--entrypoint`.
- `souls_dir` in the config points to a host path (`/home/jess/.microclaw/souls`) that is NOT mounted into the container — the container will see that path as missing unless a mount is added.
- `docker compose` itself only sees `DOCKER_GID` from `.env` (via interpolation in `docker-compose.yaml`). It does NOT inject `ANTHROPIC_API_TOKEN` / `DISCORD_BOT_TOKEN` into the container — those land in `microclaw.config.yaml` via `up.sh`'s `yq … envsubst` step. Adding `environment:` passthroughs in `docker-compose.yaml` would be redundant.
- The mikefarah `yq` (Go) and the kislyuk `yq` (Python) are unrelated tools with the same name; only mikefarah's has the `envsubst` operator. On Debian/Ubuntu `apt install yq` may install whichever; check with `yq --version` (mikefarah reports `yq (https://github.com/mikefarah/yq/) version v...`).
