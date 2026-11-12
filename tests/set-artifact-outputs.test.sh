#!/usr/bin/env bash
# shellcheck source=.tooling/tests/lib.sh
source "$(dirname "$0")/../.tooling/tests/lib.sh"
only_on linux macos windows

SCRIPT="$REPO_ROOT/build/scripts/set-artifact-outputs.sh"
VARS=(APP_NAME=my_app TARGET=android-apk MODE_SUFFIX=-debug DIST_DIR=out)

new_case
mkdir -p "$WORK/out"
touch "$WORK/out/my_app-android-debug.apk"
run "$SCRIPT" "${VARS[@]}"
expect "artifact-name" "my_app-android-apk-debug" "$(output artifact-name)"
expect "artifact-path is the dist dir glob" "out/*" "$(output artifact-path)"

new_case
mkdir -p "$WORK/out"
touch "$WORK/out/my_app-linux.tar.gz"
run "$SCRIPT" APP_NAME=my_app TARGET=linux MODE_SUFFIX= DIST_DIR=out
expect "release artifact-name has no suffix" "my_app-linux" "$(output artifact-name)"

new_case
mkdir -p "$WORK/out"
run "$SCRIPT" "${VARS[@]}"
expect_fail "empty dist" "Packaging produced no artifacts"
expect "no outputs on failure" "" "$(output artifact-name)"

new_case
run "$SCRIPT" "${VARS[@]}"
expect_fail "missing dist" "Packaging produced no artifacts"

new_case
run "$SCRIPT" APP_NAME=my_app TARGET=linux MODE_SUFFIX=
expect_fail "DIST_DIR is required"

finish
