#!/usr/bin/env bash
# rollback.sh — retag app to a previous image tag and restart that service.
# Usage: ./scripts/rollback.sh [TAG]   (default TAG=previous)
set -euo pipefail
cd "$(dirname "$0")/.."
TAG="${1:-previous}"
echo ">> rolling app back to tag: $TAG"
docker tag "demo-app:latest" "demo-app:failed-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
docker tag "demo-app:${TAG}" "demo-app:latest" || {
  echo "error: tag demo-app:${TAG} not found. List tags: docker images demo-app" >&2; exit 1; }
docker compose up -d app
echo "rolled back. verify: curl -s http://127.0.0.1:${HTTP_PORT:-80}/healthz"
