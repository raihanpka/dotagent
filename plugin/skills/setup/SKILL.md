---
name: setup
description: "Set dotagent up in this repo by interview, once: the AI agent you use (Claude Code, Codex, Command Code, both, or another), commands, architecture, workflow, verification, CI, git hooks, and protected paths. Writes the files and the saved settings, shows each file first, and never overwrites. Stays small when the workflow is local."
disable-model-invocation: true
---
# dotagent setup

Runs once per repo and asks one short round, then writes the files and the workflow settings in `.dotagent/config.json`. If both the
config and `docs/DOTAGENT-SETUP.md` already exist, say so and stop.

`SKILL` is `${CLAUDE_SKILL_DIR}`.
Read `$SKILL/../../SETUP.md` and follow it. Read `$SKILL/../../SETUP-REFERENCE.md` only when `SETUP.md` sends you there. The templates it
names are in `$SKILL/../../templates/`. If those paths do not resolve, find the plugin folder with
`ls ~/.claude/plugins/cache/*/dotagent/*/SETUP.md` and use the folder that holds it.

At the end, save `set setup full`, show `docs/DOTAGENT-SETUP.md`, and end with one `next:` line for the first smoke task.
