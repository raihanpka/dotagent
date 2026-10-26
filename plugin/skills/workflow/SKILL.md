---
description: "Pick how far a run goes on its own. adapt: stops at local commits, never pushes. checkpoint: asks for your yes before any push, PR, or merge. autopilot: goes all the way to the merge. No argument shows the saved settings."
argument-hint: "[autopilot|checkpoint|adapt]"
disable-model-invocation: true
---
Modes:
- `autopilot`: runs the whole TODO, pushes, opens each PR, watches CI, merges when the review is clean and CI is green, and goes on to the next PR.
- `checkpoint`: the same run and local commits, but it asks for your yes in the chat before any push, PR, or merge.
- `adapt`: asks first, sets up the minimum, keeps every commit on one local branch, and never pushes.

With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set workflow <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output and one line: the mode now in use.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
End the reply with one line `next:` `/dotagent:ship <task>`.
