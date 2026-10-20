#!/usr/bin/env bash
# Compares one tiny task with and without the harness plugin: wall time, API time, turns, tokens, cost.
# Usage: bench/run.sh [runs per condition, default 3]. Needs claude, jq, python3. It spends real tokens.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
runs="${1:-3}"
out="$here/bench/results"
mkdir -p "$out"
task='Add a function slugify(text) to slug.py that lowercases, replaces runs of non-alphanumerics with one hyphen, and trims hyphens at both ends. Add a unit test in test_slug.py. Run python3 -m unittest, then commit with a one line message. Do not push.'
# Bash is fully allowed because compound commands never match a prefix rule. It runs in a throwaway repo.
allow='Read,Edit,Write,Grep,Glob,Bash'

# fresh_repo <dir>: a tiny git repo with a stub module and one passing test.
fresh_repo() {
  rm -rf "$1" && mkdir -p "$1" && cd "$1" || exit 1
  git init -q -b main
  printf 'def shout(text):\n    return text.upper()\n' > slug.py
  printf 'import unittest\nfrom slug import shout\n\n\nclass T(unittest.TestCase):\n    def test_shout(self):\n        self.assertEqual(shout("a"), "A")\n\n\nif __name__ == "__main__":\n    unittest.main()\n' > test_slug.py
  git add -A && git -c user.name=bench -c user.email=b@b commit -qm "chore: init"
}

# run_one <label> <n> <extra claude args...>: one headless run, saves the JSON, checks the outcome.
run_one() {
  local label="$1" n="$2"
  shift 2
  local dir="$out/work-$label-$n"
  fresh_repo "$dir"
  local start=$(date +%s)
  claude -p "$PROMPT" --output-format json --model "$MODEL" --permission-mode dontAsk \
    --allowedTools "$allow" --setting-sources project "$@" > "$out/$label-$n.json" 2> "$out/$label-$n.err"
  local wall=$(( $(date +%s) - start ))
  local tests=fail slug=fail commits msg
  (cd "$dir" && python3 -m unittest >/dev/null 2>&1) && tests=pass
  [ "$(cd "$dir" && python3 -c 'from slug import slugify; print(slugify("--Hello,  World!--"))' 2>/dev/null)" = "hello-world" ] && slug=pass
  commits=$(git -C "$dir" rev-list --count HEAD)
  msg=$(git -C "$dir" log -1 --format=%s)
  jq -c --arg label "$label" --argjson wall "$wall" --arg tests "$tests" --arg slug "$slug" --argjson commits "$commits" --arg msg "$msg" '{
    label: $label, wall_s: $wall, api_s: ((.duration_api_ms // 0) / 1000), turns: .num_turns, cost_usd: .total_cost_usd,
    input: .usage.input_tokens, output: .usage.output_tokens,
    cache_write: .usage.cache_creation_input_tokens, cache_read: .usage.cache_read_input_tokens,
    tests: $tests, slug: $slug, commits: $commits, last_commit: $msg}' "$out/$label-$n.json" >> "$out/rows.jsonl"
}

: > "$out/rows.jsonl"
MODEL=sonnet
for n in $(seq 1 "$runs"); do
  PROMPT="$task"
  run_one baseline "$n"
  PROMPT="/harness:ship scale is small, there is no remote so stop after the commit. $task"
  run_one harness "$n" --plugin-dir "$here"
done

# hook cost: the guard runs before every Bash, Write, Edit, and Read call.
guard_ms=$(python3 - "$here/hooks/guard.py" <<'P'
import subprocess, sys, time
payload = b'{"tool_name":"Bash","tool_input":{"command":"git status"}}'
start = time.perf_counter()
for _ in range(50):
    subprocess.run(["python3", sys.argv[1]], input=payload, capture_output=True)
print(round((time.perf_counter() - start) / 50 * 1000, 1))
P
)

echo "guard.py per call: ${guard_ms} ms"
jq -s -r 'group_by(.label)[] | {label: .[0].label, runs: length,
  wall_s: (map(.wall_s) | add / length), api_s: (map(.api_s) | add / length), turns: (map(.turns) | add / length),
  cost_usd: (map(.cost_usd) | add / length), output: (map(.output) | add / length),
  cache_write: (map(.cache_write) | add / length), cache_read: (map(.cache_read) | add / length),
  done_ok: (map(select(.tests == "pass" and .slug == "pass" and .commits == 2)) | length)} | @json' "$out/rows.jsonl"
