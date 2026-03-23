#!/usr/bin/env bash

set -euo pipefail

APP_NAME="${APP_NAME:-rainbowsocial}"
SERVICE_NAME="${SERVICE_NAME:-rainbowsocial-api}"
GIT_REPO="${GIT_REPO:-github.com/ZhaoX19990227/rainbowsocial}"
GIT_BRANCH="${GIT_BRANCH:-main}"
GIT_WORKDIR="${GIT_WORKDIR:-rainbow-social-backend}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-Dockerfile}"
JWT_SECRET="${JWT_SECRET:?set JWT_SECRET before running}"

koyeb app init "$APP_NAME" \
  --git "$GIT_REPO" \
  --git-branch "$GIT_BRANCH" \
  --git-workdir "$GIT_WORKDIR" \
  --git-builder docker \
  --git-docker-dockerfile "$DOCKERFILE_PATH" \
  --service "$SERVICE_NAME" \
  --instance-type free \
  --ports 8088:http \
  --routes /:8088 \
  --env PORT=8088 \
  --env SERVER_PORT=8088 \
  --env APP_ENV=production \
  --env GIN_MODE=release \
  --env ALLOWED_ORIGINS=* \
  --env JWT_SECRET="$JWT_SECRET"
