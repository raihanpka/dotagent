#!/usr/bin/env bash
# Runs every guard case against hooks/run.sh (which runs guard.py) and fails on the first wrong exit code.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
guard="$here/plugin/hooks/run.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
pass=0
fail=0

# cfg <json> writes the project config, expect <name> <want exit> <json> [VAR=value ...]
mkdir -p "$tmp/proj/.dotagent"
export CLAUDE_PROJECT_DIR="$tmp/proj"
cfg() { printf '%s' "$1" > "$tmp/proj/.dotagent/config.json"; }
expect() {
  local name="$1" want="$2" json="$3"
  shift 3
  local got
  printf '%s' "$json" | env "$@" sh "$guard" >/dev/null 2>&1
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
cfg '{"em_dash":"block","emoji":"block"}'
expect "commit ok" 0 "$(bash_json 'git commit -m "feat(auth): add login"')"
expect "commit scope ok" 0 "$(bash_json 'git commit -m "fix(list): stop crash on empty list"')"
expect "commit needs a scope" 2 "$(bash_json 'git commit -m "fix: stop crash on empty list"')"
expect "commit hotfix type ok" 0 "$(bash_json 'git commit -m "hotfix(api): restore the health route"')"
expect "commit bad type" 2 "$(bash_json 'git commit -m "added login"')"
expect "commit two -m" 2 "$(bash_json 'git commit -m "feat: a" -m "body"')"
expect "commit heredoc" 2 "$(bash_json $'git commit -m "$(cat <<\'EOF\'\nfeat: a\n\nbody\nEOF\n)"')"
expect "commit trailer" 2 "$(bash_json 'git commit -m "feat: a Co-Authored-By: X"')"
expect "commit em dash" 2 "$(bash_json 'git commit -m "feat: add — login"')"
expect "commit amend no msg" 0 "$(bash_json 'git commit --amend --no-edit')"
expect "chained add and commit" 0 "$(bash_json $'git add a.txt\ngit commit -m "chore(repo): tidy"')"
expect "not a commit" 0 "$(bash_json 'git status')"

# plan labels never name a commit or a PR
expect "commit milestone label" 2 "$(bash_json 'git commit -m "feat(milestone-1): add login"')"
expect "commit finishing task" 2 "$(bash_json 'git commit -m "feat(auth): finishing task-1"')"
expect "commit task number" 2 "$(bash_json 'git commit -m "fix(api): task 2 done"')"
expect "commit slice label" 2 "$(bash_json 'git commit -m "chore(repo): slice-3"')"
expect "commit wip" 2 "$(bash_json 'git commit -m "feat(a): wip login"')"
expect "commit todo scope" 2 "$(bash_json 'git commit -m "feat(todo): add login"')"
expect "commit real task word ok" 0 "$(bash_json 'git commit -m "feat(tasks): add the task list endpoint"')"
expect "commit milestone feature ok" 0 "$(bash_json 'git commit -m "feat(billing): add milestone payments"')"
expect "pr title label" 2 "$(bash_json 'gh pr create --title "feat(milestone-2): add overview" --body "text"')"
expect "merge subject label" 2 "$(bash_json 'gh pr merge 5 --merge --subject "feat: finish task 3 (#5)" --body ""')"

# the git hooks format and lint, so they are never skipped
expect "commit no-verify" 2 "$(bash_json 'git commit --no-verify -m "feat(a): add x"')"
expect "commit -n" 2 "$(bash_json 'git commit -n -m "feat(a): add x"')"
expect "commit -nm" 2 "$(bash_json 'git commit -nm "feat(a): add x"')"
expect "push no-verify" 2 "$(bash_json 'git push --no-verify origin feat/x')"
expect "commit -am ok" 0 "$(bash_json 'git commit -am "feat(a): add x"')"
expect "commit with n in the message ok" 0 "$(bash_json 'git commit -m "fix(net): handle -n flag"')"
expect "commit real stage word ok" 0 "$(bash_json 'git commit -m "feat(parser): support stage 2 syntax"')"
expect "commit real part word ok" 0 "$(bash_json 'git commit -m "feat(parser): read part 3 of the header"')"

# the PR number is added by GitHub, never written in a commit or a PR title
expect "commit with PR number" 2 "$(bash_json 'git commit -m "feat(a): add login (#12)"')"
expect "revert commit may carry it" 0 "$(bash_json 'git commit -m "revert(a): Revert add login (#12)"')"
expect "pr title with number" 2 "$(bash_json 'gh pr create --title "feat(a): add login (#12)" --body "text"')"
expect "pr body may reference issues" 0 "$(bash_json 'gh pr create --title "fix: a" --body "Fixes #12"')"

# pull request
expect "pr ok" 0 "$(bash_json 'gh pr create --title "fix: stop crash" --body "text"')"
expect "pr scoped title ok" 0 "$(bash_json 'gh pr create --title "feat(home): add overview" --body "text"')"
expect "pr bad title" 2 "$(bash_json 'gh pr create --title "Stop crash" --body "text"')"
expect "pr em dash body" 2 "$(bash_json 'gh pr create --title "fix: a" --body "a — b"')"

expect "commit emoji" 2 "$(bash_json 'git commit -m "feat(a): add thing 🚀"')"
cfg '{}'
expect "commit emoji blocked by default" 2 "$(bash_json 'git commit -m "feat(a): add thing 🚀"')"
cfg '{"emoji":"allow"}'
expect "commit emoji allowed when the user asks" 0 "$(bash_json 'git commit -m "feat(a): add thing 🚀"')"
cfg '{"em_dash":"block","emoji":"block"}'
expect "pr body emoji" 2 "$(bash_json 'gh pr create --title "fix: a" --body "text 🤖 Generated with Claude Code"')"

# merge level
cfg '{"merge":"off"}'
expect "merge off blocks" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
cfg '{"merge":"on_green"}'
expect "merge typo blocks" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
cfg 'not json'
expect "merge bad file blocks" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
cfg '{"scale":"large"}'
expect "merge key missing is on-green" 0 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
rm "$tmp/proj/.dotagent/config.json"
expect "merge default is on-green" 0 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
expect "merge admin is refused" 2 "$(bash_json 'gh pr merge 5 --merge --admin --subject "fix: a (#5)" --body ""')"
cfg '{"merge":"on-green"}'
expect "merge on-green ok" 0 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
cfg '{"merge":"full"}'
expect "merge commit ok" 0 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body ""')"
expect "merge wrong number" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#6)" --body ""')"
expect "squash is never used" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body ""')"
expect "merge commit needs a subject" 2 "$(bash_json 'gh pr merge 5 --merge --body ""')"
expect "merge commit needs an empty body flag" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)"')"
expect "merge commit body is refused" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body "long text"')"
expect "merge body file is refused" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body-file b.md')"
expect "rebase needs no subject or body" 0 "$(bash_json 'gh pr merge 5 --rebase')"
expect "merge subject needs number" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a" --body ""')"
cfg '{}'

# em dash in written files
cfg '{"em_dash":"block"}'
expect "write em dash" 2 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}'
expect "edit em dash" 2 '{"tool_name":"Edit","tool_input":{"file_path":"a.md","new_string":"a — b"}}'
expect "write clean" 0 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a, b"}}'
cfg '{}'
expect "write em dash blocked by default" 2 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}'
cfg '{"em_dash":"allow"}'
expect "write em dash allowed when the user asks" 0 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}'
cfg '{"em_dash":"nope"}'
expect "a wrong em dash value stays blocked" 2 '{"tool_name":"Write","tool_input":{"file_path":"a.md","content":"a — b"}}'
expect "commit generated-by" 2 "$(bash_json 'git commit -m "feat(a): add login Generated with Claude Code"')"
expect "commit signed-off-by" 2 "$(bash_json 'git commit -m "feat(a): add login Signed-off-by: X"')"
expect "pr body generated-by" 2 "$(bash_json 'gh pr create --title "fix: a" --body "text. Generated with [Claude Code](https://claude.com/claude-code)"')"
expect "pr body co-authored" 2 "$(bash_json 'gh pr create --title "fix: a" --body "text Co-Authored-By: X"')"
expect "commit mentions claude code ok" 0 "$(bash_json 'git commit -m "docs(readme): explain the Claude Code install"')"
expect "pr body clean ok" 0 "$(bash_json 'gh pr create --title "fix: a" --body "Adds the thing. Tests pass."')"
expect "commit em dash blocked by default" 2 "$(bash_json 'git commit -m "feat(a): add — login"')"
cfg '{"em_dash":"allow"}'
expect "commit em dash allowed when the user asks" 0 "$(bash_json 'git commit -m "feat(a): add — login"')"
cfg '{"em_dash":"block","emoji":"block"}'
expect "config edit blocked" 2 '{"tool_name":"Write","tool_input":{"file_path":"/x/.dotagent/config.json","content":"{}"}}'

# set validates and writes the config
set_out="$(sh "$guard" set merge on-green)"
[ "$set_out" = "merge=on-green" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL set merge: $set_out"; }
sh "$guard" set merge sometimes >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL set accepts a bad value"; } || pass=$((pass + 1))
sh "$guard" set color red >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL set accepts a bad key"; } || pass=$((pass + 1))
cfg '{}'

# planning is read-only except docs/TODO.md
sh "$guard" phase plan >/dev/null
expect "plan blocks code write" 2 '{"tool_name":"Write","tool_input":{"file_path":"src/a.go","content":"x"}}'
expect "plan blocks code edit" 2 '{"tool_name":"Edit","tool_input":{"file_path":"src/a.go","new_string":"x"}}'
expect "plan allows the TODO" 0 '{"tool_name":"Write","tool_input":{"file_path":"/r/docs/TODO.md","content":"x"}}'
expect "plan blocks other TODO.md" 2 '{"tool_name":"Write","tool_input":{"file_path":"/r/other-docs/TODO.md","content":"x"}}'
expect "plan blocks commit" 2 "$(bash_json 'git commit -m "feat(a): add thing"')"
expect "plan blocks push" 2 "$(bash_json 'git push -u origin feat/x')"
expect "plan blocks a redirect" 2 "$(bash_json 'echo x > src/a.go')"
expect "plan blocks sed -i" 2 "$(bash_json 'sed -i s/a/b/ src/a.go')"
expect "plan blocks git checkout --" 2 "$(bash_json 'git checkout -- src/a.go')"
expect "plan allows the TODO via shell" 0 "$(bash_json 'cat > docs/TODO.md')"
expect "plan allows stderr redirect" 0 "$(bash_json 'grep -rn foo src 2>/dev/null')"
expect "plan allows the branch cut" 0 "$(bash_json 'git checkout -b feat/x')"
expect "plan allows reading" 0 "$(bash_json 'git diff main...HEAD')"
sh "$guard" phase build >/dev/null
expect "build allows code write" 0 '{"tool_name":"Write","tool_input":{"file_path":"src/a.go","content":"x"}}'
sh "$guard" phase plan >/dev/null
printf '{"hook_event_name":"SessionStart"}' | sh "$guard" >/dev/null
expect "session start clears the plan marker" 0 '{"tool_name":"Write","tool_input":{"file_path":"src/a.go","content":"x"}}'
sh "$guard" phase plan >/dev/null
touch -t 200001010000 "$tmp/proj/.dotagent/phase"
expect "a stale plan marker is ignored" 0 '{"tool_name":"Write","tool_input":{"file_path":"src/a.go","content":"x"}}'
sh "$guard" phase done >/dev/null

# the config file is changed only through run.sh
expect "config redirect blocked" 2 "$(bash_json 'echo {} > .dotagent/config.json')"
expect "config sed blocked" 2 "$(bash_json 'sed -i s/off/full/ .dotagent/config.json')"
expect "config read ok" 0 "$(bash_json 'cat .dotagent/config.json')"
expect "config set via run.sh ok" 0 "$(bash_json 'sh /p/hooks/run.sh set merge off')"

# large file reads
seq 1 501 > "$tmp/big.txt"
seq 1 500 > "$tmp/ok.txt"
seq 1 900 > "$tmp/big.g.dart"
expect "read big blocked" 2 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.txt\"}}"
expect "read 500 ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/ok.txt\"}}"
expect "read big with range ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.txt\",\"offset\":10,\"limit\":50}}"
expect "read generated ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/big.g.dart\"}}"
expect "read missing ok" 0 "{\"tool_name\":\"Read\",\"tool_input\":{\"file_path\":\"$tmp/none.txt\"}}"

# session start prints the active settings
cfg '{"scale":"large","merge":"full","style_skills":"caveman"}'
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"scale=large"*"merge=full"*"style=caveman"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL session start: $out" ;; esac

# git hooks: shipped and on, shipped and off, or not shipped
g="$tmp/gitproj"
mkdir -p "$g/.githooks" && git -C "$g" init -q
[ "$(CLAUDE_PROJECT_DIR=$g sh "$guard" hooks)" = "off" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL hooks off"; }
out="$(printf '{"hook_event_name":"SessionStart"}' | CLAUDE_PROJECT_DIR=$g sh "$guard")"
case "$out" in *"git hooks are off"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL hooks off line: $out" ;; esac
git -C "$g" config core.hooksPath .githooks
[ "$(CLAUDE_PROJECT_DIR=$g sh "$guard" hooks)" = "on" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL hooks on"; }
out="$(printf '{"hook_event_name":"SessionStart"}' | CLAUDE_PROJECT_DIR=$g sh "$guard")"
case "$out" in *"git hooks are off"*) fail=$((fail + 1)); echo "FAIL hooks on but warned" ;; *) pass=$((pass + 1)) ;; esac
[ "$(CLAUDE_PROJECT_DIR=$tmp/proj sh "$guard" hooks)" = "none" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL hooks none"; }

# unfinished work is announced at session start so a bare "continue" can resume it
cfg '{}'
mkdir -p "$tmp/proj/docs"
printf '# TODO: x\n\n## PR 1: feat(a): add a\n\n- [x] 1.1 (S) `feat(a): add a`. x.\n\ndone: https://x/pr/1\n\n## PR 2: feat(b): add b\n\n- [ ] 2.1 (S) `feat(b): add b`. x.\n\ndone:\n' > "$tmp/proj/docs/TODO.md"
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"unfinished: 1 PR(s)"*"feat(b): add b"*"continue"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL unfinished line: $out" ;; esac
printf '# TODO: x\n\n## PR 1: feat(a): add a\n\n- [x] 1.1 (S) `feat(a): add a`. x.\n\ndone: https://x/pr/1\n' > "$tmp/proj/docs/TODO.md"
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *unfinished*) fail=$((fail + 1)); echo "FAIL a finished plan is announced: $out" ;; *) pass=$((pass + 1)) ;; esac
printf '# TODO: x\n\n## PR 1: feat(a): add a\n\n- [x] 1.1 (S) `feat(a): add a`. x.\n\ndone:\n' > "$tmp/proj/docs/TODO.md"
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"unfinished: 1 PR(s)"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL an unmerged PR is not unfinished: $out" ;; esac

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
