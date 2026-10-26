---
description: "Ship a clear task as clean PRs with the saved workflow (autopilot, checkpoint, or adapt). The word continue resumes unfinished work. Asks only for what is missing."
argument-hint: "<task> | continue"
---
# dotagent ship

Usage: `/dotagent:ship <task>`, or `/dotagent <task>` for the same (`/dotagent` alone only shows the saved settings). The task
can carry pasted requirements. With no task, or when the user only says `continue` (any wording), carry on with the unfinished
work, see Start.

- One path for every task. If you can describe the whole diff in one sentence, there is no plan and no TODO: change, run the
  gate, commit, open the PR, merge as below. Otherwise plan, build, and review as below.
- A run goes on by itself until the whole plan is merged or something stops it. It does not wait between PRs.

Read the `[dotagent] workflow=... read-limit=... style=...` line from session start. It comes from the saved settings
(it may end with `protected=...`, `setup=...`, `hooks=...`, `big_plan=...`), and `workflow=autopilot` is the default.
`RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`. If it also says `unfinished`, `docs/TODO.md` holds work
that is not done yet.

If a `[dotagent] first run` line is there, do what it says before anything else:

1. Tell the user in two lines what the workflow does (`autopilot`: each PR merges by itself when the review is clean and CI is
   green, and the run goes on until every PR is merged or a stop) and that `/dotagent:workflow` changes it.
2. Ask once (see Questions): set up first with `/dotagent:setup` (recommended), or go on with only a TODO. Going on means no
   `AGENTS.md`, CI, or PR template are written, the plan still goes to `docs/TODO.md`.
3. Save the answers: `sh "$RUN" set workflow autopilot`, `set setup minimal` for going on. Then do the task.

A task is one or more PRs, each cut from the default branch. Commits are atomic and one
line, `type(scope): summary`. Hooks enforce the format and the names.

## Questions

Ask with AskUserQuestion. If it is missing or errors, load it with ToolSearch (`select:AskUserQuestion`) and retry once. Still missing:
ask in plain text, a numbered list with the recommended option first, one line of reason each, then stop and wait. Headless
(`claude -p`): take the recommended option, say so, go on. Ask only for what is missing, never guess what the plan depends on, and
save each answer that can come back with `sh "$RUN" set` (`setup`, `hooks`, `big_plan`) so it is not asked twice.

## Tools and speed

Prefer harness tools to shell: Grep and Glob to find, Read with offset and limit, independent calls together in one turn. For wide
reading over many files send the `Explore` agent and keep only its summary. Watch CI in the background. Agents cannot start
agents, so only you spawn.

## Style skills

Invoke each skill in `style=` once with the Skill tool before you start (skip `none` and any not installed). They change how you
write replies, not the steps.

## Start

Check the git hooks first: `sh "$RUN" hooks` prints `on`, `off`, or `none`. They check every commit and push
by anyone, which the agent hook cannot, so do not skip this. Skip the question below when the line says `hooks=declined`.

- `off`: the repo ships `.githooks` but git does not use it. Say what is skipped (format, lint, names) and
  ask once with AskUserQuestion to turn them on with `git config core.hooksPath .githooks` (Recommended),
  or to go on without. Never change git config without the answer. Save it: `set hooks on` or `set hooks declined`.
- `none`: the repo has no git hooks. Say once that only the agent hook guards the run, and go on.

Then look at `docs/TODO.md`. A PR is unfinished when it has an unticked subtask or an empty `done:` line.

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

## The plan is read only

Planning never edits code. Do not enter Claude Code plan mode, it would block `docs/TODO.md`.
Use the plan marker instead, a hook enforces it: with the marker on, only `docs/TODO.md` can be
written, a shell command that writes files is refused, and so are `git commit`, `git push`, and `gh pr`.

Plan like this, with `RUN` from Start:

1. `sh "$RUN" phase plan`. Read as little as you can: Grep for symbols, then Read ranges, independent calls together. Treat pasted
   requirements as the source of truth and keep their words.
2. Write `docs/TODO.md` (layout below), replacing any older file.
3. **Ambiguity is never guessed.** Ask the user with AskUserQuestion, at most 4 per call, each with its options, your recommended one
   listed first as `(Recommended)`, and a one line why from a best practice or from what the repo already does. Write each answer
   under `## decisions`. Never plan a subtask that a question blocks. After 3 rounds stop and say what is still open.
