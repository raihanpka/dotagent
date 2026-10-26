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
expect "merge subject label" 2 "$(bash_json 'gh pr merge 5 --squash --subject "feat: finish task 3 (#5)" --body "- 1a2b3c4 fix(a): x"')"

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
cfg '{"workflow":"adapt"}'
expect "adapt blocks a merge" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
cfg '{"workflow":"autopilott"}'
expect "workflow typo blocks" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
cfg 'not json'
expect "merge bad file blocks" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
cfg '{"scale":"large"}'
expect "workflow key missing is autopilot" 0 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
rm "$tmp/proj/.dotagent/config.json"
expect "workflow default is autopilot" 0 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
expect "merge admin is refused" 2 "$(bash_json 'gh pr merge 5 --squash --admin --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
cfg '{"workflow":"autopilot"}'
expect "autopilot merge ok" 0 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
cfg '{"workflow":"autopilot"}'
expect "autopilot merge ok again" 0 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
expect "merge wrong number" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#6)" --body "- 1a2b3c4 fix(a): x"')"
expect "merge commit is refused" 2 "$(bash_json 'gh pr merge 5 --merge --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"')"
expect "rebase is refused" 2 "$(bash_json 'gh pr merge 5 --rebase')"
expect "squash needs a subject" 2 "$(bash_json 'gh pr merge 5 --squash --body "- 1a2b3c4 fix(a): x"')"
expect "squash needs a body" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)"')"
expect "squash empty body is refused" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body ""')"
expect "squash prose body is refused" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "long text"')"
expect "squash body with a co-author is refused" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x
Co-Authored-By: X <x@y.z>"')"
expect "squash body with many commits ok" 0 "$(bash_json 'gh pr merge 5 --squash --delete-branch --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x
- 5d6e7f8 test(a): y"')"
expect "squash body file is refused" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a (#5)" --body-file b.md')"
expect "merge subject needs number" 2 "$(bash_json 'gh pr merge 5 --squash --subject "fix: a" --body "- 1a2b3c4 fix(a): x"')"
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
expect "config edit blocked" 2 "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$tmp/proj/.dotagent/config.json\",\"content\":\"{}\"}}"
expect "a config copy in a subfolder is not the config" 0 "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$tmp/proj/examples/x/.dotagent/config.json\",\"content\":\"{}\"}}"

# set validates and writes the config
set_out="$(sh "$guard" set workflow adapt)"
[ "$set_out" = "workflow=adapt" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL set merge: $set_out"; }
sh "$guard" set workflow sometimes >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL set accepts a bad value"; } || pass=$((pass + 1))
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
expect "config set via run.sh ok" 0 "$(bash_json 'sh /p/hooks/run.sh set workflow off')"

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
case "$out" in *"scale"*) fail=$((fail + 1)); echo "FAIL session line still names the scale: $out" ;; *"workflow=autopilot"*"style=caveman"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL session start: $out" ;; esac

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

# protected paths, per-PR file scope, subagent receipt
cfg '{"protected":"db/migrations/**,.github/CODEOWNERS"}'
expect "protected path blocks" 2 '{"tool_name":"Edit","tool_input":{"file_path":"db/migrations/001_a.sql","new_string":"x"}}'
expect "protected exact file blocks" 2 '{"tool_name":"Write","tool_input":{"file_path":".github/CODEOWNERS","content":"x"}}'
expect "unprotected path ok" 0 '{"tool_name":"Write","tool_input":{"file_path":"src/a.go","content":"x"}}'
cfg '{}'
printf '# TODO: x\n\n## PR 1: feat(a): add a\nfiles: internal/a/**, internal/app/app.go\n\n- [ ] 1.1 (S) `feat(a): add a`. x.\n\ndone:\n' > "$tmp/proj/docs/TODO.md"
sh "$guard" phase build >/dev/null
expect "scope allows a listed folder" 0 '{"tool_name":"Edit","tool_input":{"file_path":"internal/a/x/y.go","new_string":"x"}}'
expect "scope allows a listed file" 0 '{"tool_name":"Edit","tool_input":{"file_path":"internal/app/app.go","new_string":"x"}}'
expect "scope blocks an unlisted file" 2 '{"tool_name":"Edit","tool_input":{"file_path":"internal/b/z.go","new_string":"x"}}'
expect "scope allows the TODO" 0 '{"tool_name":"Edit","tool_input":{"file_path":"docs/TODO.md","new_string":"x"}}'
sh "$guard" phase done >/dev/null
expect "scope is off outside a build" 0 '{"tool_name":"Edit","tool_input":{"file_path":"internal/b/z.go","new_string":"x"}}'
printf '# TODO: x\n\n## PR 1: feat(a): add a\n\n- [ ] 1.1 (S) `feat(a): add a`. x.\n\ndone:\n' > "$tmp/proj/docs/TODO.md"
sh "$guard" phase build >/dev/null
expect "no files line means no scope" 0 '{"tool_name":"Edit","tool_input":{"file_path":"internal/b/z.go","new_string":"x"}}'
sh "$guard" phase done >/dev/null
printf '{"hook_event_name":"SessionStart"}' | sh "$guard" >/dev/null
expect "agent spawn is never blocked" 0 '{"tool_name":"Agent","tool_input":{"subagent_type":"dotagent:worker"}}'
expect "second spawn" 0 '{"tool_name":"Agent","tool_input":{"subagent_type":"dotagent:worker"}}'
expect "reviewer spawn" 0 '{"tool_name":"Agent","tool_input":{"subagent_type":"dotagent:reviewer"}}'
out="$(sh "$guard" receipt)"
case "$out" in "subagents: worker 2, reviewer 1") pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL receipt: $out" ;; esac
out="$(sh "$guard" status)"
case "$out" in 1) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL status: $out" ;; esac
printf '{"hook_event_name":"SessionStart"}' | sh "$guard" >/dev/null
out="$(sh "$guard" receipt)"
case "$out" in "subagents: none") pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL receipt reset: $out" ;; esac

