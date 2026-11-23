#!/usr/bin/env bash
set -euo pipefail

dart run build_runner build --delete-conflicting-outputs

changes=$(git status --porcelain -- .)
if [ -n "$changes" ]; then
  echo "::error::Working tree has changes after build_runner (stale or uncommitted files). Run 'dart run build_runner build -d' and commit:"
  echo "$changes"
  exit 1
fi
