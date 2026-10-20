#!/usr/bin/env bash
# Runs a case under three conditions and prints a comparison table.
#   baseline: the repo's own AGENTS.md (facts only), plain Claude
#   rules:    that file plus dotagent's generic rules as plain text, no plugin
#   plugin:   the same file plus the dotagent plugin at scale=medium (hooks, planner, slicers, reviewer)
# Usage: bench/run.sh [case, default recurring-tasks] [runs per condition, default 2]
# It spends real tokens, about $0.2 to $0.8 a run, and bypasses permissions inside a throwaway copy.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
case_name="${1:-recurring-tasks}"
runs="${2:-2}"
case_dir="$here/bench/cases/$case_name"
out="$here/bench/results/$case_name"
[ -d "$case_dir/repo" ] || { echo "no such case: $case_dir"; exit 1; }
mkdir -p "$out"
task="$(cat "$case_dir/task.md")

Commit your work in atomic commits. Do not push."

# fresh_repo <dir> <with generic rules 0|1>: a copy of the case repo as a git repo with one commit.
fresh_repo() {
  rm -rf "$1" && mkdir -p "$1" && cp -R "$case_dir/repo/." "$1" && cd "$1" || exit 1
  if [ "$2" = 1 ]; then { printf '\n'; cat "$here/AGENTS.md"; } >> AGENTS.md; fi
  printf '@AGENTS.md\n' > CLAUDE.md
  git init -q -b main && git add -A && git -c user.name=bench -c user.email=b@b commit -qm "chore(repo): init"
}

# commit_facts <dir>: how conformant the agent's commits are, as one JSON object.
commit_facts() {
  python3 - "$1" <<'P'
import json, re, subprocess, sys
d = sys.argv[1]
def git(*a): return subprocess.run(["git", "-C", d, *a], capture_output=True, text=True).stdout
shas = git("rev-list", "--reverse", "HEAD").split()[1:]
pat = re.compile(r"^(feat|fix|hotfix|docs|style|refactor|test|chore|perf|revert|ci|build)\([a-zA-Z0-9_.-]+\): \S")
scoped = oneline = small = 0
for s in shas:
    body = git("log", "-1", "--format=%B", s).rstrip("\n")
    files = [f for f in git("show", "--name-only", "--format=", s).split("\n") if f]
    scoped += bool(pat.match(body.split("\n")[0]))
    oneline += "\n" not in body and "co-authored-by" not in body.lower()
    small += len(files) <= 4
changed = git("diff", "--shortstat", "HEAD~%d" % len(shas), "HEAD").strip() if shas else ""
py = subprocess.run(["git", "-C", d, "ls-files", "*.py"], capture_output=True, text=True).stdout.split()
longest = max((sum(1 for _ in open(f"{d}/{f}")) for f in py), default=0)
test_files = sum(1 for f in py if "test" in f)
print(json.dumps({"commits": len(shas), "scoped": scoped, "oneline": oneline, "small": small,
                  "test_files": test_files, "longest_py": longest, "diff": changed}))
P
}

# run_one <label> <n> <rules 0|1> <prompt> [extra claude args...]
run_one() {
  local label="$1" n="$2" rules="$3" prompt="$4"
  shift 4
  local dir="$out/work-$label-$n"
  fresh_repo "$dir" "$rules"
  local start=$(date +%s)
  # Each run is a fresh process in its own folder with no saved session and no auto memory, so no run can
  # see another run's work. --setting-sources project keeps your user plugins and memory out of the run.
  CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 claude -p "$prompt" --output-format json --model sonnet \
    --permission-mode bypassPermissions --no-session-persistence --setting-sources project "$@" \
    < /dev/null > "$out/$label-$n.json" 2> "$out/$label-$n.err"
  local wall=$(( $(date +%s) - start ))
  local unit=fail acc
  (cd "$dir" && python3 -m unittest >/dev/null 2>&1) && unit=pass
  acc="$(cd "$dir" && python3 "$case_dir/acceptance.py" 2>&1 | tail -1 | sed 's/acceptance //')"
  jq -c --arg label "$label" --argjson wall "$wall" --arg unit "$unit" --arg acc "${acc:-0/0}" \
    --argjson facts "$(commit_facts "$dir")" --argjson cpl "$(cd "$dir" && python3 "$case_dir/coupling.py")" '{
    label: $label, wall_s: $wall, turns: .num_turns, cost_usd: .total_cost_usd, output: .usage.output_tokens,
    cache_write: .usage.cache_creation_input_tokens, cache_read: .usage.cache_read_input_tokens,
    subagents: (.subagent_stats.spawned // 0),
    haiku_usd: ([.modelUsage | to_entries[] | select(.key | test("haiku")) | .value.costUSD] | add // 0),
    own_tests: $unit, acceptance: $acc, coupling: $cpl.violations} + $facts' "$out/$label-$n.json" >> "$out/rows.jsonl"
}

: > "$out/rows.jsonl"
for n in $(seq 1 "$runs"); do
  run_one baseline "$n" 0 "$task"
  run_one rules "$n" 1 "$task"
  run_one plugin "$n" 1 "/dotagent:ship $task" --plugin-dir "$here"
done

echo "case: $case_name, runs per condition: $runs"
jq -s -r 'group_by(.label)[] | {label: .[0].label,
  acceptance: (map(.acceptance) | join(" ")), coupling_violations: (map(.coupling) | add),
  commits: (map(.commits) | add / length), scoped: (map(.scoped) | add), oneline: (map(.oneline) | add),
  small_commits: (map(.small) | add), longest_py: (map(.longest_py) | max),
  subagents: (map(.subagents) | add / length), haiku_share: (((map(.haiku_usd) | add) / (map(.cost_usd) | add)) * 100 | round | tostring + "%"),
  wall_s: (map(.wall_s) | add / length | round), cost_usd: ((map(.cost_usd) | add / length) * 1000 | round / 1000)} | @json' "$out/rows.jsonl"
