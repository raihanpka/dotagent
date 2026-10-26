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
| `plugin/hooks/` | the guard (`guard.py`) and its shell entry | nothing in the repo | `run.sh`, with `set`, `show`, `approve`, `receipt`, `hooks`, `gate` |
| `plugin/skills/` | the commands `setup`, `ship`, `workflow`, `dotagent` | `hooks/run.sh`, `agents/`, `templates/` | each `SKILL.md`, and the `references/` it reads on demand |
| `plugin/agents/` | `reviewer`, the one subagent | nothing in the repo | each `.md` |
| `plugin/templates/` | files copied into a user's repo | nothing in the repo | the repo path it mirrors |
| `tests/` | `hooks.test.sh`, `ship.test.mjs`, `skills.test.mjs`, `marketplace.test.mjs` | `plugin/` | the four files |
| `benchmark/`, `examples/`, `scripts/` | measurement, the example app, the release notes script | `plugin/`, read only | their `README.md` |

## Current violations

None. `grep -rnE "tests/|benchmark/|examples/|scripts/" plugin` finds one comment, `plugin/hooks/guard.py:150`, and no import.

## Boundary check

None yet. The coupling rule is checked by the grep above. Open item in `DOTAGENT-SETUP.md`.

## Flow

`/dotagent:ship <task>` reads `.dotagent/config.json`. The lead writes `docs/TODO.md` when the diff is more than one sentence, commits each subtask itself, and a fresh reviewer checks the diff and writes the PR body. The guard checks each Bash, Write, Edit, and Read call on the way. The git hooks check every commit and push, from anyone.
