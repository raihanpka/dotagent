# bench

A way to measure what dotagent changes on a real feature, not on a toy prompt.

## what it does

`run.sh` takes a case, copies the case's small repo into a throwaway folder, and gives the same
task to Claude under three conditions:

| Condition | What the agent has |
|---|---|
| `baseline` | the repo's own `AGENTS.md` (commands, modules, rules of this repo) and plain Claude |
| `rules` | that file plus dotagent's generic rules as plain text, no plugin |
| `plugin` | the same file plus the dotagent plugin at `scale=medium`: hooks, planner, Haiku slicers, reviewer |

`rules` against `plugin` isolates what the plugin adds over the same written rules. `baseline`
against `rules` shows what the written rules alone buy.

## what it measures

| Column | Meaning |
|---|---|
| `acceptance` | hidden behavior checks the agent never saw, passed per run (`9/9` is all) |
| `coupling_violations` | breaks of the repo's coupling rules, counted by `coupling.py` |
| `commits`, `scoped`, `oneline`, `small_commits` | how many commits, how many are `type(scope): summary`, single line with no trailer, and touch 4 files or fewer |
| `longest_py` | the longest source file, as a cohesion signal |
| `wall_s`, `cost_usd` | time and money per run, averaged |

Speed and cost are reported but are not the point. dotagent adds steps (a plan, a review), so it
is slower and dearer on a small task. What it should buy is the left side of the table:
correct behavior, clean commits, and no new coupling.

## run it

```bash
bash bench/run.sh                       # the recurring-tasks case, 2 runs per condition
bash bench/run.sh recurring-tasks 3     # 3 runs per condition
```

It needs `claude`, `jq`, and `python3`. It spends real tokens, roughly $0.2 to $0.8 a run, and runs
with permissions bypassed, so it only ever touches the copy under `bench/results/<case>/work-*`.
Raw JSON per run and `rows.jsonl` land in `bench/results/`, which git ignores.

## add a case

A case is a folder under `bench/cases/` with:

```
<case>/
├── README.md          # the real situation the case stands for
├── task.md            # the task as a person would paste it, requirements included
├── repo/              # a small repo with its own AGENTS.md and passing tests
├── acceptance.py      # hidden checks, run from the repo root, prints "acceptance N/M"
└── coupling.py        # counts breaks of the repo's coupling rules, prints JSON with "violations"
```

Check a new case by writing the solution yourself in a scratch copy: `acceptance.py` must reach
M/M, and `coupling.py` must flag a deliberately coupled variant.

## results

See [`RESULTS.md`](RESULTS.md) for the last run and what it does not show.
