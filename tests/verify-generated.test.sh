#!/usr/bin/env bash
# shellcheck source=.tooling/tests/lib.sh
source "$(dirname "$0")/../.tooling/tests/lib.sh"
only_on linux macos windows

SCRIPT="$REPO_ROOT/verify-generated/scripts/verify-generated.sh"

# verify <name> <ok|FAIL> <stub body for dart>; $WORK is a clean repo with committed a.g.dart
verify() {
  new_case
  git -C "$WORK" init -q
  echo old > "$WORK/a.g.dart"
  git -C "$WORK" add a.g.dart
  git -C "$WORK" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init
  stub dart "$3"
  run "$SCRIPT"
  if [ "$2" = FAIL ]; then expect_fail "$1" "${4:-}"; else expect_ok "$1"; fi
}

verify "up to date" ok ""
expect "runs build_runner" "dart run build_runner build --delete-conflicting-outputs" "$(stub_log)"
verify "stale tracked file" FAIL "echo new > a.g.dart" "build_runner changed the working tree"
expect "lists the stale file" "yes" "$(grep -q 'a.g.dart' "$CASE_DIR/stdout" && echo yes)"
verify "uncommitted new file" FAIL "echo x > b.freezed.dart" "build_runner changed the working tree"
verify "deleted file" FAIL "rm a.g.dart" "build_runner changed the working tree"
verify "build_runner fails" FAIL "exit 1"

new_case
mkdir -p "$WORK/app"
git -C "$WORK" init -q
echo x > "$WORK/other.txt"
WORK="$WORK/app"
stub dart "echo y > ../other.txt"
run "$SCRIPT"
expect_ok "ignores changes outside the working directory"

finish
