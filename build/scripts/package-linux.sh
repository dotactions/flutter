#!/usr/bin/env bash
set -euo pipefail

BUILD_MODE="${BUILD_MODE:-release}"
APP_NAME="${APP_NAME:-app}"
MODE_SUFFIX="${MODE_SUFFIX:-}"

: "${DIST_DIR:?}"
mkdir -p "$DIST_DIR"
# ponytail: x64 only; arm64 runners need build/linux/arm64 once targets.json offers them.
tar -czf "$DIST_DIR/${APP_NAME}-linux${MODE_SUFFIX}.tar.gz" -C "build/linux/x64/${BUILD_MODE}/bundle" .
