#!/usr/bin/env bash
# Runs every guard case against hooks/guard.py and fails on the first wrong exit code.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
guard="$here/hooks/guard.py"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0
fail=0

# expect <name> <want exit> <json> [VAR=value ...]
expect() {
  local name="$1" want="$2" json="$3"
  shift 3
  local got
  printf '%s' "$json" | env "$@" python3 "$guard" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL $name: want $want got $got"
  fi
}

bash_json() { jq -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }

# commit style
expect "commit ok" 0 "$(bash_json 'git commit -m "feat(auth): add login"')"
expect "commit no scope ok" 0 "$(bash_json 'git commit -m "fix: stop crash on empty list"')"
expect "commit bad type" 2 "$(bash_json 'git commit -m "added login"')"
expect "commit two -m" 2 "$(bash_json 'git commit -m "feat: a" -m "body"')"
expect "commit heredoc" 2 "$(bash_json $'git commit -m "$(cat <<\'EOF\'\nfeat: a\n\nbody\nEOF\n)"')"
expect "commit trailer" 2 "$(bash_json 'git commit -m "feat: a Co-Authored-By: X"')"
expect "commit em dash" 2 "$(bash_json 'git commit -m "feat: add — login"')"
expect "commit amend no msg" 0 "$(bash_json 'git commit --amend --no-edit')"
expect "chained add and commit" 0 "$(bash_json $'git add a.txt\ngit commit -m "chore: tidy"')"
expect "not a commit" 0 "$(bash_json 'git status')"

# pull request
expect "pr ok" 0 "$(bash_json 'gh pr create --title "fix: stop crash" --body "text"')"
expect "pr bad title" 2 "$(bash_json 'gh pr create --title "Stop crash" --body "text"')"
expect "pr em dash body" 2 "$(bash_json 'gh pr create --title "fix: a" --body "a — b"')"

# merge level
expect "merge off blocks" 2 "$(bash_json 'gh pr merge 5 --merge')" CLAUDE_PLUGIN_OPTION_MERGE=off
expect "merge default blocks" 2 "$(bash_json 'gh pr merge 5 --merge')"
expect "merge on-green ok" 0 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)"')" CLAUDE_PLUGIN_OPTION_MERGE=on-green
expect "merge subject needs number" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a"')" CLAUDE_PLUGIN_OPTION_MERGE=full

# em dash in written files
expect "write em dash" 2 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}'
expect "edit em dash" 2 '{"tool_name":"Edit","tool_input":{"file_path":"a.md","new_string":"a — b"}}'
expect "write clean" 0 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a, b"}}'
expect "write em dash allowed" 0 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}' CLAUDE_PLUGIN_OPTION_EM_DASH=allow

# large file reads
seq 1 351 > "$tmp/big.txt"
seq 1 350 > "$tmp/ok.txt"
seq 1 900 > "$tmp/big.g.dart"
expect "read big blocked" 2 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.txt\"}}"
expect "read 350 ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/ok.txt\"}}"
expect "read big with range ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.txt\",\"offset\":10,\"limit\":50}}"
expect "read generated ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.g.dart\"}}"
expect "read missing ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/none.txt\"}}"

# session start prints the active settings
out="$(printf '{"hook_event_name":"SessionStart"}' | env CLAUDE_PLUGIN_OPTION_SCALE=large CLAUDE_PLUGIN_OPTION_MERGE=full python3 "$guard")"
case "$out" in *"scale=large"*"merge=full"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL session start: $out" ;; esac

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
