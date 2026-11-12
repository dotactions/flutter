#!/usr/bin/env bash
set -euo pipefail

TARGETS_FILE="${TARGETS_FILE:-${GITHUB_ACTION_PATH}/targets.json}"
if ! jq -e --arg t "$TARGET" 'has($t)' "$TARGETS_FILE" > /dev/null; then
  echo "::error::Unsupported build target: $TARGET. Allowed targets: $(jq -c 'keys_unsorted' "$TARGETS_FILE")"
  exit 1
fi

case "$BUILD_MODE" in
  debug|profile|release) ;;
  *)
    echo "::error::Unsupported build mode: $BUILD_MODE"
    exit 1
    ;;
esac

if [ "$BUILD_MODE" = "release" ]; then
  MODE_SUFFIX=""
else
  MODE_SUFFIX="-${BUILD_MODE}"
fi

if [ ! -f pubspec.yaml ]; then
  echo "::error::pubspec.yaml not found in $PWD"
  exit 1
fi

NAME=$(sed -n "s/^name:[[:space:]]*//p" pubspec.yaml | head -n 1 | tr -d '\r' | sed 's/[[:space:]]*#.*$//' | tr -d '"'\'' ')
NAME="${NAME:-app}"
# The name ends up in file and artifact names; Dart's own rule keeps it path-safe.
if [[ ! "$NAME" =~ ^[a-z_][a-z0-9_]*$ ]]; then
  echo "::error::Invalid pubspec.yaml name '$NAME': must match ^[a-z_][a-z0-9_]*\$"
  exit 1
fi

# The action owns this directory, so a consumer's own dist/ is never packaged and repeated builds in one job don't mix.
DIST_DIR="${RUNNER_TEMP:?}/flutter-dist/${TARGET}"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

{
  echo "app-name=$NAME"
  echo "mode-suffix=$MODE_SUFFIX"
  echo "dist-dir=$DIST_DIR"
} >> "$GITHUB_OUTPUT"
