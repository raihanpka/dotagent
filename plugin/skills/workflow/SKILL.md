---
description: "Pick how far a run goes on its own. local: stops at local commits, never pushes. ask: asks for your yes before any push, PR, or merge. auto: goes all the way to the merge. No argument shows the saved settings."
argument-hint: "[local|ask|auto]"
disable-model-invocation: true
---
Modes:
- `auto`: runs the whole TODO and finishes every PR: pushes, opens it, watches CI, fixes a red check, merges when the review is clean and CI is green, then goes on to the next PR until all are merged or something stops it.
- `ask`: the same run and local commits, but it asks for your yes in the chat before any push, PR, or merge.
- `local`: asks first, sets up the minimum, keeps every commit on one local branch, and never pushes.

With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set workflow <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output and one line: the mode now in use.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
End the reply with one line `next:` `/dotagent:ship <task>`.
