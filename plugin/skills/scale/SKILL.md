---
description: "Pick the size of a run. small: no plan, for a tiny diff. medium (default): planner, one Haiku worker per subtask, reviewer. large: the ship-large workflow, falls back to medium without the Workflow tool. No argument shows the saved settings."
argument-hint: "[small|medium|large]"
disable-model-invocation: true
---
With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set scale <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output only.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
End the reply with one line `next:` `/dotagent:workflow` to pick how a run ends, or `/dotagent:ship <task>`.
