# Plan, the TODO, and the loop over the PRs

Read this when the diff is more than one sentence. `RUN` is defined in `SKILL.md`.

## The plan is read only

Planning never edits code. Do not enter Claude Code plan mode, it would block `docs/TODO.md`. Use the plan phase instead,
`sh "$RUN" phase plan`, and a hook enforces it: while the phase is `plan`, only `docs/TODO.md` can be written, a shell command that writes
files is refused, and so are `git commit`, `git push`, and `gh pr`.

Plan like this:

1. `sh "$RUN" phase plan`. Read as little as you can: Grep for symbols, then Read ranges, independent calls together. Treat pasted
   requirements as the source of truth and keep their words.
2. Write `docs/TODO.md` (layout below), replacing any older file. State the finish predicate and the proof for each PR before you plan subtasks.
3. **Open points are decided, not guessed.** Follow the decide rule in `SKILL.md`: pick the option you would defend, write it under
   `## decisions` with its reason, and ask only when that rule says to. Never plan a subtask that a missing answer blocks.
4. When the plan is settled, say what `docs/TODO.md` holds in two lines. Stop here if the user said plan only (run `sh "$RUN" phase done`).
5. `sh "$RUN" phase build`, then build. At the end, and on every stop or failure, run `sh "$RUN" phase done`.

If a requirement cannot be checked, turn it into one that can before you plan. "The list is faster" becomes "the p95 for 1000 items is
under 50 ms on the same workload". A plan with no checkable finish is not a plan yet.

## The TODO

`docs/TODO.md` is the report and the state. It stays out of git, never stage it. You write it fresh per task, tick each subtask as its
commit lands, and write the PR url on `done:` after a merge. Layout:

```
# TODO: the goal in one line
goal: what this run is for, in one line
finish: a command or artifact that can pass or fail
budget: optional, for example 8 units or 2h
base: the branch the PRs target

## requirements
(the user's words, verbatim. More than one point: number them R1, R2, keep the words.)

## decisions
(question: choice, because reason. A wrong request also notes what was built instead.)

## log
| when | unit | decision | evidence | result |
|---|---|---|---|---|
| 2026-01-01T10:00Z | 1.1 | added the owner filter in the query | commit 1a2b3c4, `internal/boards/store.go:88` | done |
| 2026-01-01T10:20Z | 1.2 | tried a handler guard, did not change the result | 5d6e7f8 | reverted |

## PR 1: type(scope): summary          (this is the PR title)
branch: feat/short-slug
needs: none, or the PR that must merge first
covers: R1, R2                         (only when the requirements are numbered)
files: path/**, other/file.go          (every path the PR may edit, tests included, a hook refuses the rest)
prove: the real-artifact check, not the gate
- [ ] 1.1 `type(scope): summary`. What changes, in which files. Verify: format, then the scoped lint and test.
- [ ] 1.2 `type(scope): summary`. What changes. Verify: the command and the proof.
done:                                  (the PR url, filled when it is merged)

## PR 2: ...

## stopped
reason: one of the reasons in loop.md
what: one line
next: one concrete action
```

- One subtask is one commit: one logical change that builds and passes on its own, 1 to 3 files in one module. New behavior and its
  tests share a subtask. A refactor is its own subtask, never mixed with a feature.
- `finish:` is the run predicate. Do not mark `done` because the TODO is empty. Run the predicate.
- `prove:` is required for a behavior change. `verify.md` has the ladder and the feature map.
- With several requirements, every `R` is covered by exactly one PR. An `R` no PR covers goes to the user as a question.
- Vertical first: one thin path through the stack that works end to end. For work across layers the first PR is the contract (types,
  interfaces). The riskiest piece goes early. Unfinished user facing work sits behind a flag, off by default.
- Cross modules only through a module's public interface. Never plan an import the repo's `AGENTS.md` forbids.
- A file that would pass about 500 lines or take on a second responsibility gets its split as its own subtask.
- Touch only what the task needs. Put unrelated problems under `noticed`, do not plan them.
- Two subtasks that change the same file are ordered, never parallel.

## The loop over the PRs

Ship the PRs in order, one after another, one unit at a time (in `ask`, the permission prompt for each push, PR, and merge is the only pause):

1. Take the first unfinished PR whose `needs` is none or already merged (check with `gh pr view`).
2. Ship it: branch, subtasks, verify, prove, review, open the PR, CI, merge, as in `merge.md`.
3. After the merge, write the url on its `done:` line, switch to the default branch, pull, and go to 1.
4. After each unit run `sh "$RUN" progress <unit>`, and after each PR write the log rows. Say one line per PR as it lands.
5. At the end run the `finish:` predicate. Passing is `stop done`. Failing is not done, even with every PR merged.

Stop the loop with the reason from `loop.md`, write `## stopped`, and report when:

- a fix ran out of tries (a failed subtask, review gaps, or a red CI after two tries),
- a stop reason fires,
- a push, PR, or merge is refused (a permission prompt answered no, or no user to answer it), or the PR cannot merge,
- the next PR `needs` a PR that is not merged.
