---
name: dotagent-ship
description: "Ship a task that already has clear requirements as one verified loop: a checkable finish, small units, a real-artifact proof, a fresh review, a stop reason, fan-out, and a production watch. Works in any agent that reads .agents/skills."
argument-hint: "<task> | continue"
---
# dotagent ship

Usage: invoke this skill with a task, or with `continue`. With no task, or when the user only says `continue` (any wording), resume from
state. The task can carry pasted requirements.

- One path for every task. If the whole diff fits one sentence there is no plan: change, verify, commit, open the PR.
- A run is a loop, not a line: **goal -> plan -> one unit -> verify -> prove -> review -> ship -> next unit -> finish**. A failed check
  goes back to the unit. Two tries on one hypothesis, then a pivot.
- A stop is a feature: every stop names one reason, writes it down, and ends with a `next:` line. Never retry the same unit silently.
`SKILL` is the folder that holds this file. `RUN` is `.dotagent/run.sh` from the repo root. If it is missing, run the setup step once.

- Read a reference only when you reach that step, so a small task never loads the rest:
  - `$SKILL/references/loop.md` before the first unit: the loop, the stop table, the context budget, how to decide.
  - `$SKILL/references/verify.md` before a behavior change: the proof ladder, the feature map, formal verification.
  - `$SKILL/references/plan.md` before you plan: the read-only plan and the TODO layout.
  - `$SKILL/references/merge.md` before you push, open a PR, or merge.
  - `$SKILL/references/fanout.md` before a wide verification, a competing design, or an adversarial pass: swarm, arena, interrogate, panel.
  - `$SKILL/references/production.md` before a PR with a `release:`, `watch:`, or `rollback:` line.

Read the `[dotagent] ...` line from session start. It carries `workflow=`, `phase=`, `stop=`, `stalled=`, `next=`, and when the repo differs
from the default also `merge=`, `types=`, `scope=`, `base=`, and `protected=`. Follow them, they come from the setup step.
If the line says `unfinished`, `docs/TODO.md` holds work that is not done yet.

A `[dotagent] first run` line means no config yet:

1. Tell the user in two lines what `auto` does (each PR merges when the review is clean and CI is green, until the finish predicate passes
   or a stop) and that the workflow setting changes it.
2. Ask once (see Questions): set up first with the setup step (recommended), or go on with only a TODO. Going on writes no
   `AGENTS.md`, CI, or PR template.
3. Save the answer: `sh "$RUN" set setup minimal` for going on. Then do the task.

A task with clear requirements runs to the end. Decide reversible points yourself: pick the option you would defend, write `question: choice,
because reason` under `## decisions` in `docs/TODO.md`, and report it. Ask only when the answer lives with the user alone, the action cannot
be undone, or the requirement contradicts itself or the repo. A wrong requirement: say in two lines what is wrong and where, build the best
version, and ask once in the final report. A stop is not a question: stop only when the next unit cannot start. `loop.md` has the line.

## Questions

Ask with the harness's question tool, recommended option first. If it has none, ask in plain text, numbered, recommended first, one reason
each, then wait. Headless: take the recommended option, say so, go on. Save each answer that can come back with `sh "$RUN" set`.

## Delegating

Every spawn (`Explore`, `reviewer`) gets three lines:

- **Objective:** one line, what to find or check, for which PR (the base branch, the `covers`).
- **Output:** the shape you want back. `reviewer`: `clean` or a numbered list of gaps with `path:line` and the fix. `Explore`: `path:line` hits only.
- **Boundaries:** read only, the files in scope, and what is already done (for the reviewer, whether `gate check` says `ok`).

A spawn gets a pointer, not the payload. Prefer Grep and Glob, Read ranges, and independent calls. If the harness can spawn subagents, use
them; otherwise do a fresh pass. Invoke each `style=` skill once before you start.

## Start

Run `sh "$RUN" state` first. It prints `run=`, `reason=`, `phase=`, `left=`, `head=`, `progress=`, `stalled=`, and `next=`. Read the top of
`docs/TODO.md`, `git log -1`, and the TODO's `## stopped` block. Never resume from memory.

Check the git hooks: `sh "$RUN" hooks` prints `on`, `off`, or `none`. On `off`, say what is skipped and ask once to enable them; `loop.md`
has the command.

Then look at `docs/TODO.md`, and at `docs/LESSONS.md` when it exists. A PR is unfinished when it has an unticked subtask or an empty `done:` line.

- **Unfinished work and no new task** (this skill alone, or `continue`): run `sh "$RUN" start continue`, then resume.
- **Unfinished work and a new task:** do not start the new one yet. Ask once: finish the old task first (Recommended, say what is left in one
  line), or drop it and start the new one.
