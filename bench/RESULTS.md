# Benchmark results

One tiny task: add `slugify` with a unit test and commit, in a throwaway Python repo.
Sonnet, headless, 3 runs per condition, `--setting-sources project` so only the plugin differs.
Run it yourself with `bash bench/run.sh 3`. It spends real tokens.

| | baseline | harness (`scale=small`) | change |
|---|---|---|---|
| wall time | 17.7 s | 19.0 s | +1.3 s (+7%) |
| API time | 10.6 s | 11.9 s | +1.3 s |
| turns | 3.7 | 3.7 | same |
| cost | $0.055 | $0.060 | +9% |
| output tokens | 718 | 747 | +4% |
| cache write tokens | 10.2k | 11.4k | +1.1k |
| cache read tokens | 67.8k | 70.8k | +3k |
| task done (tests, behavior, 1 new commit) | 3 of 3 | 3 of 3 | same |
| commit message | free form, 3 of 3 | `feat: add slugify`, 3 of 3 | style enforced |

`hooks/guard.py` costs about 20 ms per call. It runs before each Bash, Write, Edit, and Read.

## Read this before trusting the numbers

- Three runs is noisy. Wall time ranged 16 to 21 s for the harness and 16 to 19 s for the baseline.
- Only `scale=small` was measured. The plugin adds about 1.1k cache write tokens of context.
  The medium and large paths (planner, slicer, reviewer) were not measured.
- `workflows/ship.js` was not run. The Workflow tool was not available in a headless session
  here, so the per agent `model` option and the full plan, PR, and CI loop are untested.
- The benchmark repo has no remote, so the PR and CI steps were never exercised.