4. When the plan is settled, say what `docs/TODO.md` holds in two lines. Stop here if the user said plan only (run
   `sh "$RUN" phase done`). With more than 6 PRs, ask once whether to go on (skip it when the line says `big_plan=ok`) and save `set big_plan ok`.
5. `sh "$RUN" phase build`, then build.
6. At the end, and on every stop or failure, run `sh "$RUN" phase done`.

## The TODO

`docs/TODO.md` is the report and stays out of git, never stage it. You write it fresh per task, tick each subtask as its commit lands,
and write the PR url on `done:` after a merge. Layout:

```
# TODO: the goal in one line
## requirements    (verbatim; with more than one point, number them R1, R2, keep the words)
## decisions       (question: answer, recommended and accepted, or chosen)
## PR 1: type(scope): summary          (this is the PR title)
branch: feat/short-slug
needs: none, or the PR that must merge first
covers: R1, R2                         (only when the requirements are numbered)
files: path/**, other/file.go          (every path the PR may edit, tests included, a hook refuses the rest)
- [ ] 1.1 `type(scope): summary`. What changes, in which files. Verify: format, then the scoped lint and test of the module (see `AGENTS.md`).
- [ ] 1.2 `type(scope): summary`. ...
done:                                  (the PR url, filled when it is merged)
## PR 2: ...
## fixes   ## noticed
```

- One subtask is one commit: one logical change that builds and passes on its own, 1 to 3 files in one module, and the message
  describes exactly those files. New behavior and its tests share a subtask. A refactor is its own subtask, never mixed with a feature.
- With several requirements, every `R` is covered by exactly one PR. An `R` no PR covers goes to the user as a question.
  The reviewer checks the `R` of the PR in hand, and you report which are done.
- Vertical first: one thin path through the stack that works end to end. For work across layers the first PR is the contract (types,
  interfaces). The riskiest piece goes early. Unfinished user facing work sits behind a flag, off by default. Migrations come with a rollback.
- Cross modules only through a module's public interface. Never plan an import the repo's `AGENTS.md` forbids.
- A file that would pass about 500 lines or take on a second responsibility gets its split as its own subtask.
- Touch only what the task needs. Put unrelated problems under `noticed`, do not plan them.
- Two subtasks that change the same file are ordered, never parallel.

## The loop over the PRs

Ship the PRs in order, one after another, without asking in between:

1. Take the first unfinished PR whose `needs` is none or already merged (check with `gh pr view`).
2. Ship it: branch, subtasks, review, open the PR, CI, merge, as below.
3. After the merge, write the url on its `done:` line, switch to the default branch, pull, and go to 1.
4. Say one line per PR as it lands. At the end report what shipped and which `R` are done.

Stop the loop, run `sh "$RUN" phase done`, and report when:

- a fix ran out of tries (a failed subtask, review gaps, or a red CI after two tries),
- a question is left open,
- the workflow is `checkpoint` and the user has not said yes, or the PR cannot merge (a conflict, a required review): leave the PR open and
  say what is needed, then the user says `continue`,
- the next PR `needs` a PR that is not merged.

## Resume

Work out where a PR stopped from git and `gh`, never from memory. In this order, take the first that fits:

1. A merged PR for its branch: write the url on `done:`, move on to the next PR.
2. An open PR: go on at CI (and merge). If checks failed, fix as in Limits.
3. Commits on the branch but no PR: run the reviewer, then open the PR.
4. Unticked subtasks: do them in order, skip the ticked ones, the branch already exists.
5. Nothing yet: start the PR from the default branch.

Whatever the user typed after `continue` is extra guidance, apply it.

## By workflow

- **autopilot** and **checkpoint**: the steps in Merge, one branch and one PR per plan item.
- **adapt**: ask first for what is missing (one round, see Questions), then plan. Work on one branch for the whole TODO
  (`feat/<slug>`), one local commit per subtask, no push, no PR, no CI. Run the reviewer once at the end. Then ask whether to rebase
  and squash onto the default branch locally (recommended) or to leave the branch for the user, and do what they pick.

## Build

