---
description: "Ship a clear task as clean PRs with the saved workflow (auto, ask, or local). Decides open points itself and asks only when it must. The word continue resumes unfinished work."
argument-hint: "<task> | continue"
---
# dotagent ship

Usage: `/dotagent:ship <task>`, or `/dotagent <task>` for the same. The task can carry pasted requirements. With no task, or when the user only says `continue` (any wording), carry on with the unfinished work, see Start.

- One path for every task. If you can describe the whole diff in one sentence, there is no plan and no TODO: change, run the
  gate, commit, then open the PR and merge as the workflow mode allows. Otherwise plan, build, and review.
- A run goes on by itself until the whole plan is merged or something stops it. It does not wait between PRs, except for the permission prompt that `ask` shows before each push, PR, or merge.
- This file is the core. Read a reference only when you reach that step, so a small task never loads the rest:
  - `${CLAUDE_SKILL_DIR}/references/plan.md` before you plan: the read only plan, the TODO layout, the loop over the PRs.
  - `${CLAUDE_SKILL_DIR}/references/merge.md` before you push, open a PR, or merge: the workflow modes, the PR, CI, the squash.

Read the `[dotagent] workflow=... style=...` line from session start. It comes from the saved settings
(it may end with `protected=...`, `setup=...`, `hooks=...`, `big_plan=...`), and `workflow=auto` applies when nothing is saved. A repo flow that is not the
default adds `merge=`, `types=`, `scope=`, or `base=` to that line: follow them, they come from `/dotagent:setup`.
`RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`. If it also says `unfinished`, `docs/TODO.md` holds work
that is not done yet.

If a `[dotagent] first run` line is there, do what it says before anything else:

1. Tell the user in two lines what the workflow does (`auto`: each PR merges by itself when the review is clean and CI is
   green, and the run goes on until every PR is merged or a stop) and that `/dotagent:workflow` changes it.
2. Ask once (see Questions): set up first with `/dotagent:setup` (recommended), or go on with only a TODO. Going on means no
   `AGENTS.md`, CI, or PR template are written, the plan still goes to `docs/TODO.md`.
3. Save the answers: `sh "$RUN" set workflow auto`, `set setup minimal` for going on. Then do the task.

A task is one or more PRs, each cut from the default branch (the `base=` branch when the line has one). Commits are atomic and one
line, `type(scope): summary`, with the repo's own `types=` and an optional scope when the line says so. Hooks enforce the format and the names.

## Decide

A task with clear requirements runs to the end. Decide open points: pick the option you would defend, write `question: choice, because
reason` under `## decisions` in `docs/TODO.md`, and list it in the final report so the user can redirect it.

Ask only when the answer lives with the user alone (a secret, a product call with no sensible default), when an action cannot be undone
and was not asked for, or when the request is wrong (it breaks a requirement, a repo rule, or a known failure). A wrong request: say in two
lines what is wrong and where, build the best version you would defend, and ask once in the final report if they want their version instead.
That question never pauses the run.

## Questions

Ask with AskUserQuestion, recommended option first. If it is missing or errors, load it with ToolSearch (`select:AskUserQuestion`) and retry
once. Still missing: ask in plain text, numbered, recommended first, one line of reason each, then stop and wait. Headless (`claude -p`): take
the recommended option, say so, go on. Save each answer that can come back with `sh "$RUN" set` (`setup`, `hooks`, `big_plan`).

## Tools and speed

Prefer harness tools to shell: Grep and Glob to find, Read ranges, independent calls together. Send `Explore` for wide reading, keep its summary, and watch CI in the background. Agents cannot start agents, so only you spawn.

## Delegating

Every spawn (`Explore`, `reviewer`) gets three lines:

- **Objective:** one line, what to find or check, for which PR (the base branch, the `covers`).
- **Output:** the shape you want back. `reviewer`: `clean` or a numbered list of gaps with `path:line` and the fix. `Explore`: `path:line` hits only.
- **Boundaries:** read only, the files in scope, and what is already done (for the reviewer, whether `gate check` says `ok`).

## Style skills

Invoke each `style=` skill once with the Skill tool before you start (skip `none` and missing ones). They change replies, not steps.

## Start

Check the git hooks first: `sh "$RUN" hooks` prints `on`, `off`, or `none`. They guard every commit and push, not only the agent's.
Skip the question below when the line says `hooks=declined`.

- `off`: the repo ships `.githooks` but git does not use it. Say what is skipped (format, lint, names) and
  ask once with AskUserQuestion to turn them on with `git config core.hooksPath .githooks` (Recommended),
  or to go on without. Never change git config without the answer. Save it: `set hooks on` or `set hooks declined`.
