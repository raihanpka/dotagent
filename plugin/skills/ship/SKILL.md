---
description: Ship a clear task as clean PRs, all the way to merge. Minimalist agent swarm workflow.
argument-hint: "[small|medium|large] <task>"
---
# dotagent ship

Usage: `/dotagent:ship [small|medium|large] <task>`, or `/dotagent <task>` for the same with the saved
settings (`/dotagent` alone only shows the scale, like `/dotagent:scale`). The task can carry pasted requirements.
With no task, or when the user only says `continue` (any wording), carry on with the unfinished work, see Start.

- A first word of `small`, `medium`, or `large` sets the scale for this run only. Strip it from the task.
- With no scale word, use `scale=` from the session line (saved with `/dotagent:scale`, `medium` by default).
- `small`: no plan, for a tiny change. `medium`: plan, one worker per subtask, review. `large`: the
  same steps run by the `ship-large` workflow, which enforces the limits in code.
- A run goes on by itself until the whole plan is merged or something stops it. It does not wait between PRs.

Read the `[dotagent] scale=... merge=... read-limit=... style=...` line from session start (it may end with `protected=...`).
If a `[dotagent] first run` line is there, do what it says before anything else: tell the user the scale (medium unless they gave
one) and why, that each PR merges by itself when the review is clean and CI is green and the run goes on until every PR is
merged or a stop, and how to change it. Then save both with `sh "$RUN" set scale <scale>` and `set merge on-green` and go straight to
the task. Do not ask. It comes from
`.dotagent/config.json`, and `merge=on-green` is the default. If it also says `unfinished`, `docs/TODO.md`
holds work that is not done yet.
A task is one or more PRs, each cut from the default branch. Commits are atomic and one
line, `type(scope): summary`. Hooks enforce the format and the names.

## Tools and speed

Use the harness tools, they are faster than shell: Grep and Glob to find, Read with offset and limit to read, and
several independent calls in one turn. For a big repo, send the `Explore` agent first for a wide read and give the
planner its summary as `context`. Run `gh pr checks --watch` in the background and carry on, or watch it with Monitor.
Agents cannot start agents, so only you (the lead) spawn.

## Style skills

`style=` lists skills such as `caveman` or `ponytail:lite`. Invoke each once with the Skill tool
before you start. Skip `none` or a skill that is not installed. They change how you write replies,
not the steps below.

## Start

Check the git hooks first: `sh "$RUN" hooks` prints `on`, `off`, or `none`. They check every commit and push
by anyone, which the agent hook cannot, so do not skip this. `RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`.

- `off`: the repo ships `.githooks` but git does not use it. Say what is skipped (format, lint, names) and
  ask once with AskUserQuestion to turn them on with `git config core.hooksPath .githooks` (Recommended),
  or to go on without. Never change git config without the answer.
- `none`: the repo has no git hooks. Say once that only the agent hook guards the run, and go on.

Then look at `docs/TODO.md`. A PR is unfinished when it has an unticked subtask or an empty `done:` line.

- **Unfinished work and no new task** (`/dotagent:ship` alone, or `continue`): resume it, see Resume.
- **Unfinished work and a new task:** do not start the new one yet. Ask the user once with AskUserQuestion:
  finish the old task first (Recommended, say what is left in one line), or drop it and start the new one.
  Finishing first means resume the old task, then start the new one by itself. Dropping means the planner
  writes a fresh `docs/TODO.md`, and the old one is gone.
- **No unfinished work and a new task:** plan it. **Nothing at all:** say there is nothing to continue and
  ask what to build.

## The team

A task becomes one or more PRs, a PR becomes subtasks. Sonnet leads: the `planner` plans and the
`reviewer` checks each PR in a fresh context. A swarm of `worker` agents on Haiku does the building,
one agent per subtask, one at a time because they share one git index. Fixed steps (git, `gh`, CI)
are plain commands, not agents.

## Names

A commit message, PR title, and merge subject say what changed, never where the work sits in the plan
(`milestone-1`, `task-2`, `slice 3`, `step 4`, `phase`, `wip`, "finishing task"), and never `(#N)`.
`feat(auth): add the login route` is right. A hook refuses the wrong ones, so write the right one first.

