# Fan out: swarm, arena, interrogate, panel

Read this when a task is wide, risky, or hard to prove. The lead still owns the plan, the merge, and the final answer. A fan-out is
read-only unless the harness can isolate a writer, and an agent in the fan-out never merges.

## When to fan out

- **Wide and independent:** three or more modules, packages, feature-map entries, or files that do not depend on each other.
- **Hard to prove:** a race, a state machine, a parser, a protocol, a security boundary, or a property that tests rarely reach.
- **A design fork:** two or more plausible designs and no precedent.
- **A diff you do not trust:** a small change with a blast radius across three or more callers.

Do not fan out when the diff fits one sentence, the slices touch the same file, or the work is sequential. A one-sentence change is one
lead and one check.

## Swarm: verify slices in parallel

One agent per slice, one aggregated report.

- Slice by module, package, feature-map entry, or declared race arm. Each slice has one owner and one check.
- An agent is read-only unless the harness gives it its own worktree or branch. Never let two writers share a tree.
- Each agent returns exactly one verdict: `PASS`, `ISSUES`, or `BLOCKED`, with a `path:line` and the command it ran for every issue.
- The lead merges the reports into one list, drops duplicates, and keeps only findings with a reproducible check. A raw dump is not a report.
- An agent that cannot run its check returns `BLOCKED`, not `PASS`.

## Arena: compare attempts

Two or three attempts at the same brief, then one decision.

- Give every attempt the same brief, the same predicate, and the same boundaries.
- Isolate each attempt in its own worktree or branch. When the harness cannot isolate, run them sequentially and say so.
- Compare against the predicate, not against taste. Pick one base, graft only the parts that beat it, and record the decision and the
  rejected parts in `## log`.
- Arena is for a fork worth the cost. A settled design does not need another attempt.

## Interrogate: try to break the diff

Adversarial review with fresh eyes.

- Spawn two or more reviewers on the diff, each with a different focus: correctness, concurrency, security, data loss, compatibility, or
  the one fact the change depends on.
- When the harness can pin a model, use a different model family for at least one seat. When it cannot, say so and use a fresh context.
- Keep only a finding you can reproduce or point at with `path:line` and a failing check. Dismiss noise with a one-line reason, and record
  what was dismissed.
- The author does not grade its own work. The lead applies the smallest fix and reruns the affected checks.

## Panel: settle a judgment call

A panel is for a design or verification judgment that a single pass may miss.

- Two or three perspectives, one round. A panel is not a vote and not a debate.
- Give every seat the same brief and the same evidence. Ask for a recommendation and the reason, not a summary of the diff.
- The lead decides, records the decision and the losing option, and moves on.

## The brief every agent gets

- **Objective:** one line, the slice or question, and the predicate it must answer.
- **Output:** `PASS`, `ISSUES`, or `BLOCKED`, with `path:line`, the command, and the evidence pointer. No prose dump.
- **Boundaries:** read-only unless a worktree is provided, the files in scope, and what is already done.
- **Evidence:** a check the agent ran, not a claim. A finding without a repro is a hypothesis.

## Aggregation and stop

- One report, no raw logs. Group by slice, then by severity.
- A `BLOCKED` slice is not a `PASS`. Name the missing tool or access.
- Stop `error` when the harness cannot run the fan-out at all. Stop `no-progress` when the slices do not move the predicate.
- Keep the fan-out cheap. If the work is small, the lead does it alone.
