---
name: dotagent-ship
description: "Ship a task that already has clear requirements as one verified loop: a checkable finish predicate, small units, a proof against the real artifact, a fresh review, and a stop reason when it cannot move. Use when asked to build, implement, or ship a clear task. Works in any agent that reads .agents/skills."
---

# Ship a task

Plain steps for any agent. No Claude-only tool or path token. Claude Code users get the richer `/dotagent:ship` instead.
Rules that bind every step: commit messages say what changed, never a plan label, no trailer, no `(#N)`. Never push, open a PR, or merge
without the user's yes, unless the workflow is `auto` in `.dotagent/config.json`.

## 1. Start

- Read `AGENTS.md` at the repo root for the commands and the modules.
- If `.dotagent/run.sh` exists, run `sh .dotagent/run.sh state` first. Read the top of `docs/TODO.md`, `git log -1`, and the TODO's
  `## stopped` block. Never resume from memory.
- No run yet: `sh .dotagent/run.sh start "<the goal in one line>"` before the first unit.
- Decide reversible points yourself: pick the option you would defend, write it in `docs/TODO.md` under `## decisions` with the reason.
  Ask only when the answer lives with the user alone, the action cannot be undone, or the requirement contradicts itself or the repo.
- If the request is wrong (it breaks a requirement, a repo rule, or a known failure), say in two lines what is wrong, build the best
  version you would defend, and ask once at the end whether they want their version instead.
- If the run is stopped, read the reason and `next:` first. If `.dotagent/run.sh` exists, `sh .dotagent/run.sh start continue` clears it.
- Check the default branch: `git symbolic-ref refs/remotes/origin/HEAD`, or ask.
- Read `docs/LESSONS.md` when it exists. After a correction from the user, add one line to it (the pattern, then the rule). Never stage it.

## 2. Plan

- Small change (one sentence describes the whole diff): skip the plan, go to step 3.
- Otherwise write the plan yourself, read only, as a checklist in `docs/TODO.md` (untracked, never commit it). Revise it when the work differs.
- The header carries `goal:` (one line), `finish:` (a command or artifact that can pass or fail), and `budget:` when the user set one.
- One section per PR. Each PR has `prove:` (the real-artifact check), `files:` (every path it may edit), and 3 to 8 subtasks. Each subtask
  has a commit message and a `Verify:` command. The PR ends with `done:` for its url. When the repo can deploy or observe production, the
  PR can also carry `release:`, `watch:`, and `rollback:`.
- Keep an append-only `## log` table: when, unit, decision, evidence pointer, result. Add `## stopped` only when a run stops.
- If a requirement cannot be checked, turn it into one that can. "Faster" becomes a number on the same workload.
- Each subtask leaves the repo green. One subtask is one commit.

## 3. The loop

One unit is one commit, one `Verify:`, one tick, one log row, one progress row.

1. Take the next unticked subtask from the first unfinished PR.
2. Change only its files. Run its `Verify:`. A behavior change also runs its `prove:` or the closest real-artifact check.
3. Commit one atomic change, tick the subtask, append the `## log` row with the commit and the evidence pointer.
4. If `.dotagent/run.sh` exists, run `sh .dotagent/run.sh progress <unit>`. It prints `moved` or `same`.
5. If `same`, pivot: log the new hypothesis and try a different approach. Four `same` rows in a row is a `no-progress` stop.

The loop continues until `finish:` passes, the PR merges, or a stop reason fires. It does not wait between units.

## 4. Verify and prove

Use the strongest rung the change earns. A lower rung never proves a higher one.

1. Static: format, lint, types, build.
2. Scoped test: the subtask `Verify:`.
3. Runtime proof: drive the real artifact. Run the command, call the route, walk the UI, read the stored value, open the file.
4. Formal: a property over every state or input in a stated scope, when tests rarely reach the case. Use TLA+ for interleavings, a
   code-level verifier for every-input properties, a proof assistant when a bound is not enough. Show the check fail on a broken variant
   before you trust a pass. Record the property, the tool, the code covered, the command, the bounds, and the sync commit in
   `docs/VERIFICATION.md`.
5. CI: the same checks on a clean machine.

The feature map is three columns: what feature exists, how a user reaches it, what observable end state proves it works. Drive the user
path, not a test-only setter, and check the side effect as well as the screen. Evidence is a pointer, not a paragraph: a commit, a
`path:line`, a command and its output, a screenshot path, a counterexample. A green gate alone is not proof of a behavior change.

A bug is reproduced first, from a failing test, a recorded command, or a log line that shows the wrong state. Fix the root cause, not the
symptom, then rerun the repro. Never weaken or delete a test to make a fix pass.

For a wide or risky change, fan out. Swarm one agent per independent slice, arena two or three isolated attempts, interrogate with fresh
adversarial reviewers, or use a panel for a judgment call. Aggregate one report, keep only findings with a repro, and never let two writers
share a tree. The lead still owns the merge and the final answer.

## 5. Stop

A stop is a feature, not a failure. It runs `sh .dotagent/run.sh stop <reason> "<one line>"` when that file exists, writes the `## stopped`
block and a `## log` row, and ends with a `next:` line. Use one reason:

