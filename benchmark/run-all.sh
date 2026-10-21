#!/usr/bin/env bash
# Runs the whole matrix: 5 tasks x 4 arms x 3 trials. Spends real money. JOBS runs at once (default 4).
set -euo pipefail
cd "$(dirname "$0")/.."
for i in 1 2 3; do for t in benchmark/tasks/*/; do for a in plain small medium large; do
  echo "$a $(basename "$t") $i"; done; done; done |
  xargs -P "${JOBS:-4}" -L 1 bash benchmark/run.sh