## The plan is read only

Planning never edits code. Do not enter Claude Code plan mode, it would block `docs/TODO.md`.
Use the plan marker instead, a hook enforces it: with the marker on, only `docs/TODO.md` can be
written, a shell command that writes files is refused, and so are `git commit`, `git push`, and `gh pr`.

Start every non-`small` plan like this, with `RUN` from Start:

1. `sh "$RUN" phase plan`, then spawn `planner` with the task and the pasted requirements.
2. The planner writes `docs/TODO.md`: one section per PR, each with its subtasks.
3. **Ambiguity is never guessed.** If the planner returns `questions`, ask the user with
   AskUserQuestion, at most 4 per call, each with its options, the planner's `recommended` one
   listed first as `(Recommended)`, and its `why`. Then call the planner again with the answers as
   `decisions`. Repeat until it returns none. After 3 rounds stop and say what is still open.
4. When the plan is settled, say what `docs/TODO.md` holds in two lines. Stop here if the user said
   plan only (run `sh "$RUN" phase done`). With more than 6 PRs, ask once whether to go on.
5. `sh "$RUN" phase build`, then build.
6. At the end, and on every stop or failure, run `sh "$RUN" phase done`.

## The TODO

`docs/TODO.md` is the report. The planner writes it fresh for each task, so the last task's file
is gone, and it stays out of git (setup adds it to `.gitignore`). Each worker ticks its own subtask
when it finishes it. When a PR is merged, write its url on its `done:` line. Read it to see progress.
Never stage or commit it. It is a scratch file, so the truth about what is merged is git and `gh`.

With more than one requirement, the planner numbers them `R1`, `R2` and gives each PR a `covers:` line, so
no requirement is lost between PRs. An `R` that no PR covers comes back as a question. The reviewer checks the
`R` of the PR in hand only. When you report a finished PR, say which `R` are done and which remain.

## The loop over the PRs

Ship the PRs in order, one after another, without asking in between:

1. Take the first unfinished PR whose `needs` is none or already merged (check with `gh pr view`).
2. Ship it: branch, subtasks, review, open the PR, CI, merge, as below.
3. After the merge, write the url on its `done:` line, switch to the default branch, pull, and go to 1.
4. Say one line per PR as it lands. At the end report what shipped and which `R` are done.

Stop the loop, run `sh "$RUN" phase done`, and report when:

- a fix ladder ran out (a failed subtask, review gaps, or a red CI after one Haiku and one Sonnet try),
- the planner or the user left a question open,
- the merge level is `off`, or the PR cannot merge (a conflict, a required review): leave the PR open and
  say what is needed, then the user says `continue`,
- the next PR `needs` a PR that is not merged.

## Resume

Work out where a PR stopped from git and `gh`, never from memory. In this order, take the first that fits:

1. A merged PR for its branch: write the url on `done:`, move on to the next PR.
2. An open PR: go on at CI (and merge). If checks failed, use the fix ladder.
3. Commits on the branch but no PR: run the reviewer, then open the PR.
4. Unticked subtasks: do them in order, skip the ticked ones, the branch already exists.
5. Nothing yet: start the PR from the default branch.

Whatever the user typed after `continue` is extra guidance, apply it.

## By scale

- **small**: no plan, no TODO. Change, run build, lint, test, commit, open the PR, merge as below.
- **medium**: if you can describe the whole diff in one sentence, treat it as `small` and say so.
  Otherwise follow The plan is read only, then for each PR spawn one `worker` per subtask, in
  order, and wait for each commit before the next. Give each its subtask line. Two subtasks in one
  module may go to one `worker`. Spawn `reviewer`. Fix gaps, open the PR.