# first run line and protected in the session line
rm -f "$tmp/proj/.dotagent/config.json"
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"scale"*) fail=$((fail + 1)); echo "FAIL first run line names the scale: $out" ;; *"first run"*"workflow=autopilot"*"tracked files"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL first run line: $out" ;; esac
cfg '{"scale":"medium","protected":"go.sum"}'
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"first run"*) fail=$((fail + 1)); echo "FAIL first run shown with a config: $out" ;; *"protected=go.sum"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL protected in line: $out" ;; esac
cfg '{}'

# saved answers, the git exclude entry, and the first run line
sh "$guard" set setup minimal >/dev/null && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL set setup"; }
sh "$guard" set setup maybe >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL setup accepts a bad value"; } || pass=$((pass + 1))
sh "$guard" set hooks declined >/dev/null && sh "$guard" set big_plan ok >/dev/null && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL set hooks or big_plan"; }
case "$(sh "$guard" show)" in *"setup=minimal"*"hooks=declined"*"big_plan=ok"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL show answers: $(sh "$guard" show)" ;; esac
cfg '{}'
x="$tmp/exproj"
mkdir -p "$x" && git -C "$x" init -q
CLAUDE_PROJECT_DIR=$x sh "$guard" set workflow checkpoint >/dev/null
CLAUDE_PROJECT_DIR=$x sh "$guard" set workflow autopilot >/dev/null
[ "$(git -C "$x" status --porcelain)" = "" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL config is not ignored: $(git -C "$x" status --porcelain)"; }
[ "$(grep -c '^.dotagent/$' "$x/.git/info/exclude")" = "1" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL exclude line is not written once"; }
out="$(printf '{"hook_event_name":"SessionStart"}' | CLAUDE_PROJECT_DIR=$x sh "$guard")"
case "$out" in *"first run"*) fail=$((fail + 1)); echo "FAIL first run after saving the workflow: $out" ;; *) pass=$((pass + 1)) ;; esac

