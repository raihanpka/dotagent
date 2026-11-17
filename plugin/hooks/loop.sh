#!/bin/sh
# One fresh context per PR in auto, so the lead never carries the whole plan. It reads the run state first, stops when the run
# is stopped or stalled, and stops when a process moved neither HEAD nor the unfinished count. In local it runs one process for
# the whole TODO and never pushes. Usage: sh loop.sh [max PRs].
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

mode="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" show | tr ' ' '\n' | sed -n 's/^workflow=//p' | head -1)"
if [ "$mode" = "local" ]; then
  echo "dotagent: workflow is local: one process for the whole TODO, no push"
  # shellcheck disable=SC2086
  claude -p ${CLAUDE_FLAGS:-} "/dotagent:ship continue. Finish the local TODO, then stop." || exit 1
  left="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" status)"
  if [ "$left" != 0 ]; then
    echo "dotagent: local run stopped with $left PR(s) left; read docs/TODO.md ## stopped"
    echo "next: read docs/TODO.md and the local branch"
    exit 1
  fi
  echo "dotagent: local TODO finished; nothing was pushed"
  echo "next: review the local branch, then merge it yourself"
  exit 0
fi

while [ "$i" -lt "$max" ]; do
  state="$(CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" state)"
  case "$state" in
    *"run=stopped"*)
      echo "dotagent: $state"
      echo "next: read docs/TODO.md ## stopped, then continue or start a new task"
      exit 0
      ;;
    *"stalled=yes"*)
      CLAUDE_PROJECT_DIR="$root" sh "$here/run.sh" stop no-progress "loop.sh saw four same rows after a pivot"
      echo "dotagent: no progress after a pivot, stopped. $state"
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
