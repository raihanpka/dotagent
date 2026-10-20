# {{project}}

{{One line: what this repo is.}} Generic working rules come from the harness, the facts below are this repo's.

## Commands

- Build: `{{build}}`
- Lint: `{{lint}}`
- Test: `{{test}}` (one file: `{{test-one}}`)

## Modules

<!-- One line per module: what it owns and what it may import. The boundary check enforces it. -->
- `{{path}}`: {{owns}}. May import: {{allowed}}.

## Rules

- Branch from `{{default-branch}}`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer. Scopes: {{scopes}}.
- Never edit generated files under `{{generated}}`. Run `{{codegen}}` instead.
- A PR stays near 400 changed lines. Split a bigger task into slices that each build and pass.
- {{a rule that differs from the language defaults, one per line}}
