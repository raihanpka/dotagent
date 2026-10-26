---
description: "Shortcut for /dotagent:ship. With a task it ships it, alone it shows the saved settings."
argument-hint: "<task>"
disable-model-invocation: true
---
- No arguments: run `sh "${CLAUDE_SKILL_DIR}/../../hooks/run.sh" show`. Reply with the output and one line `next:` `/dotagent:ship <task>`,
  `/dotagent:workflow`, or `/dotagent:setup`. If the session line says `unfinished`, add one line: say `continue` to carry on.
- Anything else is a task: invoke the `ship` skill with the Skill tool and pass the user's words as its args, unchanged.
