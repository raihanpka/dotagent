#!/usr/bin/env bash
# Confirms every grader fails on the untouched base app, so a pass later means the agent built the feature.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for t in "$root"/benchmark/tasks/*/; do
  id="$(basename "$t")"
  rm -rf "$tmp/app"; cp -R "$root/examples/taskboard-backend" "$tmp/app"
  cp "$t/bench_test.go" "$tmp/app/internal/app/bench_test.go"
  if (cd "$tmp/app" && go test ./internal/app -run TestBench >/dev/null 2>&1); then
    echo "FAIL $id: grader passes on the base app"; exit 1
  fi
  echo "ok   $id: grader fails on the base app"
done