- **large**: run the `ship-large` workflow with the Workflow tool, once per PR. If that tool is not
  in your tool list (headless runs, older Claude Code), say so in one line and do the medium steps.
  Pass the user's words as the argument `{ task, context, decisions, planOnly, resume, run }`:
  `task` is one line of what to build, `context` is any pasted requirements verbatim, `decisions`
  is the user's answers so far, `planOnly` is true when the user said plan only, `resume` is true
  when the plan already exists in `docs/TODO.md`, and `run` is `RUN` above. The workflow plans read
  only, builds one PR, reviews it, and returns the PR and `prsLeft`, then apply Merge and the loop
  over the PRs, calling it again with `resume`. If it returns `stopped: questions`, ask the user as in
  step 3, then run the workflow again with the same arguments plus `decisions` and the `base` and
  `branch` it returned. On any other `stopped`, report it and run `sh "$RUN" phase done`.

Whatever the scale, text the user pastes after the task, such as requirements from product, is
input to the plan. Never summarize it away, pass it on verbatim.

## Limits

- A PR is reviewable in one sitting: aim for 3 to 8 subtasks and a few hundred changed lines. It is a
  range, not a limit. A bigger or riskier task becomes more PRs, never one huge PR.
- One worker runs at a time. Subtasks that touch the same file are never parallel.
- Every fix (a failed subtask, review gaps, a red CI) gets one try from a Haiku worker, then one
  try from a Sonnet worker with the full context, then you stop and report. Never loop past that.

## Open the PR

Push the branch, then `gh pr create` with the planner's title (a name that says what changed, see Names) and
`.github/PULL_REQUEST_TEMPLATE.md` filled by the reviewer. The body never ends with a "Generated with" line or a
trailer, a hook refuses it. Tick only what was done and delete every unchecked line.

## CI

After the push run `gh pr checks --watch`. On a failure read the failing log, fix it with one
more subtask, push, and watch again. Never skip, weaken, or delete a check to get green.

## Merge

- **on-green** (the default): merge only when the reviewer said `clean` and CI is green.
- **full**: as on-green, and also fix review gaps yourself before merging.
- **off**: stop at the open PR and say it is ready. The hook blocks `gh pr merge` anyway.

Merge with a squash, always: one commit on the default branch per PR. The atomic commits stay traceable
because the squash body lists each one with its hash. Do it in this order:

1. Read the PR commits: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
   Also check `gh pr view <n> --json commits -q '.commits[].messageBody'` shows no `Co-Authored-By`,
   `Signed-off-by`, or "Generated with" line. If one is there, stop and report: do not merge, because
   GitHub copies such a trailer into the squash commit and it cannot be removed from the default branch
   afterwards.
2. Merge with the lines from step 1 pasted into the body, as text, never as a shell variable (the hook reads
   the command as typed): `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<lines>"`.
   The subject ends with this PR's number. The body is only those lines, `- <short hash> <commit subject>`,
   one per commit, oldest first. No prose, no trailer, no tool name.
3. Switch to the default branch, pull, and check `git log -1 --format=%B` has no `Co-authored-by`. If it
   does, report it to the user, never rewrite the default branch.

A commit message and a PR title never carry `(#<n>)`, GitHub adds it. A hook refuses it, and `--merge`,
`--rebase`, `--admin`, a body that is not a commit list, and any trailer. The subject's number must be
the PR you are merging. Never bypass a required check or a required review to merge, report it instead.
If the repo does not allow squash merging (`gh repo view --json squashMergeAllowed`), stop and say so.

## Receipt and guardrails

- End every run, and every stop, with `sh "$RUN" receipt`, and put its line in your report. It lists the subagents that really
  ran (`subagents: planner 1, worker 4, reviewer 1`). A plan with subtasks and no `worker` means you built it yourself: say so.
- Before `gh pr create`, run the full gate once (the repo's build, lint, and test). Workers checked only their module.
- A hook refuses an edit outside the PR's `files:` and any path in `protected`. Do not work around either: add the path to `files:`
  only when the task needs it, and tell the user when a protected path needs a change.
- To keep the lead context small on a long plan, the user can run `sh "${CLAUDE_SKILL_DIR}/../../hooks/loop.sh"`: one fresh
  `claude -p` per PR, resumed from `docs/TODO.md`.

## Done condition

For `/goal`: `every PR in docs/TODO.md is merged, or a stop above was reached and reported`.
