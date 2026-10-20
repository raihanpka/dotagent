# Measuring the Workflow

Not run yet. This is the plan, so a claim like "cheaper" or "faster" has a number behind it.

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

## Plan for dotagent

1. **Tasks.** 5 merged PRs from one repo, each with its requirement text and its tests as the grader.
2. **Arms.** Same model for all: plain Claude Code, `/dotagent:ship small`, `medium`, `large`.
3. **Per run, record:** resolved (tests pass), CI green, tokens in and out, cost, wall clock,
   worker runs, review gaps found, PR size in changed lines.
4. **Repeat** each task 3 times. Report resolved rate, cost per resolved task, and p50 wall clock
   per arm, with the spread.
5. **Decide.** Keep a rule (planner, reviewer, one worker per subtask) only if it raises resolved rate
   or cuts cost per resolved task. Otherwise remove it.
