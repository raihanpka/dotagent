---
name: ship
description: Implement a task end to end, from plan to atomic commits, review, PR, CI, and merge. Use when asked to build, fix, or ship a change.
---
# ship

Read the `[harness] scale=... merge=...` line from session start. One task is one branch and one
PR, cut from the default branch. Commits are atomic and one line (hooks enforce the format).

## By scale

- **small**: no plan. Change, run build, lint, test, commit, open the PR.
- **medium**: spawn `planner` for `tasks/plan.md`. Then spawn `slicer` once per slice, in order,
  and wait for each commit before the next. Spawn `reviewer`. Fix gaps, open the PR.
- **large**: run the `/harness:ship` workflow with the task as its argument. It does the
  medium steps with the retries below built in and returns the PR. Do not plan by hand. Then
  apply Merge.

## Open the PR

Push the branch, then `gh pr create` with the planner's title and `templates/pr.md` filled by
the reviewer. Tick only what was done and delete every unchecked line.

## CI

After the push run `gh pr checks --watch`. On a failure, read the failing log, fix it with one
more slice, push, and watch again. At most 2 fix rounds, then stop and report the failing
check. Never skip, weaken, or delete a check to get green.

## Merge

- **off**: stop at the open PR and say it is ready. The hook blocks `gh pr merge` anyway.
- **on-green**: merge only when the reviewer said `clean` and CI is green.
- **full**: as on-green, and also fix review gaps yourself (2 rounds) before merging.

Merge with `gh pr merge <n> --merge --delete-branch --subject "<PR title> (#<n>)"`. Then switch
to the default branch and pull.

## Done condition

Use this with `/goal` for an unattended run: `PR is open, CI is green, reviewer said clean, or
2 CI fix rounds were used and the failure is reported`.
