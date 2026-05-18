#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

command -v yq >/dev/null || { echo "yq not found; install mikefarah/yq" >&2; exit 1; }

mkdir -p data tmp
cp -f sandbox-path-allowlist.txt data/sandbox-path-allowlist.txt

set -a; . ./.env; set +a

yq '(.. | select(tag == "!!str")) |= envsubst(nu)' microclaw.config.yaml.template > microclaw.config.yaml
chmod 640 microclaw.config.yaml

docker compose up -d --force-recreate
