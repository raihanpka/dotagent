---
name: dotagent-ship
description: "Ship a task that already has clear requirements as small, reviewable PRs: branch, subtasks, checks, one-line commits, PR, squash merge. Use when asked to build, implement, or ship a clear task. Works in any agent that reads .agents/skills."
---

# Ship a task

Plain steps for any agent. Claude Code users get the richer `/dotagent:ship` instead.
Rules that bind every step: commit messages say what changed, never a plan label, no
trailer, no `(#N)`. Never push, open a PR, or merge without the user's yes, unless the
user already set autopilot in `.dotagent/config.json` (Claude Code only).

## 1. Start

- Read `AGENTS.md` at the repo root for the commands and the modules.
- If the task is unclear, ask one question with a recommended answer and the reason. Do not guess.
- Check the default branch: `git symbolic-ref refs/remotes/origin/HEAD`, or ask.

## 2. Plan

- Small change (one sentence describes the whole diff): skip the plan, go to step 3.
- Otherwise write the plan yourself, read only, as a checklist in `docs/TODO.md` (untracked, never commit it). Revise it when the work differs from it.
  One section per PR. Each PR has 3 to 8 subtasks: change, build, lint, test, commit.
- Each subtask leaves the repo green.

## 3. Build

- Branch from the default branch: `git switch -c <type>/<slug>`.
- Do each subtask yourself, one at a time. Run the repo's test command from `AGENTS.md`. It must pass before you commit.
- Commit one atomic change: `git add <explicit paths>`, then `git commit -m "type(scope): summary"`.
  Never `git add -A`. A refactor is its own commit.
- Tick the subtask in `docs/TODO.md`. Go to the next.
- Never edit a protected path or a generated file. Run the generator for generated files.

## 4. Check

- Run build, lint, and test once more on the whole change, once per commit: do not rerun a gate that passed on the same commit, and say in your reply which commit it passed at. Show the output.
- Prove it with a check you ran, never with "looks done".
- Review the diff against the plan in a fresh context: the `reviewer` subagent (`.codex/agents/reviewer.toml`) if you can run subagents,
  otherwise yourself in a fresh pass. Tell it the gate result and what is in scope, and ask for `clean` or numbered gaps with `path:line`.
  Fix gaps before the PR.

## 5. Pull request

- Ask the user for a yes before `git push` and `gh pr create` (the default in dotagent).
- `git push -u origin <branch>`, then `gh pr create` with the title `type(scope): summary`
  and the body from `.github/PULL_REQUEST_TEMPLATE.md`. Tick only what was done. Delete the
  unchecked lines.
- The body has no trailer and no "Generated with" line.

## 6. CI and merge

- Watch CI: `gh pr checks --watch`. On red, read the log, fix with one more commit, push. Never
  skip or weaken a check to get green.
- Ask the user for a yes before the merge.
- Rebase first, then squash, so the default branch stays linear:
  1. `git fetch origin && git rebase origin/<default>`. Resolve conflicts, do not skip them.
  2. Run the gate once. Push with `git push --force-with-lease` only, never `--force`.
  3. Read the commits: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
     Stop if any message body has `Co-Authored-By`, `Signed-off-by`, or "Generated with".
  4. `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<the lines>"`.
     The body is only the `- <hash> <subject>` lines from step 3, oldest first.
- Never use `--admin`, `--merge`, or `--rebase` to merge.

## 7. Stop and report

Stop and report, do not loop, when: a fix failed twice, a question is still open, CI is red
after one fix, or a PR cannot merge. Say what is done, what is left, and what the user must decide.
Never commit `docs/TODO.md`, a planning note, or a benchmark result.
