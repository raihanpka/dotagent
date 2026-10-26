# Measuring the Workflow

The harness is in `benchmark/` and ran once (results below), so a claim like "cheaper" or "faster" has a number behind it.

## What Others Measure

Sources are blog posts and preprints, I did not verify their figures.

- **Resolved rate and cost per task, together.** One study reports the share of tasks resolved on
  SWE-Bench Verified and Terminal-Bench plus mean cost per task ([arXiv 2609.20804](https://arxiv.org/pdf/2609.20804)).
  Artificial Analysis tracks pass@1 over three runs, mean API cost, and wall time ([Artificial Analysis](https://artificialanalysis.ai/agents/coding-agents)).
- **Same model, only the harness changes.** Scaffolding alone is reported to move scores by 10 to 20
  points ([Benchmark Literacy guide](https://codex.danielvaughan.com/2026/06/17/benchmark-literacy-guide-reading-coding-agent-benchmarks-critically/)).
- **Cost moves more than success.** Success changed by a few points while cost varied up to 5x for
  one model ([Digital Applied](https://www.digitalapplied.com/blog/coding-agent-harness-cost-harnesstax-same-model-5x)).
  Output tokens against pass@1 shows the trade ([arXiv 2606.17454](https://arxiv.org/pdf/2606.17454)).
- **Repeat runs.** Use several trials with confidence intervals, and record benchmark version,
  harness, run count, and cache behavior ([Toolhalla](https://toolhalla.ai/blog/coding-agent-benchmark-methodology-deepswe-checklist)).
  pass@k and pass^k agree at k=1 and diverge after, so report which one ([Anthropic, Demystifying evals for AI agents](https://anthropic.com/engineering/demystifying-evals-for-ai-agents)).
- **Your own task set beats a leaderboard.** 20 to 40 tasks from your merged PRs, in a harness such as
  Harbor ([developertoolkit.ai](https://developertoolkit.ai/en/ecosystem/models/benchmarks/)).

## How a skill workflow is usually tested

Common to the sources above and to the skill-creator guides ([Pillitteri](https://pasqualepillitteri.it/en/news/341/claude-code-skills-2-0-evals-benchmarks-guide), [Conduction](https://conduction.nl/academy/claude-skills-tutorial-3-skill-evals), [skill-benchmark](https://www.skills.sh/workersio/skills/skill-benchmark)):

- **With and without.** The same prompt, same model, once with the skill and once without. Compare pass rate, time, and tokens.
- **Deterministic grader first.** A test or a script decides pass or fail. An LLM judge only for what code cannot check.
- **Isolated run.** A fresh copy of the repo per run, so one run cannot leak into the next.
- **Several trials.** A single run is noise. Report the spread, not only the mean.
- **Watch both warning signs.** The skill matches the baseline (it adds little), or it scores below it (too prescriptive).
- **Cost per resolved task**, not cost per task. A configuration that fails early looks cheap ([Braintrust](https://www.braintrust.dev/blog/hf-agent-traces)).
- **Trigger tests.** A skill must also start when it should and stay quiet when it should not.

## What is built

- **App.** `examples/taskboard-backend`, a gin task board with 6 modules and a green `make ci`.
- **Tasks.** Two in `benchmark/tasks/`, each a `prompt.md` and a hidden `bench_test.go` grader that is copied in only after the run. They are the two paths of the single loop:

| Task | Path it tests | Shape |
|---|---|---|
| `t1-board-leak` | a one sentence diff, no plan | a bug fix: one function, find the root cause |
| `t6-members-roles` | plan, subtask commits, gate, reviewer | a feature across several PRs: roles across boards, tasks, and a new module, and it only passes if the `GET /boards` leak is fixed too |

Run 1 used five tasks, `t1` to `t5`. Every arm resolved all of them, so `t2` to `t5` (due dates, pagination, archive, comments) could not separate the arms and were removed, and `t6` was added to force the full path. The grader runs with `-race`.

- **Arms.** `plain` (Claude Code alone) and `dotagent` (`/dotagent:ship <task>`, one loop for every task). Run 1 used the old arms `small`, `medium`, and `large` (`/dotagent:ship <scale>`), which no longer exist, and `report.py` still prints them. Same model for all, `MODEL=sonnet` by default.
- **Run.** `bash benchmark/run.sh <arm> <task> <trial>` copies the app to a temp dir, runs `claude -p` with `--output-format json`, then grades. The dotagent arms load the working tree plugin with `--plugin-dir plugin`.
- **Per run it records:** resolved (hidden test passes), gate green (`make ci`), cost, wall clock, turns, tokens (input, output, cache), commits, bad commit subjects and trailers, changed lines.
- **Report.** `python3 benchmark/report.py` prints, per arm, resolved rate, cost per resolved task, p50 wall clock with its range, and a per task table.
- **Before a run.** `bash benchmark/check-graders.sh` proves every grader fails on the untouched app.

```
for t in benchmark/tasks/*/; do for a in plain dotagent; do for i in 1 2 3; do
  bash benchmark/run.sh $a $(basename $t) $i; done; done; done      # 12 runs, spends real money, cap with BUDGET
python3 benchmark/report.py
```

`bash benchmark/run-all.sh` runs the matrix (`JOBS=4` at once). Try one first: `bash benchmark/run.sh plain t1-board-leak 1`. `report.py` skips a run the API refused (a session limit), so rerun those.

## Results, run 1 (2026-10-21)

Sonnet 5.5 for every arm, 5 tasks x 4 arms x 3 trials = 60 valid runs, about $13.8 in total. Ten runs hit a session limit mid-matrix and were rerun.

| Arm | Resolved | `make ci` green | Cost per run | p50 wall | Output tokens per run | Commits | Changed lines | Trailers |
|---|---|---|---|---|---|---|---|---|
| plain | 15/15 | 15/15 | $0.15 | 43 s | 4.7k | 1 | 154 | 8 |
| small | 15/15 | 15/15 | $0.24 | 66 s | 7.1k | 2 | 171 | 0 |
| medium | 15/15 | 15/15 | $0.27 | 77 s | 13.6k | 2 | 197 | 0 |
| large | 15/15 | 15/15 | $0.26 | 75 s | 11.1k | 2 | 195 | 0 |

What it says, and no more:

- **No arm resolved more.** All 60 runs passed the hidden test and the gate. These 5 tasks are too easy to separate the arms, so there is no evidence yet that planning or review raises the resolved rate.
- **The workflow costs more here.** About 1.6x to 1.8x the cost and 1.5x to 1.8x the wall clock of plain Claude Code. `medium` and `large` cost the same, and `small` is a little cheaper than both.
- **Hygiene is where it differs.** Plain Claude Code added a `Co-Authored-By` trailer in 8 of 15 runs, which the repo forbids. No dotagent run did, and every commit subject matched `type(scope): summary`.
- **Outlier.** One `medium` run on `t5-comments` took 1257 s for $0.43, so the p50 is the number to read, not the mean.
- **Decide.** By the rule below, no planner, reviewer, or worker rule has earned its cost on these tasks. That is a reason to run harder tasks, not to remove them yet: the point of the workflow is larger, riskier work than a one endpoint change.

Next run: tasks that need several PRs, an ambiguous requirement, or a bug with a non obvious cause, and the same arms.

Run 1 measured the old design, a planner and a worker per subtask. It is the reason the workflow became one loop for every task: the lead plans only when the diff is more than one sentence, builds it, and a fresh reviewer checks it. Run 2 below measured the single loop, and it did not get faster than plain.

## Results, run 2, the single loop (2026-10-26)

Sonnet 5.5 for every arm, only the two kept tasks, `dotagent` 5 runs and `plain` 1 run on `t6`, about $2.6 in total. The `plain` and old arm numbers for `t1` are run 1's.

| Task | Arm | Resolved | Gate | Cost p50 | Wall p50 | Commits |
|---|---|---|---|---|---|---|
| `t1-board-leak` | plain (run 1, n=3) | 3/3 | 3/3 | $0.11 | 27 s | 1 |
| `t1-board-leak` | old `medium` (run 1, n=3) | 3/3 | 3/3 | $0.20 | 47 s | 1 |
| `t1-board-leak` | `dotagent` (n=3) | 3/3 | 3/3 | $0.19 | 70 s | 1 |
| `t6-members-roles` | plain (n=1) | 1/1 | 1/1 | $0.24 | 74 s | 1 |
| `t6-members-roles` | `dotagent` (n=2) | 2/2 | 2/2 | $0.44 | 183 s | 3 |

What it says, and no more:

- **It works end to end.** Every run resolved and passed the gate, and the run's `subagent_stats` show one subagent only, `dotagent:reviewer`, no planner and no worker. No bad commit subject, no trailer.
- **It is not faster or cheaper than plain Claude Code.** About 2.6x the wall clock on `t1` and 2.5x on `t6`, and 1.8x the cost. That is the same ratio as run 1, so the single loop did not close the gap.
- **Against the old design, `t1` got no faster.** Cost is the same ($0.19 against $0.20), wall clock is slower (70 s against 47 s, each a median of 3 and the old `medium` has a 101 s outlier). A one sentence diff has no plan, so the extra time is the skill and its references being read, the gate, the reviewer, and the hook on each call.
- **What it buys is the shape of the result.** `t6` came out as three atomic commits with the leak fixed and a clean review, `plain` as one commit.
- **Too few runs.** One or two runs per cell, so a cell can move a lot (`t1` ranged from 66 to 83 s). There is no old design number for `t6`, because the old arms are gone.

Next, before trusting the single loop for speed: skip the reviewer for a one sentence diff and run `t1` again, and run `t6` three times per arm.

## Limits to keep in mind

- The work copy has no GitHub remote, so the dotagent arms stop after the review and local commits. PR, CI, and merge time and cost are not measured.
- `total_cost_usd` from `claude -p` should include subagents. Confirm that on the first run, the reviewer is the one subagent left.
- `--setting-sources project,local` keeps your user plugins out of the run, but the plain arm still has the machine's login and model defaults.
- Two tasks show a direction. A claim needs more tasks from real merged PRs.

## Decide

Keep a rule (the plan, the reviewer, the gate record) only if it raises resolved rate or cuts cost per resolved task. Otherwise remove it.