- A one sentence diff: no plan, change, run the repo's build, lint, and test, commit, open the PR, merge as below.
- Otherwise follow The plan is read only, then for each PR build each subtask yourself, in order: write a failing test first when it adds
  behavior, make the simplest change that passes, format, then run the scoped checks (the subtask's `Verify:`). Commit with its one line
  message, stage only its files, then tick it in `docs/TODO.md`. Read ranges, not whole files.
- When a file outside the PR's `files:` must change, a hook refuses the edit. Add the path to `files:` only when the task needs it, and
  tell the user when a protected path needs a change.
- Spawn `reviewer` when the subtasks are done. Fix the gaps, then open the PR.

Whatever the size, text the user pastes after the task, such as requirements from product, is
input to the plan. Never summarize it away, keep it verbatim.

## Limits

- A PR is reviewable in one sitting: aim for 3 to 8 subtasks and a few hundred changed lines. It is a
  range, not a limit. A bigger or riskier task becomes more PRs, never one huge PR.
- Subtasks that touch the same file are never parallel, and you build them one at a time.
- Every fix (a failed subtask, review gaps, a red CI) gets two tries from you: fix it, then retry with the full log. Then you stop
  and report. Never loop past that.

## Open the PR

Push the branch, then `gh pr create` with the PR title (a name that says what changed, see Names) and
`.github/PULL_REQUEST_TEMPLATE.md` filled by the reviewer. The body never ends with a "Generated with" line or a
trailer, a hook refuses it. Tick only what was done and delete every unchecked line.

## CI

After the push run `gh pr checks --watch`. On a failure read the failing log, fix it, push, and watch again. Never skip, weaken, or
delete a check to get green.

## Merge

The workflow mode decides who acts:

- **autopilot** (the default): push, open the PR, and merge when the reviewer said `clean` and CI is green. Fix review gaps first.
- **checkpoint**: build and commit locally as in autopilot, but before any push, PR, or merge ask the user in the chat and wait for a
  yes ("yes", "approve", "ya"). After a yes run `sh "$RUN" approve` (it covers one PR), then go on. Without it the hook asks the user itself.
- **adapt**: never push, open a PR, or merge on the remote. See By workflow.

Always rebase first, then squash. The branch sits on the latest default branch, so a stale branch or a conflict shows up on your
side, and the default branch stays linear with one commit per PR. The squash body lists each commit with its hash.

Cloud (autopilot, checkpoint), in this order:

1. `git fetch origin` and `git rebase origin/<default>`. On a conflict fix as in Limits, never `--skip` or `--abort` to hide it.
2. Run the full gate once. Then `git push --force-with-lease`, on your own branch only (the hook refuses `--force`). Wait for CI.
3. Read the PR commits now, after the rebase, because the hashes changed: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
   Also check `.commits[].messageBody` for a `Co-Authored-By`, `Signed-off-by`, or "Generated with" line. If one is there, stop and report:
   GitHub copies such a trailer into the squash commit and it cannot be removed from the default branch afterwards.
4. Merge with the lines pasted into the body as text, never a shell variable (the hook reads the command as typed):
   `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<lines>"`. The body is only those lines,
   `- <short hash> <commit subject>`, oldest first. No prose, no trailer, no tool name.
5. Switch to the default branch, pull, and check `git log -1 --format=%B` has no `Co-authored-by`. If it does, report it, never rewrite the default branch.

Local (adapt): `git rebase <default>`, the full gate once, then on the default branch `git merge --squash <branch>` and one commit,
`git commit -m "<title>"` followed by the hash lines from `git log --reverse --format='- %h %s' <default>..<branch>`. Keep the
branch, so the hashes in the body still resolve.

A commit message and a PR title never carry `(#<n>)`, GitHub adds it. A hook refuses it, and `--merge`, `--rebase`, `--admin`, `--force`,
a body that is not a commit list, and any trailer. The subject's number must be the PR you are merging. Never bypass a required check or a
required review, report it instead. If the repo does not allow squash merging (`gh repo view --json squashMergeAllowed`), stop and say so.

## Receipt and guardrails

- End every run, and every stop, with `sh "$RUN" receipt`, and put its line in your report. It lists the subagents that really
  ran (`subagents: reviewer 1`).
- Before `gh pr create`, run the full gate once (the repo's build, lint, and test). Subtask checks covered only their module.
- A hook refuses an edit outside the PR's `files:` and any path in `protected`. Do not work around either.
- To keep the lead context small on a long plan, the user can run `sh "${CLAUDE_SKILL_DIR}/../../hooks/loop.sh"`: one fresh
  `claude -p` per PR, resumed from `docs/TODO.md`.

## Done condition

For `/goal`: `every PR in docs/TODO.md is merged, or a stop above was reached and reported`.

End every run, and every stop, with one line `next:` that names what the user can do now (`continue`, `/dotagent:workflow`, `/dotagent:setup`, or a new task).
