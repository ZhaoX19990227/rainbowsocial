#!/usr/bin/env bash

set -Eeuo pipefail

DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/rainbowsocial-deploy}"
REPO_ARCHIVE="${REPO_ARCHIVE:-/tmp/rainbowsocial-src.tgz}"
WEB_ARCHIVE="${WEB_ARCHIVE:-/tmp/rainbowsocial-web.tgz}"
WORK_DIR="$(mktemp -d /tmp/rainbowsocial-deploy.XXXXXX)"
BACKUP_DIR=""
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://127.0.0.1:8088/health}"
ROLLBACK_NEEDED=0
DEPLOY_TARGETS=(
  "rainbow-social-backend"
  "rainbow-social-frontend"
  "rainbow-share-static"
  "deploy"
)

restore_path() {
  local path="$1"

  rm -rf "$DEPLOY_ROOT/$path"
  if [ -e "$BACKUP_DIR/$path" ]; then
    cp -R "$BACKUP_DIR/$path" "$DEPLOY_ROOT/$path"
  fi
}

run_healthcheck() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "==> curl not found, skip health check"
    return 0
  fi

  echo "==> health check: $HEALTHCHECK_URL"
  curl -fsS "$HEALTHCHECK_URL"
  echo
}

rollback() {
  local path

  if [ "$ROLLBACK_NEEDED" -ne 1 ]; then
    return
  fi

  if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    echo "==> rollback skipped: backup not found" >&2
    return
  fi

  echo "==> deploy failed, rolling back"

  for path in "${DEPLOY_TARGETS[@]}"; do
    restore_path "$path"
  done

  if [ -d "$BACKUP_DIR/site" ]; then
    rm -rf "$DEPLOY_ROOT/site"
    cp -R "$BACKUP_DIR/site" "$DEPLOY_ROOT/site"
  fi

  if [ -n "${COMPOSE_FILE:-}" ] && [ -f "$COMPOSE_FILE" ]; then
    echo "==> restarting previous containers"
    docker compose -f "$COMPOSE_FILE" up -d --build
    docker compose -f "$COMPOSE_FILE" ps
  fi

  run_healthcheck
  echo "==> rollback completed"
}

cleanup() {
  rollback
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "==> deploy root: $DEPLOY_ROOT"
echo "==> extracting source archive"
mkdir -p "$WORK_DIR/src"
tar -xzf "$REPO_ARCHIVE" -C "$WORK_DIR/src"

mkdir -p "$DEPLOY_ROOT"
BACKUP_DIR="$WORK_DIR/backup"
mkdir -p "$BACKUP_DIR"

for path in "${DEPLOY_TARGETS[@]}"; do
  if [ -e "$DEPLOY_ROOT/$path" ]; then
    cp -R "$DEPLOY_ROOT/$path" "$BACKUP_DIR/$path"
  fi
done

if [ -d "$DEPLOY_ROOT/site" ]; then
  cp -R "$DEPLOY_ROOT/site" "$BACKUP_DIR/site"
fi

ROLLBACK_NEEDED=1

for path in "${DEPLOY_TARGETS[@]}"; do
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

run_healthcheck

ROLLBACK_NEEDED=0

echo "==> deploy completed"