# the scale setting is gone: set refuses it with a hint, and an old config that still has it loads as before
out="$(sh "$guard" set scale medium 2>&1)" && { fail=$((fail + 1)); echo "FAIL set scale is accepted"; } || case "$out" in *"scale was removed"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL set scale hint: $out" ;; esac
cfg '{"scale":"large"}'
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"first run"*|*"scale"*) fail=$((fail + 1)); echo "FAIL an old scale key: $out" ;; *"workflow=autopilot"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL old scale session line: $out" ;; esac
cfg '{}'

# workflow modes: autopilot, checkpoint, adapt
SQ='--squash --subject "fix: a (#5)" --body "- 1a2b3c4 fix(a): x"'
cfg '{"workflow":"autopilot"}'
expect "autopilot pushes" 0 "$(bash_json 'git push origin feat/a')"
expect "autopilot opens a PR" 0 "$(bash_json 'gh pr create --title "fix: a" --body "text"')"
cfg '{"workflow":"adapt"}'
expect "adapt never pushes" 2 "$(bash_json 'git push origin feat/a')"
expect "adapt never opens a PR" 2 "$(bash_json 'gh pr create --title "fix: a" --body "text"')"
expect "adapt never merges on the remote" 2 "$(bash_json "gh pr merge 5 $SQ")"
expect "adapt keeps local commits" 0 "$(bash_json 'git commit -m "feat(a): add a"')"
expect "adapt allows a local squash" 0 "$(bash_json 'git merge --squash feat/a')"
cfg '{"workflow":"checkpoint"}'
ask_out() { printf '%s' "$1" | sh "$guard" 2>/dev/null; }
out="$(ask_out "$(bash_json 'git push origin feat/a')")"
case "$out" in *'"permissionDecision": "ask"'*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL checkpoint push does not ask: $out" ;; esac
expect "checkpoint asks, it does not block" 0 "$(bash_json 'git push origin feat/a')"
expect "checkpoint commits locally" 0 "$(bash_json 'git commit -m "feat(a): add a"')"
sh "$guard" approve >/dev/null
out="$(ask_out "$(bash_json 'git push origin feat/a')")"
case "$out" in *'"permissionDecision"'*) fail=$((fail + 1)); echo "FAIL checkpoint asks after a yes: $out" ;; *) pass=$((pass + 1)) ;; esac
expect "checkpoint merges after a yes" 0 "$(bash_json "gh pr merge 5 $SQ")"
out="$(ask_out "$(bash_json "gh pr merge 5 $SQ")")"
case "$out" in *'"permissionDecision": "ask"'*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL a yes covers more than one PR: $out" ;; esac
# the old merge key is read once
cfg '{"merge":"on-green"}'
case "$(sh "$guard" show)" in *"workflow=autopilot"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL old on-green: $(sh "$guard" show)" ;; esac
cfg '{"merge":"full"}'
case "$(sh "$guard" show)" in *"workflow=autopilot"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL old full: $(sh "$guard" show)" ;; esac
cfg '{"merge":"off"}'
case "$(sh "$guard" show)" in *"workflow=checkpoint"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL old off: $(sh "$guard" show)" ;; esac
cfg '{"merge":"sometimes"}'
case "$(sh "$guard" show)" in *"workflow=adapt"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL old typo: $(sh "$guard" show)" ;; esac
cfg 'not json'
case "$(sh "$guard" show)" in *"workflow=adapt"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL broken file: $(sh "$guard" show)" ;; esac
cfg '{}'

# force push, and the hash list in a local squash commit
cfg '{"workflow":"autopilot"}'
expect "force push is refused" 2 "$(bash_json 'git push --force origin feat/a')"
expect "short force push is refused" 2 "$(bash_json 'git push -f origin feat/a')"
expect "force with lease is allowed" 0 "$(bash_json 'git push --force-with-lease origin feat/a')"
expect "squash commit with a hash list" 0 "$(bash_json 'git commit -m "feat(tasks): paginate the task list

- 1a2b3c4 test(tasks): cover the pages
- 5d6e7f8 feat(tasks): page the list"')"
expect "commit body with prose is refused" 2 "$(bash_json 'git commit -m "feat(tasks): paginate

