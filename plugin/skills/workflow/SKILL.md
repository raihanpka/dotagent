---
description: "Pick how far a run goes on its own. local: stops at local commits, never pushes. auto: goes all the way to the merge. No argument shows the saved settings."
argument-hint: "[local|auto]"
disable-model-invocation: true
---
Modes:
- `auto` (default): runs the whole TODO and finishes every PR: pushes, opens it, watches CI, fixes a red check, merges when the review is clean and CI is green, then goes on to the next PR until the finish predicate passes or a stop.
- `local`: asks first, sets up the minimum, keeps every commit on one local branch, and never pushes.

With an argument run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set workflow <argument>`.
With none run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output and one line: the mode now in use.
The command rejects any other value. Never edit `.dotagent/config.json` by hand.
End the reply with one line `next:` `/dotagent:ship <task>`.
