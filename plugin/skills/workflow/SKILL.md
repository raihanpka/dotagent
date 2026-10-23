---
description: Pick how a run ends for every run. autopilot pushes and merges, checkpoint asks first, adapt stays local.
argument-hint: "autopilot|checkpoint|adapt"
disable-model-invocation: true
---
Modes:
- `autopilot`: runs the whole TODO, pushes, opens each PR, watches CI, merges when the review is clean and CI is green, and goes on to the next PR.
- `checkpoint`: the same run and local commits, but it asks for your yes in the chat before any push, PR, or merge.
- `adapt`: asks first, sets up the minimum, keeps every commit on one local branch, and never pushes.

With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set workflow <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output and one line: the mode now in use.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
