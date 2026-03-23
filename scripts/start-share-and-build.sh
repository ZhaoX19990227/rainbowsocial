#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="/Users/zhaoxiang/GolandProjects/rainbow"
FRONTEND_DIR="$ROOT_DIR/rainbow-social-frontend"
BACKEND_DIR="$ROOT_DIR/rainbow-social-backend"
LOG_DIR="$ROOT_DIR/.run"
BUILD_LOG="$LOG_DIR/build-apk.log"
APK_SOURCE="$FRONTEND_DIR/build/app/outputs/flutter-apk/app-release.apk"
APK_TARGET="$BACKEND_DIR/downloads/rainbow-social.apk"
START_SCRIPT="$ROOT_DIR/scripts/start-share.sh"

mkdir -p "$LOG_DIR"

bash "$START_SCRIPT"

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

if [[ -z "$PUBLIC_URL" ]]; then
  echo "failed to get ngrok public url"
  exit 1
fi

cd "$FRONTEND_DIR"

export JAVA_HOME
JAVA_HOME="$(
  /usr/libexec/java_home -v 17
)"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:/Users/zhaoxiang/tools/flutter-sdk/flutter/bin:$ANDROID_HOME/platform-tools"

echo "building apk with:"
echo "  API_BASE_URL=$PUBLIC_URL"
echo "  WS_BASE_URL=${PUBLIC_URL/https:/wss:}/ws"

flutter build apk --release \
  --dart-define="API_BASE_URL=$PUBLIC_URL" \
  --dart-define="WS_BASE_URL=${PUBLIC_URL/https:/wss:}/ws" \
  2>&1 | tee "$BUILD_LOG"

cp "$APK_SOURCE" "$APK_TARGET"

echo "build log:   $BUILD_LOG"
echo "apk source:  $APK_SOURCE"
echo "apk target:  $APK_TARGET"
echo "share page:  $PUBLIC_URL/share"
echo "download:    $PUBLIC_URL/downloads/rainbow-social.apk"
