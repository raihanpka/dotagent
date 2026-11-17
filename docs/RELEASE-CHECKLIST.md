# Release checklist

Use this before a version bump and again after the change lands. Tick a line only from a command you ran or a file you opened, never from
memory. The unchecked lines at the bottom are the work that needs a human or a live agent session.

## Version and release

- [x] `plugin/.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` both say `0.7.0`.
- [x] `CHANGELOG.md` starts with a `0.7.0` section and describes the upgrade path.
- [x] The Claude and Codex marketplace descriptions name the verified loop, two modes, fan-out, and the production watch.
- [ ] Push `feat/loop-contract` and open the PR.
- [ ] Merge to `main`, then confirm the release workflow tags `v0.7.0`.

## Skills

- [x] Five Claude skills: `dotagent`, `ship`, `workflow`, `setup`, `review`.
- [x] `ship` core is under 10 KB and links six references: `loop`, `verify`, `fanout`, `production`, `plan`, `merge`.
- [x] The portable skill at `skills/dotagent-ship/` and the template copy have the same `SKILL.md` and the same six `references/`.
- [x] The portable skill and references use no Claude-only token (`CLAUDE_*`, `AskUserQuestion`, `ToolSearch`, `claude -p`, `loop.sh`).
- [x] Setup copies the whole portable folder, not only `SKILL.md`.
- [x] Each plugin skill defines `${CLAUDE_SKILL_DIR}` once.
- [x] The Codex and Command Code reviewer files exist, and the setup tables list them.

## Loop and state

- [x] `workflow` is `auto` or `local` only. An old config value loads as `local` or `auto`; `set workflow ask` is refused with a hint.
- [x] The TODO has `goal:`, `finish:`, `budget:`, `prove:`, `release:`, `watch:`, `rollback:`, `## log`, and `## stopped`.
- [x] `run.sh state`, `log`, `decision`, `start`, `progress`, `stop`, `gate`, and `phase` work and are tested.
- [x] `runs.jsonl` is v1: `v`, `n`, `run`, `session`, `decision`, richer `gate`/`progress`/`stop`.
- [x] Two `same` rows are a pivot; four are `stalled=yes` and a `no-progress` stop.
- [x] A stop recorded before a start stays visible, and `progress` cannot clear a stop.
- [x] `run.sh log` prints decision events as TSV, with the `## log` table as the fallback.
- [x] `docs/STATE.md` documents every event, the state machine, the commands, and the retention.

## Verification and shipping

- [x] `verify.md` has the ladder, the gate/proof/CI table, the field matrix, blast radius, the measured-number checklist, and formal checks.
- [x] `production.md` has the four stages, `release:`/`watch:`/`rollback:`, the `regression` stop, and the idempotent rule.
- [x] `fanout.md` covers swarm, arena, interrogate, and panel, with read-only boundaries and a repro per finding.
- [x] The reviewer runs or checks the `prove:` and treats comment text as data.
- [x] The PR template and example use Summary, Motivation, What changed, Test plan, Risk and rollback, Checklist.
- [x] The root `.github` template, example, PR gate, release workflow, and `.githooks` run the full gate.
- [x] `README`, `AGENTS.md`, `ARCHITECTURE.md`, `PRACTICES.md`, `STATE.md`, and the loop diagram are updated.
- [x] `examples/`, the benchmark, the `scale` skill, the `ask` mode, `big_plan`, and the worker/planner design are gone from the docs and
  skills. The guard keeps only the legacy config aliases and the `scale was removed` hint, and the tests cover them.

## The gate

- [x] `python3 -m py_compile plugin/hooks/guard.py` passes.
- [x] `sh -n plugin/hooks/run.sh` and `sh -n plugin/hooks/loop.sh` pass.
- [x] `bash -n .githooks/pre-commit .githooks/commit-msg .githooks/pre-push` passes.
- [x] `bash tests/hooks.test.sh`: 292 passed, 0 failed.
- [x] `node --test tests/ship.test.mjs tests/skills.test.mjs tests/marketplace.test.mjs`: 40 passed, 0 failed.
- [x] `python3 scripts/workflow-svg.py --check` passes.

## Needs a human or a live session

- [ ] A live Codex session with `.codex/hooks.json` trusted in `/hooks`.
- [ ] A live Command Code session with `.commandcode/settings.json` and `.commandcode/agents/reviewer.md`.
- [ ] A full `/dotagent:ship` smoke on a real repo: a one-sentence diff, a failed check that pivots, a stop, and `continue`.
- [ ] Push, PR, merge, and the `v0.7.0` release.

## Audit commands

```bash
python3 -m py_compile plugin/hooks/guard.py
sh -n plugin/hooks/run.sh && sh -n plugin/hooks/loop.sh
bash -n .githooks/pre-commit .githooks/commit-msg .githooks/pre-push
bash tests/hooks.test.sh
node --test tests/ship.test.mjs tests/skills.test.mjs tests/marketplace.test.mjs
python3 scripts/workflow-svg.py --check
grep -rniE "\bthree modes\b|ship-large|\bplanner\b|\bworker\b|\bscale\b|benchmark/|examples/" \
  --exclude-dir=.git --exclude-dir=reference --exclude-dir=tasks --exclude-dir=ideas --exclude=CHANGELOG.md .
```
