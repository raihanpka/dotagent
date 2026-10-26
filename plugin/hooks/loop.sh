#!/bin/sh
# Fresh context per PR: runs `claude -p` once for each unfinished PR in docs/TODO.md, so the lead never carries
# the whole plan. Usage: sh loop.sh [max PRs]. Env CLAUDE_FLAGS adds flags, for example
# CLAUDE_FLAGS="--max-budget-usd 5" caps the spend of each PR (checked with `claude --help`), --dangerously-skip-permissions skips prompts.
# A subagent cannot start subagents, so the PR cannot be handed to one. A new process per PR is the way.
here="$(dirname "$0")"
max="${1:-10}"
i=0
while [ "$i" -lt "$max" ]; do
  left="$(sh "$here/run.sh" status)"
  [ "$left" = 0 ] && { echo "dotagent: nothing left in docs/TODO.md"; exit 0; }
  # shellcheck disable=SC2086
  claude -p ${CLAUDE_FLAGS:-} "/dotagent:ship continue. Ship exactly one PR, then stop." || exit 1
  now="$(sh "$here/run.sh" status)"
  [ "$now" -ge "$left" ] && { echo "dotagent: no PR landed, stopping at $now left"; exit 1; }
  i=$((i + 1))
done
