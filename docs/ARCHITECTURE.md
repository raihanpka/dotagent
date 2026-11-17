# Architecture

## Style

- System: a plugin package of files, no service, because the product is skills, agents, a guard hook, and templates that run inside Claude Code and in a user's repo.
- Structure: by role, one folder per kind of file.
- Coupling rule: `plugin/` never reads `tests/`, `examples/`, or `scripts/`. Dependencies point from the tests to the plugin, never back.

## Shape

The plugin is what users install. Everything else in the repo tests it, measures it, or shows it.

## Modules

| Module | Owns | May depend on | Public interface |
|---|---|---|---|
| `plugin/hooks/` | the guard (`guard.py`), its shell entry, and `loop.sh` | nothing in the repo | `run.sh`, with `set`, `show`, `receipt`, `hooks`, `gate`, `phase`, `status`, `state`, `log`, `start`, `progress`, `stop` |
| `hooks/` (repo root) | the Codex hook entry, `hooks.json`, which runs `plugin/hooks/run.sh --client codex` on Codex's `Bash`, `apply_patch`, and `spawn_agent` | `plugin/hooks/run.sh` | read by Codex once the user trusts it with `/hooks` |
| `plugin/skills/` | the commands `setup`, `ship`, `workflow`, `review`, `dotagent` | `hooks/run.sh`, `agents/`, `templates/` | each `SKILL.md`, and the `references/` it reads on demand (loop, verify, fanout, production, plan, merge) |
| `plugin/agents/` | `reviewer`, the one subagent | nothing in the repo | each `.md` |
| `plugin/templates/` | files copied into a user's repo, including `.codex/` and `.commandcode/` | nothing in the repo | the repo path it mirrors |
| `skills/dotagent-ship/` | the portable skill for Codex, Command Code, and other agents | nothing in the repo | `SKILL.md`, byte identical to the template copy |
| `tests/` | `hooks.test.sh`, `ship.test.mjs`, `skills.test.mjs`, `marketplace.test.mjs` | `plugin/` | the four files |
| `examples/`, `scripts/` | the example app, the release notes script and the diagram svg script | `plugin/`, read only | their `README.md` |
| `docs/` | the practices, the state and log reference, the setup guide, and the loop diagram | `plugin/`, read only | their files |

## Current violations

None. `grep -rnE "tests/|examples/|scripts/" plugin` finds one comment in `plugin/hooks/guard.py` and no import.

## Boundary check

None yet. The coupling rule is checked by the grep above. Open item in `DOTAGENT-SETUP.md`.

## Flow

`/dotagent:ship <task>` reads `.dotagent/config.json` and the session capsule. The run is a circle: goal and finish predicate, read-only
plan in `docs/TODO.md`, one unit at a time, a scoped check, a real-artifact proof, a fresh reviewer, PR, CI, merge, then progress and the
next unit. A failed check goes back to the unit, two tries, then a named stop. `run.sh state` is the capsule a fresh process resumes from,
and `loop.sh` runs one fresh process per PR. A wide or risky change can fan out to swarm, arena, interrogate, or a panel. A release adds a
`watch:` after the merge and stops `regression` on a bad signal. The guard checks each shell, write, and edit call on the way. The git
hooks check every commit and push, from anyone. `docs/STATE.md` documents the state machine and the logs in `.dotagent`.
