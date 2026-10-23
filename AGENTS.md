# dotagent

A Claude Code plugin: skills, agents, a guard hook, and templates for a small agent workflow. Generic working rules come from the dotagent, the facts below are this repo's.

## Commands

- Build: none, the plugin is plain files.
- Run: none.
- Format: none. Lint: none.
- Test: `bash tests/hooks.test.sh && node --test tests/ship.test.mjs && node --test tests/skills.test.mjs && node --test tests/marketplace.test.mjs`
- One file: `node --test tests/ship.test.mjs`, or `bash tests/hooks.test.sh` for the guard only.

## Architecture

- Style: a plugin package of files, no service. Structure: by role, one folder per kind of file.
- Coupling: `plugin/` never reads `tests/`, `benchmark/`, `examples/`, or `scripts/`. Dependencies point from the tests to the plugin, never back. Enforced by grep for now, no boundary check yet.

## Modules

- `plugin/hooks/`: the guard (`guard.py`) and its shell entry (`run.sh`). Public interface: `run.sh`. May depend on: nothing in the repo.
- `plugin/skills/`: the commands `setup`, `ship`, `workflow`, `scale`, `dotagent`. Public interface: each `SKILL.md`. May depend on: `hooks/run.sh`, `agents/`, `templates/`.
- `plugin/agents/`: `planner`, `worker`, `reviewer`. May depend on: nothing in the repo.
- `plugin/workflows/`: `ship-large.js`, the large-scale run. May depend on: `agents/`.
- `plugin/templates/`: files copied into a user's repo, mirroring its paths. May depend on: nothing.
- `tests/`: the guard and ship tests. May depend on: `plugin/`.
- `benchmark/`, `examples/`, `scripts/`: measurement, the example app, the release notes script. May read `plugin/`, never written back by it.

## Rules

- Every change goes through a PR into `main`. No direct push.
- Merging a change to `plugin/.claude-plugin/plugin.json` or `CHANGELOG.md` tags a release (`.github/workflows/release.yml`). Bump the version only with the user's yes.
- Commits are one line, `type(scope): summary`, no trailer. Scopes: plugin, skills, ship, workflow, hooks, guard, setup, templates, readme, changelog, repo, benchmark, ci.
- Names say what changed. Never a plan label such as `milestone-1`, `task-2`, or `wip`, and never `(#N)`.
- Planning notes stay local: keep them untracked and listed in `.git/info/exclude`, never in `.gitignore`, and never pushed.
- Never edit protected paths (`protected` in `.dotagent/config.json`: `release.yml`, `LICENSE`, `plugin/.claude-plugin/plugin.json`). The guard refuses it.
- The benchmark spends real quota. Run it only when the user asks.