- **No unfinished work and a new task:** `sh "$RUN" start "<the goal in one line>"`, then plan it.
- **Nothing at all:** say there is nothing to continue and ask what to build.

## The loop

The unit is the atom. One unit is one commit, one scoped `Verify:`, one tick, one row in `## log`, one `sh "$RUN" progress <unit>`.

1. Take the next unticked subtask from the first unfinished PR.
2. Change only its files, then run its `Verify:`. A behavior change also runs its `prove:` or the closest real-artifact check.
3. Commit one atomic change, tick the subtask, append one `## log` row with the commit and the evidence pointer.
4. Run `sh "$RUN" progress <unit>`. It prints `moved` or `same`.
5. If `same`, pivot: log the new hypothesis and try a different approach. Four `same` rows in a row means `stop no-progress`.

The loop runs until the `finish:` predicate passes, the PR merges, or a stop fires. It does not wait between units.

## Stop

Read `loop.md` for the table and the procedure. Every stop runs `sh "$RUN" stop <reason> "<one line>"`, writes the `## stopped` block and a
`## log` row, and ends with a `next:` line. A failed `watch:` after the merge is a `regression` stop. Never stop silently, retry the same
unit, or turn a stop into a question.

## The team

You lead, in one context: you plan, build every subtask, and fix. The `reviewer` checks each PR in a fresh context, and `Explore`
reads wide. Git, `gh`, and CI are plain commands. Do not hand a subtask to another agent, you already hold what it would need.

## Build

- A one sentence diff: no plan. Change, run the scoped check and the proof, commit, then open the PR (read `merge.md`). A behavior change
  runs its `prove:` before the PR; a green gate alone is not proof. `verify.md` has the ladder, the feature map, and formal verification.
- Names say what changed, never a plan label like `milestone-1`, `task-2`, or `wip`, and never `(#N)`. A hook refuses the wrong ones.
- Otherwise read `plan.md` first, write the plan, then build each subtask yourself, in order: write a failing test first when it adds
  behavior, make the simplest change that passes, format, then run the subtask's `Verify:`.
- Commit one line, stage only its files, tick it in the TODO. Revise the plan first and say what changed. A file outside `files:` needs its
  path and a reason.
- A bug report is a task: reproduce it from the log or the failing test, then fix the root cause, not the symptom. `verify.md` says how.
- After a correction from the user, add one line to `docs/LESSONS.md` (the pattern, then the rule). Never stage it, like `docs/TODO.md`.
- Never write a new markdown file, a summary doc, or a planning note the task did not ask for. `docs/TODO.md` is the only scratch.
  A comment explains why, never what the next line does.
- When the subtasks are done run `sh "$RUN" gate check`. On `stale` run `sh "$RUN" gate run <the gate command from AGENTS.md>`,
  which records the commit when it exits 0. Then spawn `reviewer` with the brief from Delegating. Fix the gaps, rerun the gate if code
  changed, then open the PR.

## Resume

Run `sh "$RUN" state` first. `run=stopped` means read `## stopped` and `next:`, then `sh "$RUN" start continue`. `stalled=yes` means the
last two units moved nothing: do not repeat them, pick the smallest next experiment or stop.

Before any new work run `sh "$RUN" gate check`. On `stale` run the repo's whole gate with `sh "$RUN" gate run <the gate command>`. If it
fails, stop with `red-base` and report, a red base is not a place to start a subtask. On `ok` the gate already passed at this commit.

Work out where a PR stopped from git and `gh`, never from memory. In this order, take the first that fits: a merged PR for its branch (write
the url on `done:`), an open PR (go on at CI), commits but no PR (review, then open it), unticked subtasks (do them in order), or nothing
(start the PR from the default branch). Whatever the user typed after `continue` is extra guidance.

## Limits

- Aim for 3 to 8 subtasks and a few hundred changed lines per PR. It is a range, not a limit. A bigger task becomes more PRs.
- Subtasks that touch the same file are never parallel, and you build them one at a time.
- A failed check gets two tries on one hypothesis. A different hypothesis gets its own two tries. A repeated premise stops `premise`.

## Receipt and guardrails

- End every run and every stop with `sh "$RUN" receipt` in the report: the subagents that really ran (`subagents: reviewer 1`).
- Before `gh pr create`, `sh "$RUN" gate check` must say `ok`, and the gate runs once per commit, not once per agent.
- A hook refuses a path in `protected`: do not work around it. A hook refuses an edit outside the PR's `files:`: add the path with a
  reason, then retry. For a long plan, use the harness's loop command or run one fresh process per PR.

The run's finish: `the finish predicate in docs/TODO.md passes, or the run stopped with a reason and reported it`. End every run, and every
stop, with one line `next:` that names what the user can do now (`continue`, the workflow setting, the setup step, or a new task).