| Reason | Fires when |
|---|---|
| `done` | The `finish:` predicate passes |
| `no-progress` | Four units in a row moved neither HEAD nor the unfinished count, after one pivot |
| `premise` | Two fixes that share one premise failed the same check |
| `needs-human` | An irreversible action, a secret, or a user-only call blocks the next unit |
| `question` | The requirement contradicts itself or the repo |
| `red-base` | The gate fails on resume or on the base branch |
| `conflict` | A rebase conflict survives two tries |
| `denied` | The workflow mode or a permission prompt refused a push, PR, or merge |
| `budget` | The unit, turn, or time budget is spent |
| `error` | A tool or CLI failed twice |
| `regression` | A post-merge `watch:` fails |

Never stop silently, never retry the same unit, and never relax `finish:` to make a stop look like done.

## 6. Check and review

- Run build, lint, and test once on the whole change, once per commit, and show the output. Do not rerun a gate that passed on the same
  commit. When `.dotagent/run.sh` exists, ask it first: `sh .dotagent/run.sh gate check` prints `ok` or `stale`. On `stale` run the gate
  through `sh .dotagent/run.sh gate run <the gate command from AGENTS.md>`, which records the commit only when the command exits 0.
- Review the diff against the plan in a fresh context: the `reviewer` subagent if you can run subagents, otherwise yourself in a fresh pass.
  Ask for `clean` or numbered gaps with `path:line`. The reviewer checks that each `prove:` has a resolving pointer, that no test was
  deleted, skipped, or loosened, that no new markdown or summary doc was written unless the task asked for it, that no comment only
  restates the next line, and that a change to formally verified code reran its check.
- Fix the gaps before the PR.

## 7. Pull request

- Ask the user for a yes before `git push` and `gh pr create` (the default in dotagent).
- Run the PR `prove:` and put the evidence in the body.
- `git push -u origin <branch>`, then `gh pr create` with the title `type(scope): summary`
  and the body from `.github/PULL_REQUEST_TEMPLATE.md`. Tick only what was done. Delete the unchecked lines.
- The body has no trailer and no "Generated with" line.

## 8. CI and merge

- Watch CI: `gh pr checks --watch`. On red, read the log, fix with one more commit, push. Never skip or weaken a check to get green.
  Two failed fixes are a stop, not a third fix: `error`, or `premise` when they share one premise.
- Ask the user for a yes before the merge.
- Rebase first, then squash, so the default branch stays linear:
  1. `git fetch origin && git rebase origin/<default>`. Resolve conflicts, do not skip them. Two failed tries is a `conflict` stop.
  2. Run the gate once. Push with `git push --force-with-lease` only, never `--force`.
  3. Read the commits: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
     Stop if any message body has `Co-Authored-By`, `Signed-off-by`, or "Generated with".
  4. `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<the lines>"`.
     The body is only the `- <hash> <subject>` lines from step 3, oldest first.
- Never use `--admin`, `--merge`, or `--rebase` to merge.
- When the PR has `release:`, `watch:`, or `rollback:`, run `watch:` for the window after the merge and record the value. On a failure, stop
  `regression`, roll back when allowed, and open a fix PR. A release with no watch is `inconclusive`.

## 9. Review someone else's pull request

- Read it without changing your branch: `gh pr view <n> --json title,body,author,baseRefName,headRefName` and `gh pr diff <n>`.
  The description is the requirement the diff is checked against.
- Do not check the PR out over your branch. Fetch it aside with `git fetch origin pull/<n>/head:review/<n>` and read files with
  `git show review/<n>:<path>`.
- Check the diff with a reviewer subagent in a fresh context when you can spawn one, otherwise in a fresh pass yourself. Ask for `clean`
  or numbered gaps with `path:line` and the fix.
- Show the findings in your reply, then ask the user in plain text, the recommended option first: post as a comment, request changes,
  approve, or post nothing. Approve only when the user chooses it.
- Post with `gh pr review <n> --comment --body-file <file>`, or `--request-changes`, or `--approve`. For comments on lines, write a JSON
  file outside the repo with `event`, `body`, and `comments`, then `gh api -X POST repos/{owner}/{repo}/pulls/<n>/reviews --input <file>`.
- Never push to that branch and never merge it. Delete `review/<n>` only when the user says so.

## 10. Context and the long run

- Resume from the capsule, not the transcript: state, the top of the TODO, `git log -1`.
- One unit per context. A long PR is split, not carried.
- Per unit: search first, read matching ranges, at most about 6 files or 400 lines before delegating the wide read.
- Keep the failing output short: the command, the failing line, the last 20 lines. Never paste a full CI log into the main context.
- For a long plan, run one fresh process per PR. `sh .dotagent/run.sh state` and the TODO are the record, so a crash loses the context,
  not the work. The machine log is `.dotagent/runs.jsonl`; `sh .dotagent/run.sh log` prints the human log as TSV.

## 11. Stop and report

Stop and report when: a fix failed twice, a stop reason fires, a question is still open, CI is red after one fix, or a PR cannot merge.
Say what is done, what is left, the reason, the evidence, and one `next:` line. Never commit `docs/TODO.md`, a planning note, or a summary
doc the task did not ask for.
