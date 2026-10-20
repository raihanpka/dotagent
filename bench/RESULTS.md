# Results

Case `recurring-tasks`, Sonnet, 2 runs per condition, each run a fresh process in its own folder
with no saved session and no auto memory. Raw JSON stays in `bench/results/` (git ignored).

| | baseline | rules | plugin |
|---|---|---|---|
| acceptance (hidden, 9 checks) | 9/9, 9/9 | 9/9, 9/9 | 9/9, 9/9 |
| coupling violations | 0 | 0 | 0 |
| commits per run | 3 | 3 | 5 |
| `type(scope): summary`, one line | 6 of 6 | 6 of 6 | 10 of 10 |
| commits touching 4 files or fewer | 5 of 6 | 4 of 6 | 8 of 10 |
| subagents spawned per run | 0 | 0 | 7 |
| share of cost on Haiku | 0% | 0% | 9% |
| wall time | 54 s | 125 s | 227 s |
| cost | $0.135 | $0.131 | $0.268 |

## What this shows

- On this case Sonnet with the repo's own `AGENTS.md` already gets every behavior check and keeps
  the coupling rules. The plugin does not make the result more correct here. The case is too easy
  to separate the conditions on correctness.
- The runs are not identical. The plugin run spawned 7 subagents (planner, slicers on Haiku,
  reviewer), made 5 atomic commits instead of 3, and cost twice as much and took about four times
  as long. That is the price of the plan and review steps on a task this small.
- The repo's `AGENTS.md` already states the commit format, so the format rows do not separate the
  conditions either. The hooks matter when an agent ignores written rules, and these runs did not.

## What it does not show

- Two runs per condition is noise, not a trend. Do not read the time or cost gap as precise.
- Only `scale=medium` ran here. The `large` workflow (`ship-large.js`) needs the Workflow tool, which a
  headless `claude -p` run did not have, so its escalation ladder is covered by tests against a
  fake agent only.
- No PR or CI step ran, the repo has no GitHub remote.
- A harder case is the next step: one where the natural solution couples modules or breaks an
  existing behavior, so that correctness and coupling can separate the conditions.
