#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="/Users/zhaoxiang/GolandProjects/rainbow"
LOG_DIR="$ROOT_DIR/.run"
BACKEND_PID_FILE="$LOG_DIR/backend.pid"
NGROK_PID_FILE="$LOG_DIR/ngrok.pid"

kill_from_pid_file() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  fi
}

kill_from_pid_file "$BACKEND_PID_FILE"
kill_from_pid_file "$NGROK_PID_FILE"

pkill -f 'go run main.go' 2>/dev/null || true
pkill -f '/var/folders/.*/exe/main' 2>/dev/null || true
pkill -f 'ngrok http 8088 --log=stdout' 2>/dev/null || true

echo "stopped backend and ngrok"
