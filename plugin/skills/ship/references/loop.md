# The loop, the stop reasons, and the context budget

Read this when a run starts and when a unit fails. `RUN` is defined in `SKILL.md`.

## The circle

```
                 finish predicate (goal)
                          |
                          v
   plan -> unit -> verify -> prove -> review -> ship -> progress
             ^       |                  |
             |       +---- issues ------+
             |                          |
             +---- one different try ---+---- same twice ---> stop
```

One turn of the circle:

1. **State.** `sh "$RUN" state`. Take the next unticked subtask of the first unfinished PR, or start the next PR.
2. **Change.** The smallest diff that satisfies the subtask, only the paths in `files:`.
3. **Verify.** Run the subtask `Verify:`. A behavior change also runs the PR `prove:` or the closest real-artifact check from `verify.md`.
4. **Record.** Commit one atomic change, tick the subtask, append one `## log` row with the commit and the evidence pointer.
5. **Progress.** `sh "$RUN" progress <unit>`. It prints `moved` or `same`.
6. **Decide.** `moved` goes to the next unit. `same` gets one different approach. `same` twice in a row is `stop no-progress`.

The loop is the default. Nothing waits between units. The only pauses are the permission prompt in `ask`, a stop, and the user.

## Progress and stalls

A unit made progress when either of these changed since the previous `progress` row:

- HEAD moved (a new commit), or
- the unfinished count dropped (a subtask was ticked, a PR merged).

`progress` records the HEAD, the unfinished count, and whether either moved. `state` counts the consecutive `same` rows at the tail and
prints `stalled=yes` at two. A stall is not a signal to try harder on the same idea. It is a signal to change the idea or stop.

## The stop table

| Reason | Fires when | What the report says |
|---|---|---|
| `done` | The `finish:` predicate passes | What shipped, the evidence, the PR urls |
| `no-progress` | Two units moved neither HEAD nor the unfinished count | The last unit, what was tried, the smallest next experiment |
| `premise` | Two fixes that share one premise failed the same check | The premise in one sentence, the observation that would settle it |
| `needs-human` | An irreversible action, a secret, or a user-only product call blocks the next unit | One question, recommended option first |
| `question` | The requirement contradicts itself or the repo | The contradiction, the two options, the safer default |
| `red-base` | The gate fails on resume or on the base branch | The failing command and the first failing line |
| `conflict` | A rebase conflict survives two tries | The files, what each side wants |
| `denied` | The workflow mode or a permission prompt refused a push, PR, or merge | The command, the mode, how to unblock |
| `budget` | The unit, turn, or time budget is spent | Done, left, and the next unit |
| `error` | A tool or CLI failed twice | The exact command and the log line |

Two or more failed fixes that share a premise are a `premise` stop, not another fix. Write the premise down and test it directly. Do not
start the next fix before the premise is written and tested.

## The stop procedure

Do all four, in this order:

1. `sh "$RUN" stop <reason> "<one line>"`.
2. In `docs/TODO.md`, write or replace the `## stopped` block:

```
## stopped
reason: no-progress
what: the list endpoint test still returns every user's boards after two fixes
next: check whether the query is built in the store or the handler, then fix that one place
```

3. Append one `## log` row: the decision, the evidence, and `result: stopped`.
4. Report with the goal, what is done, what is left, the reason, and one `next:` line.

A later `continue` runs `sh "$RUN" start continue`, which clears the stop. The `## stopped` block stays until the next task replaces the TODO,
so the next context can read why the last one stopped.

## The auto loop

`sh loop.sh [max]` is the unattended form. It runs one fresh `claude -p` per PR, so the lead never carries the whole plan.

- Before each process it reads `state`. `run=stopped` exits with the reason. `stalled=yes` records `stop no-progress` and exits.
- After each process it compares HEAD and the unfinished count. If neither moved, it records `stop no-progress` and exits.
- `CLAUDE_FLAGS` can add a cap, for example `CLAUDE_FLAGS="--max-turns 40"` or `CLAUDE_FLAGS="--max-budget-usd 5"`. Check the flags with
  `claude --help` before you document them.
- Every exit prints a `next:` line.

The loop is safe to rerun. `state`, `docs/TODO.md`, git, and `gh` are the record, so a crash loses the context, not the work.

## Deciding vs stopping

A reversible point is decided, not asked. Pick the option you would defend, write `question: choice, because reason` under `## decisions`
in `docs/TODO.md`, and report it. A wrong requirement is built the best way you would defend, with two lines on what is wrong, and one
question at the end. That question never pauses the run.

A stop happens only when the next unit cannot start without the answer: a secret, a product call with no sensible default, an irreversible
action, or a requirement that contradicts itself or the repo. Name it `needs-human` or `question`. Never guess on a one-way door.

## The context budget

Context overflow degrades reasoning, creates compression artifacts, and stops progress. Guard it on purpose:

- Resume from the capsule, not the transcript: `state`, the top 20 lines of the TODO, `git log -1`.
- One unit per context. After a PR, start a fresh process with `loop.sh`.
- Per unit: Grep first, read matching ranges, at most about 6 files or 400 lines before handing wide reading to `Explore`.
- `Explore` returns `path:line` and a summary, never raw files.
- Keep the failing output short: the command, the failing line, the last 20 lines. Never paste a full CI log into the main context.
- A spawn gets a pointer to the files, not the files inlined.
- Prefer Grep and Glob to find, Read ranges, and independent calls together. Invoke each `style=` skill once before the run; it changes
  the reply, not the steps.

If the conversation is compacted, the hook reprints the capsule. Read it before any new work.

## What a stop is not

- Not a failure to announce. It is the loop keeping its promise: it either advances or ends with a reason.
- Not a question in the middle of the run. A reversible decision is decided and logged. A stop happens only when the next unit cannot start.
- Not a relaxation of the finish predicate. Never edit `finish:` to make a stop look like done.
