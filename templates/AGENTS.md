# {{project}}

{{one line: what this repo is}}

## Commands

- Build: `{{build}}`
- Lint: `{{lint}}`
- Test: `{{test}}` (one file: `{{test-one}}`)

## Modules

<!-- One line per module: what it owns and which modules it may import. Boundaries are
     enforced by {{boundary check}}, not by this list. -->
- `{{path}}`: {{owns}}. May import: {{allowed}}.

## Rules

- Branch from `{{default-branch}}`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer. Details go in the PR.
- Never edit generated files under `{{generated}}`. Run `{{codegen}}` instead.
- {{rule that differs from the language defaults, one per line}}
