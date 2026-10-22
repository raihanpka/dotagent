---
description: Save the merge level for every run (off, on-green, full), or show it. on-green and full merge each PR and carry on to the next.
argument-hint: "off|on-green|full"
disable-model-invocation: true
---
With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set merge <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output only.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
