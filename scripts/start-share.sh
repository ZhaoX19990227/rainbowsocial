#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="/Users/zhaoxiang/GolandProjects/rainbow"
BACKEND_DIR="$ROOT_DIR/rainbow-social-backend"
LOG_DIR="$ROOT_DIR/.run"
BACKEND_LOG="$LOG_DIR/backend.log"
NGROK_LOG="$LOG_DIR/ngrok.log"
BACKEND_PID_FILE="$LOG_DIR/backend.pid"
NGROK_PID_FILE="$LOG_DIR/ngrok.pid"

mkdir -p "$LOG_DIR"

kill_if_running() {
  local pid_file="$1"
  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 1
    fi
    rm -f "$pid_file"
  fi
}

pkill -f 'go run main.go' 2>/dev/null || true
pkill -f '/var/folders/.*/exe/main' 2>/dev/null || true
pkill -f 'ngrok http 8088 --log=stdout' 2>/dev/null || true

kill_if_running "$BACKEND_PID_FILE"
kill_if_running "$NGROK_PID_FILE"

cd "$BACKEND_DIR"
nohup go run main.go >"$BACKEND_LOG" 2>&1 < /dev/null &
echo $! >"$BACKEND_PID_FILE"
disown "$(cat "$BACKEND_PID_FILE")" 2>/dev/null || true

for _ in {1..20}; do
  if curl -fsS "http://127.0.0.1:8088/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

nohup ngrok http 8088 --log=stdout >"$NGROK_LOG" 2>&1 < /dev/null &
echo $! >"$NGROK_PID_FILE"
disown "$(cat "$NGROK_PID_FILE")" 2>/dev/null || true

PUBLIC_URL=""
for _ in {1..20}; do
  PUBLIC_URL="$(
    {
      curl -fsS "http://127.0.0.1:4040/api/tunnels" 2>/dev/null || true
    } | sed -n 's/.*"public_url":"\([^"]*\)".*/\1/p' | head -n 1
  )"
  if [[ -n "$PUBLIC_URL" ]]; then
    break
  fi
  sleep 1
done

echo "backend pid: $(cat "$BACKEND_PID_FILE")"
echo "ngrok pid:   $(cat "$NGROK_PID_FILE")"
echo "backend log: $BACKEND_LOG"
echo "ngrok log:   $NGROK_LOG"

if [[ -n "$PUBLIC_URL" ]]; then
  echo "share page:  $PUBLIC_URL/share"
  echo "download:    $PUBLIC_URL/downloads/rainbow-social.apk"
else
  echo "ngrok tunnel not ready yet. Check: $NGROK_LOG"
fi
