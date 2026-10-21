#!/usr/bin/env bash
# One benchmark run: bash benchmark/run.sh <arm> <task> <trial>
# arm: plain | small | medium | large. Writes benchmark/results/<arm>__<task>__<trial>.json.
# Env: MODEL (default sonnet), BUDGET (max USD per run, default 5).
# This spends real tokens. The work copy has no GitHub remote, so the dotagent arms stop before the PR.
set -euo pipefail
arm="${1:?arm}"; task="${2:?task}"; trial="${3:?trial}"
root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/examples/taskboard-backend"
tdir="$root/benchmark/tasks/$task"
out="$root/benchmark/results"; mkdir -p "$out"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

cp -R "$src" "$work/app"; cd "$work/app"
if [ "$arm" = plain ]; then rm -rf .dotagent .githooks .claude docs/DOTAGENT-SETUP.md; fi
git init -q -b main && git add -A && git -c user.name=bench -c user.email=bench@local commit -qm "chore(repo): base"
base="$(git rev-parse HEAD)"
git checkout -qb "bench/$task"

prompt="$(cat "$tdir/prompt.md")"
flags=(-p --output-format json --dangerously-skip-permissions --model "${MODEL:-sonnet}"
       --max-budget-usd "${BUDGET:-5}" --setting-sources project,local)
if [ "$arm" = plain ]; then
  prompt="$prompt

Commit your work on this branch. Do not push."
else
  flags+=(--plugin-dir "$root/plugin")
  prompt="/dotagent:ship $arm $prompt

There is no GitHub remote. Stop after the review and the local commits: do not push, do not open a PR."
fi

start=$(date +%s)
claude "${flags[@]}" "$prompt" > "$work/claude.json" 2> "$work/claude.err" || true
secs=$(( $(date +%s) - start ))

mkdir -p "$out/raw"; cp "$work/claude.json" "$out/raw/${arm}__${task}__${trial}.json" 2>/dev/null || true
# Grade: the hidden test plus the repo's own gate. Uncommitted work counts, so commit nothing for the agent.
cp "$tdir/bench_test.go" internal/app/bench_test.go
resolved=false; gate=false
go test ./internal/app -run TestBench >/dev/null 2>&1 && resolved=true
rm internal/app/bench_test.go
make ci >/dev/null 2>&1 && gate=true

commits="$(git rev-list --count "$base"..HEAD)"
bad="$(git log --format=%s "$base"..HEAD | grep -vcE '^(feat|fix|refactor|test|docs|chore|ci|perf|build)\([a-z0-9-]+\): .+' || true)"
trailers="$(git log --format=%B "$base"..HEAD | grep -ciE 'co-authored-by|generated with' || true)"
lines="$(git diff --shortstat "$base" | tr -dc '0-9 ' | awk '{print $2+$3}')"

export arm task trial resolved gate secs commits bad trailers lines MODEL_NAME="${MODEL:-sonnet}"
python3 - "$work/claude.json" "$out/${arm}__${task}__${trial}.json" <<'PY'
import json, os, sys
e = os.environ
try: r = json.load(open(sys.argv[1]))
except Exception: r = {}
mu = r.get("modelUsage") or {}
def tot(k): return sum(m.get(k, 0) for m in mu.values())
json.dump({
  "arm": e["arm"], "task": e["task"], "trial": int(e["trial"]), "model": e["MODEL_NAME"],
  "resolved": e["resolved"] == "true", "gate_green": e["gate"] == "true", "wall_s": int(e["secs"]),
  "cost_usd": r.get("total_cost_usd"), "turns": r.get("num_turns"),
  "input_tokens": tot("inputTokens"), "output_tokens": tot("outputTokens"),
  "cache_read_tokens": tot("cacheReadInputTokens"), "cache_create_tokens": tot("cacheCreationInputTokens"),
  "models": sorted(mu),
  "commits": int(e["commits"]), "bad_subjects": int(e["bad"]), "trailers": int(e["trailers"]),
  "changed_lines": int(e["lines"] or 0), "is_error": r.get("is_error", True),
  "result_head": str(r.get("result", ""))[:200],
}, open(sys.argv[2], "w"), indent=1)
PY
echo "$arm $task #$trial resolved=$resolved gate=$gate ${secs}s"
