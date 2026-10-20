# {{project}}

{{One line: what this repo is.}} Generic working rules come from the dotagent, the facts below are this repo's.

## Commands

- Build: `{{build}}`
- Run: `{{run}}`
- Format: `{{format}}` (check only: `{{format-check}}`)
- Lint: `{{lint}}`
- Test: `{{test}}` (one file: `{{test-one}}`)

## Architecture

- Style: {{modular monolith, microservices, event driven, layered, or other}}. Structure: {{vertical slices by feature, layers, or other}}.
- Coupling: {{the rule in one line, for example "a module is used only through its public interface, shared code lives in `shared/`, dependencies point one way"}}. Enforced by {{boundary check}}.

## Modules

<!-- One line per module: what it owns, its public interface, and what it may depend on. -->
- `{{path}}`: {{owns}}. Public interface: {{file}}. May depend on: {{allowed}}.

## Rules

- Branch from `{{default-branch}}`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer. Scopes: {{scopes}}.
- Names say what changed. Never a plan label such as `milestone-1`, `task-2`, `slice 3`, or "finishing task", and never `(#N)`, in a commit message, PR title, or branch.
- Never edit generated files under `{{generated}}`. Run `{{codegen}}` instead.
- A PR stays reviewable in one sitting, a few hundred changed lines is typical, a range and not a limit. A bigger task is more PRs that each build and pass.
- {{a rule that differs from the language defaults, one per line}}
