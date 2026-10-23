---
name: dotagent
description: Show or set the scale like /dotagent:scale, or ship a task with the saved settings.
argument-hint: "[small|medium|large | <task>]"
---
- No arguments, or only `small`, `medium`, or `large`: do what `/dotagent:scale` does. With the word run
  `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" set scale <word>`, with none run `... show`. Reply with the output and one line `next:` `/dotagent:ship <task>`, `/dotagent:workflow`, or `/dotagent:setup`. If the
  session line says `unfinished`, add one line: say `continue` to carry on.
- Anything else is a task: invoke the `ship` skill with the Skill tool and pass the user's words as its args, unchanged.
