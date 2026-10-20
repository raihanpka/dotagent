---
description: Set dotagent up in this repo by interview, then generate its files and config.
disable-model-invocation: true
---
# dotagent setup

Runs once per repo and interviews the user in rounds, like grill-me, then writes the files and the
workflow settings in `.dotagent/config.json`. If both already exist, say so and stop.

Read `${CLAUDE_SKILL_DIR}/../../SETUP.md` and follow it. The templates it names are in
`${CLAUDE_SKILL_DIR}/../../templates/`. If those paths do not resolve, find the plugin folder with
`ls ~/.claude/plugins/cache/*/dotagent/*/SETUP.md` and use the folder that holds it.
