#!/usr/bin/env bash

set -euo pipefail

sudo apt-get update
sudo apt-get install -y ca-certificates curl git

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
fi

sudo mkdir -p /opt/rainbowsocial
sudo chown "$USER":"$USER" /opt/rainbowsocial

if [[ ! -d /opt/rainbowsocial/.git ]]; then
  git clone git@github.com:ZhaoX19990227/rainbowsocial.git /opt/rainbowsocial
else
  git -C /opt/rainbowsocial pull --ff-only
fi

cd /opt/rainbowsocial/deploy/oracle
docker compose up -d --build
docker compose ps