this adds paging"')"
expect "commit body with a trailer is refused" 2 "$(bash_json 'git commit -m "feat(tasks): paginate

- 1a2b3c4 feat(tasks): x
Co-Authored-By: X <x@y.z>"')"
cfg '{}'

# the session line carries the saved answers
cfg '{"scale":"medium","setup":"minimal","hooks":"declined"}'
out="$(printf '{"hook_event_name":"SessionStart"}' | sh "$guard")"
case "$out" in *"setup=minimal hooks=declined"*) pass=$((pass + 1)) ;; *) fail=$((fail + 1)); echo "FAIL answers in the session line: $out" ;; esac
cfg '{}'

# deleting a test to get green is refused, other deletes are not
cfg '{}'
expect "rm of a js test" 2 "$(bash_json 'rm tests/a.test.js')"
expect "git rm of a go test" 2 "$(bash_json 'git rm internal/x/x_test.go')"
expect "rm of a python test" 2 "$(bash_json 'rm -f pkg/test_login.py')"
expect "rm of the tests folder" 2 "$(bash_json 'rm -rf tests')"
expect "git rm after another command" 2 "$(bash_json 'git add a && git rm -q src/__tests__/a.js')"
expect "rm of a source file" 0 "$(bash_json 'rm src/a.js')"
expect "git rm of a source file" 0 "$(bash_json 'git rm src/login.go')"
expect "rm of a log" 0 "$(bash_json 'rm -f build/out.log')"
expect "a file named like test data is fine" 0 "$(bash_json 'rm test_data.txt')"
expect "grep for a test is fine" 0 "$(bash_json 'grep -rn rm tests/a.test.js')"

# the gate is recorded per commit: ok at the same HEAD, stale after a commit, an edit, or with no record
g="$tmp/gate"
mkdir -p "$g" && git -C "$g" init -q && git -C "$g" config user.email t@t && git -C "$g" config user.name t
printf 'a\n' > "$g/a.txt" && git -C "$g" add a.txt && git -C "$g" commit -qm "feat(a): add a"
gate() { CLAUDE_PROJECT_DIR=$g sh "$guard" gate "$@"; }
[ "$(gate check)" = stale ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check with no record: $(gate check)"; }
gate run true >/dev/null
[ "$(gate check)" = ok ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check after pass: $(gate check)"; }
printf 'b\n' >> "$g/a.txt"
[ "$(gate check)" = stale ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check after an edit: $(gate check)"; }
git -C "$g" checkout -q a.txt
[ "$(gate check)" = ok ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check after the edit is undone: $(gate check)"; }
printf 'b\n' >> "$g/a.txt" && git -C "$g" commit -qam "feat(a): add b"
[ "$(gate check)" = stale ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check after a commit: $(gate check)"; }
[ "$(git -C "$g" status --porcelain)" = "" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate record is not ignored: $(git -C "$g" status --porcelain)"; }
n="$tmp/nogit"
mkdir -p "$n"
[ "$(CLAUDE_PROJECT_DIR=$n sh "$guard" gate check)" = stale ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate check outside git"; }
CLAUDE_PROJECT_DIR=$n sh "$guard" gate run true >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL gate run outside git"; } || pass=$((pass + 1))
# a failing gate records nothing and its exit code comes back, a gate on a dirty tree is refused, and a missing command is an error
gate run sh -c 'exit 3' >/dev/null 2>&1; [ $? -eq 3 ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate run does not return the exit code"; }
[ "$(gate check)" = stale ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL a failing gate left a record: $(gate check)"; }
gate run true >/dev/null && [ "$(gate check)" = ok ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "FAIL gate run true did not record"; }
printf 'c\n' >> "$g/a.txt"
gate run true >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL gate run on a dirty tree"; } || pass=$((pass + 1))
git -C "$g" checkout -q a.txt
gate run no-such-command-here >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL gate run of a missing command"; } || pass=$((pass + 1))
gate pass >/dev/null 2>&1 && { fail=$((fail + 1)); echo "FAIL gate pass still exists"; } || pass=$((pass + 1))

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
