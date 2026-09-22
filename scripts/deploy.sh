#!/usr/bin/env bash
# deploy.sh — pull, build, start, health-gate. Refuses without .env.
# Usage: ./scripts/deploy.sh [--no-build]
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo "error: .env missing — cp .env.example .env first" >&2; exit 1; }
set -a; source .env; set +a

BUILD="--build"
[[ "${1:-}" == "--no-build" ]] && BUILD=""

echo ">> validating compose file"
docker compose config >/dev/null

echo ">> pulling base images"
docker compose pull --ignore-pull-failures || true

# shellcheck disable=SC2086
echo ">> building + starting"
docker compose up -d $BUILD

echo ">> health gate (30s)"
for i in $(seq 1 15); do
  if curl -sf "http://127.0.0.1:${HTTP_PORT:-80}/healthz" >/dev/null 2>&1; then
    echo "healthy after ${i}x2s"
    docker compose ps
    exit 0
  fi
  sleep 2
done
echo "error: app never became healthy — see: docker compose logs --tail 100" >&2
exit 1
