---
name: ship
description: Implement a task end to end, from plan to atomic commits, review, PR, CI, and merge. Use when asked to build, fix, or ship a change.
---
# ship

Read the `[dotagent] scale=... merge=... read-limit=... style=...` line from session start.
One task is one branch and one PR, cut from the default branch. Commits are atomic and one
line, `type(scope): summary`. Hooks enforce the format.

## Style skills

`style=` lists skills such as `caveman` or `ponytail:lite`. Invoke each once with the Skill tool
before you start. Skip `none` or a skill that is not installed. They change how you write replies,
not the steps below.

## The team

Sonnet leads: the `planner` cuts the work and the `reviewer` checks it in a fresh context. A swarm
of `slicer` agents on Haiku does the building, one agent per slice, one slice at a time because
slices share one git index. Fixed steps (git, `gh`, CI) are plain commands, not agents.

## By scale

- **small**: no plan. Change, run build, lint, test, commit, open the PR.
- **medium**: spawn `planner` for `.dotagent/plan.md`. Then spawn one `slicer` per slice, in order,
  and wait for each commit before the next. Spawn `reviewer`. Fix gaps, open the PR.
- **large**: run the `ship-large` workflow (`/dotagent:ship-large`) with the Workflow tool. If that tool is not in your
  tool list (headless runs, older Claude Code), say so in one line and do the medium steps.
  The workflow does the medium steps with the limits and retries below and returns the PR. Then apply Merge. Pass the user's words as the argument
  `{ task, context, planOnly }`: `task` is one line of what to build, `context` is
  any pasted requirements verbatim, and `planOnly` is true when the user said plan only.

Whatever the scale, text the user pastes after the task, such as requirements from product, is
input to the plan. Never summarize it away, pass it on verbatim.

## Limits

- At most 8 slices and about 400 changed lines per PR. When the planner says it needs more,
  stop and propose two tasks.
- One slicer runs at a time. Slices that touch the same file are never parallel.
- Every fix (a failed slice, review gaps, a red CI) gets two tries from a Haiku slicer, then one
  try from a Sonnet slicer with the full context, then you stop and report. Never loop past that.

## Open the PR

Push the branch, then `gh pr create` with the planner's title and
`templates/PULL_REQUEST_TEMPLATE.md` filled by the reviewer. Tick only what was done and
delete every unchecked line.

## CI

After the push run `gh pr checks --watch`. On a failure read the failing log, fix it with one
more slice, push, and watch again. Never skip, weaken, or delete a check to get green.

## Merge

- **off**: stop at the open PR and say it is ready. The hook blocks `gh pr merge` anyway.
- **on-green**: merge only when the reviewer said `clean` and CI is green.
- **full**: as on-green, and also fix review gaps yourself before merging.

Merge with `gh pr merge <n> --merge --delete-branch --subject "<PR title> (#<n>)"`. Then switch
to the default branch and pull.

## Done condition

Use this with `/goal` for an unattended run: `PR is open, CI is green, reviewer said clean, or
a limit above was reached and the failure is reported`.
