#!/usr/bin/env bash
# Compares three conditions on one small multi-step task in a throwaway Python repo:
#   baseline: plain Claude, no rules      rules: the same rules as an AGENTS.md only, no plugin
#   plugin:   the plugin with scale=medium (planner, Haiku slicers, reviewer, hooks)
# Measures time, tokens, cost, hidden acceptance tests, and how conformant the commits are.
# Usage: bench/run.sh [runs per condition, default 2]. It spends real tokens, about $0.1 to $0.5 a run.
# The repo is disposable, so permissions are bypassed. Do not point this at a real repo.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
runs="${1:-2}"
out="$here/bench/results"
mkdir -p "$out"

task='Build a small shopping cart in this repo. 1) pricing.py: apply_discount(price, percent) returns the discounted price rounded to 2 decimals and raises ValueError when percent is outside 0 to 100 or price is negative. 2) cart.py: class Cart with add(name, price, qty=1), remove(name), and total(percent_off=0) that uses apply_discount, and add raises ValueError when qty is below 1. 3) a short README.md section with usage. Add unit tests for each part and run them with python3 -m unittest. Make atomic commits, one per part, and commit everything. Do not push.'

# fresh_repo <dir> <with rules 0|1>: a git repo with a stub module, one test, and optionally the rules file.
fresh_repo() {
  rm -rf "$1" && mkdir -p "$1" && cd "$1" || exit 1
  git init -q -b main
  printf '# shop\n' > README.md
  printf 'def shout(text):\n    return text.upper()\n' > util.py
  printf 'import unittest\nfrom util import shout\n\n\nclass T(unittest.TestCase):\n    def test_shout(self):\n        self.assertEqual(shout("a"), "A")\n\n\nif __name__ == "__main__":\n    unittest.main()\n' > test_util.py
  if [ "$2" = 1 ]; then cp "$here/AGENTS.md" AGENTS.md && printf '@AGENTS.md\n' > CLAUDE.md; fi
  git add -A && git -c user.name=bench -c user.email=b@b commit -qm "chore(repo): init"
}

# hidden acceptance checks the agent never saw
accept() {
  (cd "$1" && python3 - <<'P'
import sys
try:
    from pricing import apply_discount
    from cart import Cart
    assert apply_discount(19.99, 10) == 17.99
    assert apply_discount(10, 0) == 10 and apply_discount(10, 100) == 0
    for bad in [(10, -1), (10, 101), (-5, 10)]:
        try:
            apply_discount(*bad); sys.exit(1)
        except ValueError:
            pass
    c = Cart(); c.add("a", 2.5, 2); c.add("b", 1.0)
    assert c.total() == 6.0 and c.total(percent_off=50) == 3.0
    c.remove("a"); assert c.total() == 1.0
    try:
        c.add("z", 1, 0); sys.exit(1)
    except ValueError:
        pass
except SystemExit:
    raise
except Exception:
    sys.exit(1)
P
  ) >/dev/null 2>&1 && echo pass || echo fail
}

# git facts about the commits the agent made, as one JSON object
commit_facts() {
  python3 - "$1" <<'P'
import json, re, subprocess, sys
d = sys.argv[1]
def git(*a): return subprocess.run(["git", "-C", d, *a], capture_output=True, text=True).stdout
shas = git("rev-list", "--reverse", "HEAD").split()[1:]
pat = re.compile(r"^(feat|fix|hotfix|docs|style|refactor|test|chore|perf|revert|ci|build)\([a-zA-Z0-9_.-]+\): \S")
ok = single = small = tested = 0
for s in shas:
    body = git("log", "-1", "--format=%B", s).rstrip("\n")
    files = [f for f in git("show", "--name-only", "--format=", s).split("\n") if f]
    ok += bool(pat.match(body.split("\n")[0]))
    single += "\n" not in body and "co-authored-by" not in body.lower()
    small += len(files) <= 4
    tested += any("test" in f for f in files)
py = [f for f in subprocess.run(["git", "-C", d, "ls-files", "*.py"], capture_output=True, text=True).stdout.split()]
longest = max((sum(1 for _ in open(f"{d}/{f}")) for f in py), default=0)
print(json.dumps({"commits": len(shas), "scoped": ok, "oneline": single, "small": small, "with_tests": tested, "longest_py": longest}))
P
}

# run_one <label> <n> <rules 0|1> <prompt> [extra claude args...]
run_one() {
  local label="$1" n="$2" rules="$3" prompt="$4"
  shift 4
  local dir="$out/work-$label-$n"
  fresh_repo "$dir" "$rules"
  local start=$(date +%s)
  claude -p "$prompt" --output-format json --model sonnet --permission-mode bypassPermissions \
    --setting-sources project "$@" < /dev/null > "$out/$label-$n.json" 2> "$out/$label-$n.err"
  local wall=$(( $(date +%s) - start ))
  local unit=fail
  (cd "$dir" && python3 -m unittest >/dev/null 2>&1) && unit=pass
  jq -c --arg label "$label" --argjson wall "$wall" --arg unit "$unit" --arg acc "$(accept "$dir")" --argjson facts "$(commit_facts "$dir")" '{
    label: $label, wall_s: $wall, turns: .num_turns, cost_usd: .total_cost_usd, output: .usage.output_tokens,
    cache_write: .usage.cache_creation_input_tokens, cache_read: .usage.cache_read_input_tokens,
    own_tests: $unit, acceptance: $acc} + $facts' "$out/$label-$n.json" >> "$out/rows.jsonl"
}

: > "$out/rows.jsonl"
for n in $(seq 1 "$runs"); do
  run_one baseline "$n" 0 "$task"
  run_one rules "$n" 1 "$task"
  CLAUDE_PLUGIN_OPTION_SCALE=medium run_one plugin "$n" 0 "/dotagent:ship $task" --plugin-dir "$here"
done

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
  wall_s: (map(.wall_s) | add / length), cost_usd: ((map(.cost_usd) | add / length) * 1000 | round / 1000),
  commits: (map(.commits) | add / length), scoped: (map(.scoped) | add), oneline: (map(.oneline) | add),
  with_tests: (map(.with_tests) | add), acceptance_passed: (map(select(.acceptance == "pass")) | length),
  own_tests_passed: (map(select(.own_tests == "pass")) | length), longest_py: (map(.longest_py) | max)} | @json' "$out/rows.jsonl"
