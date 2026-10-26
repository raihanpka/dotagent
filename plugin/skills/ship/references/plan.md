# Plan, the TODO, and the loop over the PRs

Read this when the diff is more than one sentence. `RUN` is defined in `SKILL.md`.

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
- the workflow is `ask` and the user has not said yes, or the PR cannot merge (a conflict, a required review): leave the PR open and
  say what is needed, then the user says `continue`,
- the next PR `needs` a PR that is not merged.