- `none`: the repo has no git hooks. Say once that only the agent hook guards the run, and go on.

Then look at `docs/TODO.md`, and at `docs/LESSONS.md` when it exists. A PR is unfinished when it has an unticked subtask or an empty `done:` line.

- **Unfinished work and no new task** (`/dotagent:ship` alone, or `continue`): resume it, see Resume.
- **Unfinished work and a new task:** do not start the new one yet. Ask the user once with AskUserQuestion:
  finish the old task first (Recommended, say what is left in one line), or drop it and start the new one.
  Finishing first means resume the old task, then start the new one by itself. Dropping means you write a fresh
  `docs/TODO.md`, and the old one is gone.
- **No unfinished work and a new task:** plan it. **Nothing at all:** say there is nothing to continue and
  ask what to build.

## The team

You lead, in one context: you plan, build every subtask, and fix. The `reviewer` checks each PR in a fresh context, and `Explore`
reads wide. Git, `gh`, and CI are plain commands. Do not hand a subtask to another agent, you already hold what it would need.

## Names

Commit messages, PR titles, and merge subjects say what changed, never where the work sits in the plan (`milestone-1`, `task-2`,
`wip`, "finishing task") and never `(#N)`. A hook refuses the wrong ones.

## Build

- A one sentence diff: no plan. Change, run the repo's build, lint, and test, commit, then open the PR (read `merge.md`).
- Otherwise read `plan.md` first, write the plan, then for each PR build each subtask yourself, in order: write a failing test first
  when it adds behavior, make the simplest change that passes, format, then run the scoped checks (the subtask's `Verify:`). Commit with
  its one line message, stage only its files, then tick it in `docs/TODO.md`.
- The plan is yours to revise: when the work differs or a subtask fails twice, update `docs/TODO.md` first and say in one line what changed.
  A file outside `files:` gets its path added with a reason. Never edit a protected path: tell the user.
- A bug report is a task: reproduce it from the log or the failing test, then fix the root cause, not the symptom.
- After a correction from the user, add one line to `docs/LESSONS.md` (the pattern, then the rule). Never stage it, like `docs/TODO.md`.
- The gate runs once per commit. When the subtasks are done run `sh "$RUN" gate check`. On `stale` run the whole gate with
  `sh "$RUN" gate run <the gate command from AGENTS.md>`, which records the commit when it exits 0. Then spawn `reviewer`
  with the brief from Delegating. Fix the gaps, run the gate again if code changed, then open the PR.

Pasted requirements are the plan's input: keep them verbatim, never summarize.

## Resume

Before any new work run `sh "$RUN" gate check`. On `stale` run the repo's whole gate with `sh "$RUN" gate run <the gate command>`. If it
fails, stop and report, a red base is not a place to start a subtask. On `ok` the gate already passed at this commit, go on.

Work out where a PR stopped from git and `gh`, never from memory. In this order, take the first that fits:

1. A merged PR for its branch: write the url on `done:`, move on to the next PR.
2. An open PR: go on at CI (and merge). If checks failed, fix as in Limits.
3. Commits on the branch but no PR: run the reviewer, then open the PR.
4. Unticked subtasks: do them in order, skip the ticked ones, the branch already exists.
5. Nothing yet: start the PR from the default branch.

Whatever the user typed after `continue` is extra guidance, apply it.

## Limits

- A PR is reviewable in one sitting: aim for 3 to 8 subtasks and a few hundred changed lines. It is a
  range, not a limit. A bigger or riskier task becomes more PRs, never one huge PR.
- Subtasks that touch the same file are never parallel, and you build them one at a time.
- Each fix (a failed subtask, review gaps, a red CI) gets two tries: fix it, retry with the full log, then stop and report.

## Receipt and guardrails

- End every run and every stop with `sh "$RUN" receipt` in the report: the subagents that really ran (`subagents: reviewer 1`).
- Before `gh pr create`, `sh "$RUN" gate check` must say `ok`, and the gate runs once per commit, not once per agent.
- A hook refuses a path in `protected`: do not work around it. A hook refuses an edit outside the PR's `files:`: add the path with a
  reason, then retry.
- For a long plan the user can run `sh "${CLAUDE_SKILL_DIR}/../../hooks/loop.sh"`: one fresh `claude -p` per PR.

## Done condition

For `/goal`: `every PR in docs/TODO.md is merged, or a stop above was reached and reported`.

End every run, and every stop, with one line `next:` that names what the user can do now (`continue`, `/dotagent:workflow`, `/dotagent:setup`, or a new task).
