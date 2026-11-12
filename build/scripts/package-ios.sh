#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-app}"
MODE_SUFFIX="${MODE_SUFFIX:-}"

: "${DIST_DIR:?}"
mkdir -p "$DIST_DIR"

if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
  echo "::error::ios Runner.app bundle not found"
  exit 1
fi

ditto -c -k --sequesterRsrc "build/ios/iphoneos/Runner.app" "$DIST_DIR/${APP_NAME}-ios-unsigned${MODE_SUFFIX}.zip"
