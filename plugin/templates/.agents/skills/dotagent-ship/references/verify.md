# Verification: prove the real thing

Read this before a behavior change, a bug fix, or a PR. Verification is the step that lets the agent trust its own work, so the human
does not have to check every result by hand. A green build is not a green feature.

## The ladder

Use the strongest rung the change earns. A lower rung never proves a higher one.

1. **Static.** Format, lint, types, build. It proves the code is well formed, nothing more.
2. **Scoped test.** The subtask `Verify:` command. It proves the cases someone wrote.
3. **Runtime proof.** Drive the real artifact: the command, the HTTP route, the running UI, the stored value, the file on disk. This is
   the rung that proves the behavior a user gets.
4. **Formal.** A property over every state or input in a stated scope, when tests rarely reach the case that breaks it.
5. **CI.** The same checks on a clean machine, from the PR gate. It proves the result does not depend on the local machine.

The trust order, from the reference talk: a good codebase, then static analysis, then verification, then prose, then human review.
Prose is cheap to write and easy to drift. Put the rule in a check where you can.

| Check | Proves | Does not prove |
|---|---|---|
| The gate | it compiles, the lint holds, the unit cases pass | the behavior a user gets, or that the work ran |
| The `prove:` | the change does the thing on the real artifact | it holds on every machine, or under production traffic |
| CI | the same checks run on a clean machine | the behavior beyond the cases the checks reach |

A gate-only result is not a behavior verdict. A proof-only result is not a clean-machine guarantee. Use both, and add a formal or
production check when the change earns it.

## What proves it, by field

| Field or change | Real proof | Formal or production check when |
|---|---|---|
| Backend API or service | a real request, the response, and the stored value read back | concurrent or retried writes, auth, money |
| Frontend or web UI | walk the changed flow in the running app, screenshot or video, keyboard and screen-reader path | a state machine in the UI, a race in the client |
| CLI or TUI | the real command, its stdout, stderr, and exit code | a parser or a state machine in the command |
| Library or SDK | a small example that imports the public API and uses the result | an invariant over every input |
| Mobile app | the app on a device or simulator, the changed screen, the log | offline, sync, or a lifecycle race |
| Desktop app | launch, drive the changed flow, read the log and the stored state | IPC or a file-lock race |
| Embedded or firmware | the device or a faithful simulator, timing, memory, the bus trace | a timing or concurrency invariant |
| Data pipeline or ML | replay a saved input, compare the output and the metric, check the drift | a property over all records or a model invariant |
| Database or migration | forward and backward migration, a fixture replay, the row read back | a lock, a backfill, or an idempotent retry |
| Infrastructure or IaC | plan or dry run, apply in staging, the drift check | a failover or a partial-apply state |
| Concurrency or distributed | a stress or fault-injection run, the trace | TLA+ for interleavings, a model checker |
| Security or auth | a threat-model check, an authz matrix, a secret scan, a penetration test | a protocol or a permission invariant |
| Performance | before and after on the same workload, the limiter, the run count | a bound or a complexity proof |
| Refactor | characterization tests, the observable behavior unchanged | a property that must survive the reshape |
| Docs | link check, render, run every example | nothing formal; verify the examples |
| Config or CI | the pipeline dry run, the same commands locally | a rollout or a secret-handling path |
| Dependency upgrade | lockfile diff, full gate, smoke test, the changelog | a security advisory or a breaking API |
| Data change | before and after counts, a sample read, an idempotent rerun | a uniqueness or ordering invariant |

When a field has no runtime surface, use the closest executable check. When there is none, say `inconclusive` and say what is missing.
Never invent a proof for a domain the repo cannot run.

## Blast radius

A small diff can break something far away. Before you trust it, find the one fact the change is safe because of and prove it by running
code, not by writing a paragraph.

1. Name the fact. "This call only drops already-dead cache entries and does nothing else" is a fact. "It should be fine" is not.
2. Get it as far down this list as is cheap: you said so, a `file:line`, the bad case cannot happen, a script or test calls the real code,
   or the running app reproduces it. Step 4 is usually a small script that imports the same library the app ships.
3. Look where grep stops: the library source and its pinned version, the wire format, a database column, another language reading the same
   bytes, a feature flag, code three hops downstream.
4. Keep the risks you confirmed, list the ones you cleared, and paste the proof for the one that matters.

If you cannot prove the fact, say `unproven` and stop `question`.

## A measured number

Before you report a speedup or a regression, answer these from a run, not from the code:

- What limits the number? Name the profile or counter, and why not double.
- Was every side tuned the way production runs it?
- Did the arithmetic break a physical limit?
- Did it error, skip work, or read a cache? Confirm the work ran inside the timed region.
- Does it reproduce over alternating runs? Report the median and range, and call a gap under the spread no difference.
- Does it matter end to end, on the path a user waits on?

The verdict is faster, slower, no measurable difference, or inconclusive. One run is a ballpark, not a verdict.

## The feature map

A runtime proof needs to know what the app does and how a user reaches it. When the repo has no map, add one to the PR `prove:` or as a
short table in `docs/VERIFICATION.md`:

| Feature | How a user reaches it | What proves it works |
|---|---|---|
| List boards | `GET /api/v1/boards` with a token | The response holds only the caller's boards, not another user's |
| Add a task | `POST /api/v1/boards/:id/tasks` | The task is in the store and the response carries its id |

The three columns are the whole idea: what exists, how a user reaches it, and what observable end state proves it. Drive the user path,
not a test-only setter. Capture the action and the resulting state, not only the final screen. Check side effects (rows, files, messages)
alongside what is visible.

| Change | Real proof |
|---|---|
| CLI | Run the real command, show its output and exit code |
| HTTP or service | A real request, the response, and the read-back state |
| UI | Walk the changed flow in the running app, screenshot or video |
| Parser or migration | Replay a saved input and compare |
| Performance | Before and after on the same workload, with the limiter named |
| Storage | Read back the written value |

## Formal verification

Tests check the cases someone thought to write. Formal verification checks every case in a stated scope: every order of steps in a model,
every input up to a bound, or every input. Reach for it when the code has concurrency, retries, locks, a state machine, a parser, a
protocol, money, or auth, and a bug is costly and hard to reproduce.

Pick the tool from the question, not from fashion:

- **Order of events** usually suits a model checker. TLA+ is the default for a small model of the design, in any language.
- **The code itself for every input**, such as memory safety, an overflow, or a data-structure invariant, usually suits a verifier that
  runs on the code (SMT-backed or a language verifier).
- **A property that must hold at every size**, where a bound is not enough, can need a proof assistant such as Lean or Coq.
- **No verifier runs on the language:** say so and test the real code with generated inputs. Never hand-model the function and call it proof.

Keep one property, stated in one sentence with the harm:

```
Property: a job is never leased to two processes at once.
Harm: two processes write the same record and the last one wins silently.
Scope: the lease and retry path, for every interleaving of acquire, renew, expire, and release.
```

Rules:

- **Able to fail.** Show the check failing on a broken variant (a removed guard, a reordered step) before you trust a pass. A check you
  have never seen fail proves nothing.
- **True to the code.** Each step in the model points to code a reviewer can open. One indivisible step in the code is one step in the model.
- **Findings stay findings.** If the current code breaks the property, report the counterexample in the code's words. Do not weaken the
  property or the model to get a pass, and do not change product code unless the user asks.
- **Honest about scope.** A pass covers the model or the bound, not the whole system. Say what is left out.
- **Cheap to rerun.** One command, a pinned tool version, a run short enough that the next agent uses it.
- **Kept in step.** Record the code each check covers and the commit where it last matched. A pass on a stale model is worse than no check.

Record it in `docs/VERIFICATION.md`:

```
Property: a job is never leased twice at once.
Tool: TLA+ (TLC, 2 processes, 3 jobs)
Covers: internal/jobs/lease.go, internal/jobs/retry.go
Command: make verify-lease
Sync: <commit sha>
```

## Bug fixes

Reproduce first. A failing test, a recorded command, or a log line that shows the wrong state. Then trace to the first place the system
went wrong and fix it there, not where the symptom surfaced. Rerun the repro after the fix. If the repro is impractical, use the closest
executable check and say why the test path was skipped. Never weaken or delete a test to make a fix pass.

## Evidence

Evidence is a pointer, not a paragraph: a commit sha, a `path:line`, a command and its output, a screenshot path, a trace, a counterexample
as a short sequence of steps. Put it in the `## log` row and the report. If a check could not run, say `inconclusive`. A confident claim
without evidence is a warning sign, not a result.

## What does not count

- "It compiles", "the tests should pass", "looks done".
- A green gate as the only proof of a behavior change.
- A screenshot of a test runner instead of the feature.
- A skipped, deleted, or loosened test.
- A number with no baseline, no run count, and no named limiter.
- A formal pass on a model that no longer matches the code.
