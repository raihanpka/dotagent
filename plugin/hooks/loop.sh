#!/bin/sh
# One fresh context per PR, so the lead never carries the whole plan. It reads the run state first, stops when the run
# is stopped or stalled, and stops when a process moved neither HEAD nor the unfinished count. Usage: sh loop.sh [max PRs].
# Env CLAUDE_FLAGS adds flags, for example CLAUDE_FLAGS="--max-turns 40" or CLAUDE_FLAGS="--max-budget-usd 5"
# caps the spend of each PR (check `claude --help`), --dangerously-skip-permissions skips prompts.
# A subagent cannot start subagents, so the PR cannot be handed to one. A new process per PR is the way.
here="$(dirname "$0")"
max="${1:-10}"
i=0
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

head_now() {
  git -C "$root" rev-parse HEAD 2>/dev/null || echo none
}

while [ "$i" -lt "$max" ]; do
  state="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" state)"
  case "$state" in
    *"run=stopped"*)
      echo "dotagent: $state"
      echo "next: read docs/TODO.md ## stopped, then continue or start a new task"
      exit 0
      ;;
    *"stalled=yes"*)
      CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" stop no-progress "loop.sh saw two units move nothing"
      echo "dotagent: no progress, stopped. $state"
      exit 1
      ;;
  esac
  left_before="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" status)"
  if [ "$left_before" = 0 ]; then
    echo "dotagent: nothing left in docs/TODO.md"
    echo "next: check the finish predicate, then report"
    exit 0
  fi
  head_before="$(head_now)"
  # shellcheck disable=SC2086
  claude -p ${CLAUDE_FLAGS:-} "/dotagent:ship continue. Ship exactly one PR, then stop." || exit 1
  left_after="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" status)"
  head_after="$(head_now)"
  if [ "$left_after" -ge "$left_before" ] && [ "$head_after" = "$head_before" ]; then
    CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" stop no-progress "a fresh process moved neither HEAD nor the unfinished count"
    echo "dotagent: no PR landed and HEAD did not move, stopped at $left_after left"
    echo "next: read docs/TODO.md ## stopped, then pick the smallest next experiment"
    exit 1
  fi
  i=$((i + 1))
done
echo "dotagent: budget reached after $max PRs"
echo "next: sh \"$here/run.sh\" state"
