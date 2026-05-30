#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

command -v yq >/dev/null || { echo "yq not found; install mikefarah/yq" >&2; exit 1; }

mkdir -p data tmp data/mcp.d
cp -f sandbox-path-allowlist.txt data/sandbox-path-allowlist.txt

set -a; . ./.env; set +a

cp -f mcp-config/git.json data/mcp.d/git.json
yq '(.. | select(tag == "!!str")) |= envsubst(nu)' microclaw.config.template.yaml > microclaw.config.yaml
chmod 640 microclaw.config.yaml
yq '(.. | select(tag == "!!str")) |= envsubst(nu)' microclaw-thinker.config.yaml.template > microclaw-thinker.config.yaml
chmod 640 microclaw-thinker.config.yaml
if [ "$(stat -c '%g' microclaw-thinker.config.yaml)" != "10001" ]; then
    sudo chgrp 10001 microclaw-thinker.config.yaml
fi
# Container's microclaw user is uid/gid 10001; the host file's group must match
# so the bind-mount is readable inside the container. `>` preserves ownership on
# existing files, so after the first run this stays a no-op.
if [ "$(stat -c '%g' microclaw.config.yaml)" != "10001" ]; then
    sudo chgrp 10001 microclaw.config.yaml
fi

docker compose up -d --build --force-recreate
