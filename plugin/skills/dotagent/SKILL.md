---
description: "Shortcut for /dotagent:ship. With a task it ships it, alone it shows the run state and the next step."
argument-hint: "<task> | continue | status"
disable-model-invocation: true
---
`RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`.

- No arguments, or `status`: run `sh "$RUN" state`. Reply with the capsule and one line `next:`
  naming `/dotagent:ship <task>`, `continue`, `/dotagent:workflow`, or `/dotagent:setup`. If `run=stopped`, add one line: say `continue`
  to resume from the recorded reason.
- `continue` (any wording): invoke the `ship` skill with the user's words unchanged. It resumes from state, not memory.
- `stop` or `pause`: if a run is active, write `## stopped` with `reason: needs-human`, the one line of what is in flight, and the next
  action. Run `sh "$RUN" stop needs-human "paused by the user"`, then reply with the capsule and `next:`.
- Anything else is a task: invoke the `ship` skill with the user's words unchanged.
