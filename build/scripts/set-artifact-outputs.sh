#!/usr/bin/env bash
set -euo pipefail

: "${DIST_DIR:?}"
if [ ! -d "$DIST_DIR" ] || [ -z "$(ls -A "$DIST_DIR" 2>/dev/null)" ]; then
  echo "::error::Packaging produced no artifacts in $DIST_DIR"
  exit 1
fi
echo "artifact-name=${APP_NAME}-${TARGET}${MODE_SUFFIX}" >> "$GITHUB_OUTPUT"
echo "artifact-path=${DIST_DIR}/*" >> "$GITHUB_OUTPUT"
