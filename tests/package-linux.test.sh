#!/usr/bin/env bash
# shellcheck source=.tooling/tests/lib.sh
source "$(dirname "$0")/../.tooling/tests/lib.sh"
only_on linux macos

SCRIPT="$REPO_ROOT/build/scripts/package-linux.sh"

for mode in release debug profile; do
  new_case
  mkdir -p "$WORK/build/linux/x64/$mode/bundle/lib"
  echo "$mode" > "$WORK/build/linux/x64/$mode/bundle/my_app"
  touch "$WORK/build/linux/x64/$mode/bundle/lib/libapp.so"
  suffix="-$mode"
  if [ "$mode" = release ]; then suffix=""; fi
  run "$SCRIPT" DIST_DIR=dist BUILD_MODE="$mode" APP_NAME=my_app MODE_SUFFIX="$suffix"
  expect_file "$mode archive name" "dist/my_app-linux$suffix.tar.gz"
  expect "$mode archive has bundle contents at its root" "./lib/libapp.so ./my_app" \
    "$(tar -tzf "$WORK/dist/my_app-linux$suffix.tar.gz" | grep -v '/$' | sort | tr '\n' ' ' | sed 's/ $//')"
done

new_case
mkdir -p "$WORK/build/linux/x64/release/bundle"
run "$SCRIPT" DIST_DIR=dist BUILD_MODE=debug APP_NAME=my_app MODE_SUFFIX=-debug
expect_fail "missing bundle for build mode fails"

finish
