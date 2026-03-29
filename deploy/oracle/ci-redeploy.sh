#!/usr/bin/env bash

set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/rainbowsocial-deploy}"
REPO_ARCHIVE="${REPO_ARCHIVE:-/tmp/rainbowsocial-src.tgz}"
WEB_ARCHIVE="${WEB_ARCHIVE:-/tmp/rainbowsocial-web.tgz}"
WORK_DIR="$(mktemp -d /tmp/rainbowsocial-deploy.XXXXXX)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "==> deploy root: $DEPLOY_ROOT"
echo "==> extracting source archive"
mkdir -p "$WORK_DIR/src"
tar -xzf "$REPO_ARCHIVE" -C "$WORK_DIR/src"

mkdir -p "$DEPLOY_ROOT"

for path in rainbow-social-backend rainbow-social-frontend rainbow-share-static deploy; do
  if [ -e "$WORK_DIR/src/$path" ]; then
    echo "==> syncing $path"
    rm -rf "$DEPLOY_ROOT/$path"
    cp -R "$WORK_DIR/src/$path" "$DEPLOY_ROOT/$path"
  fi
done

if [ -f "$WEB_ARCHIVE" ] && [ -d "$DEPLOY_ROOT/site" ]; then
  echo "==> updating web site bundle"
  rm -rf "$DEPLOY_ROOT/site"/*
  tar -xzf "$WEB_ARCHIVE" -C "$DEPLOY_ROOT/site"
fi

COMPOSE_FILE=""
if [ -f "$DEPLOY_ROOT/docker-compose.yml" ]; then
  COMPOSE_FILE="$DEPLOY_ROOT/docker-compose.yml"
elif [ -f "$DEPLOY_ROOT/deploy/oracle/docker-compose.yml" ]; then
  COMPOSE_FILE="$DEPLOY_ROOT/deploy/oracle/docker-compose.yml"
fi

if [ -z "$COMPOSE_FILE" ]; then
  echo "docker compose file not found under $DEPLOY_ROOT" >&2
  exit 1
fi

echo "==> using compose file: $COMPOSE_FILE"
cd "$(dirname "$COMPOSE_FILE")"

services="$(docker compose -f "$COMPOSE_FILE" config --services)"
echo "==> compose services:"
echo "$services"

if echo "$services" | grep -qx 'api'; then
  echo "==> rebuilding api"
  docker compose -f "$COMPOSE_FILE" up -d --build api
fi

if echo "$services" | grep -qx 'web'; then
  echo "==> restarting web"
  docker compose -f "$COMPOSE_FILE" up -d --build web
fi

echo "==> container status"
docker compose -f "$COMPOSE_FILE" ps

if command -v curl >/dev/null 2>&1; then
  echo "==> health check"
  curl -fsS http://127.0.0.1:8088/health
  echo
fi

echo "==> deploy completed"
