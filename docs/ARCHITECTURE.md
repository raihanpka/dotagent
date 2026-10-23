# Architecture

## Style

- System: a plugin package of files, no service, because the product is skills, agents, a guard hook, and templates that run inside Claude Code and in a user's repo.
- Structure: by role, one folder per kind of file.
- Coupling rule: `plugin/` never reads `tests/`, `benchmark/`, `examples/`, or `scripts/`. Dependencies point from the tests to the plugin, never back.

## Shape

The plugin is what users install. Everything else in the repo tests it, measures it, or shows it.

## Modules

| Module | Owns | May depend on | Public interface |
|---|---|---|---|
| `plugin/hooks/` | the guard (`guard.py`) and its shell entry | nothing in the repo | `run.sh`, with `set`, `show`, `approve`, `receipt`, `hooks` |
| `plugin/skills/` | the commands `setup`, `ship`, `workflow`, `scale`, `dotagent` | `hooks/run.sh`, `agents/`, `templates/` | each `SKILL.md` |
| `plugin/agents/` | `planner`, `worker`, `reviewer` | nothing in the repo | each `.md` |
| `plugin/workflows/` | `ship-large.js`, the large-scale run | `agents/` | the file |
| `plugin/templates/` | files copied into a user's repo | nothing in the repo | the repo path it mirrors |
| `tests/` | `hooks.test.sh`, `ship.test.mjs` | `plugin/` | the two files |
| `benchmark/`, `examples/`, `scripts/` | measurement, the example app, the release notes script | `plugin/`, read only | their `README.md` |

## Current violations

None. `grep -rnE "tests/|benchmark/|examples/|scripts/" plugin` finds one comment, `plugin/hooks/guard.py:150`, and no import.

## Boundary check

None yet. The coupling rule is checked by the grep above. Open item in `DOTAGENT-SETUP.md`.

## Flow

`/dotagent:ship <task>` reads `.dotagent/config.json`. The planner writes `docs/TODO.md`, a worker commits each subtask, and the reviewer writes the PR body. The guard checks each Bash, Write, Edit, and Read call on the way. The git hooks check every commit and push, from anyone.
