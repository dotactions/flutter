#!/usr/bin/env bash
# shellcheck source=.tooling/tests/lib.sh
source "$(dirname "$0")/../.tooling/tests/lib.sh"
only_on linux macos windows

SCRIPT="$REPO_ROOT/build/scripts/resolve-metadata.sh"
ACTION_PATH="GITHUB_ACTION_PATH=$REPO_ROOT/build"

# resolve <pubspec content, empty for none> [VAR=val ...]
resolve() {
  new_case
  if [ -n "$1" ]; then printf '%b' "$1" > "$WORK/pubspec.yaml"; fi
  shift
  run "$SCRIPT" "$ACTION_PATH" RUNNER_TEMP="$CASE_DIR/tmp" "$@"
}

PUBSPEC='name: my_app\nversion: 1.0.0\n'

for target in $(jq -r 'keys_unsorted[]' "$REPO_ROOT/build/targets.json" | tr -d '\r'); do
  resolve "$PUBSPEC" TARGET="$target" BUILD_MODE=release
  expect_ok "accepts target $target"
done

resolve "$PUBSPEC" TARGET=web BUILD_MODE=release
expect_fail "rejects unknown target" "Unsupported build target: web"
expect_fail "unknown target error lists allowed targets" '"android-apk"'

resolve "$PUBSPEC" TARGET=linux BUILD_MODE=fast
expect_fail "rejects unknown build mode" "Unsupported build mode: fast"

resolve "$PUBSPEC" TARGET=linux BUILD_MODE=release
expect "release has no suffix" "" "$(output mode-suffix)"
expect "app-name output" "my_app" "$(output app-name)"
expect "dist-dir is per target under RUNNER_TEMP" "$CASE_DIR/tmp/flutter-dist/linux" "$(output dist-dir)"
expect "dist-dir is created" "yes" "$(test -d "$CASE_DIR/tmp/flutter-dist/linux" && echo yes)"
expect "nothing is exported to GITHUB_ENV" "" "$(cat "$CASE_DIR/env")"

for mode in debug profile; do
  resolve "$PUBSPEC" TARGET=linux BUILD_MODE="$mode"
  expect "$mode suffix" "-$mode" "$(output mode-suffix)"
done

resolve 'name: "quoted_app"\n' TARGET=linux BUILD_MODE=release
expect "double-quoted name" "quoted_app" "$(output app-name)"

resolve "name: 'single_app'\n" TARGET=linux BUILD_MODE=release
expect "single-quoted name" "single_app" "$(output app-name)"

resolve 'name: crlf_app\r\nversion: 1.0.0\r\n' TARGET=linux BUILD_MODE=release
expect "crlf name" "crlf_app" "$(output app-name)"

resolve 'description: x\nflutter:\n  name: nested\nname: top_app\n' TARGET=linux BUILD_MODE=release
expect "only top-level name counts" "top_app" "$(output app-name)"

resolve 'name: commented_app # the app\n' TARGET=linux BUILD_MODE=release
expect "trailing comment is stripped" "commented_app" "$(output app-name)"

resolve 'name: "../evil"\n' TARGET=linux BUILD_MODE=release
expect_fail "rejects a name Dart would reject" "Invalid pubspec.yaml name '../evil'"

resolve 'name: My-App\n' TARGET=linux BUILD_MODE=release
expect_fail "rejects uppercase and dashes" "Invalid pubspec.yaml name"

new_case
printf 'name: my_app\n' > "$WORK/pubspec.yaml"
mkdir -p "$CASE_DIR/tmp/flutter-dist/linux"
touch "$CASE_DIR/tmp/flutter-dist/linux/stale.tar.gz"
run "$SCRIPT" "$ACTION_PATH" RUNNER_TEMP="$CASE_DIR/tmp" TARGET=linux BUILD_MODE=release
expect "stale artifacts from an earlier build are removed" "" "$(ls "$CASE_DIR/tmp/flutter-dist/linux")"

resolve 'version: 1.0.0\n' TARGET=linux BUILD_MODE=release
expect "missing name falls back to app" "app" "$(output app-name)"

resolve "" TARGET=linux BUILD_MODE=release
expect_fail "missing pubspec" "pubspec.yaml not found"

finish
