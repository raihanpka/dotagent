---
description: Save the default scale (small, medium, large) for this repo, or show it.
argument-hint: "small|medium|large"
disable-model-invocation: true
---
With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set scale <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output only.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
