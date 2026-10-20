# Dotagent setup

Written by the setup agent so a human can track and review it. Tick a file once you have read it.

## Decisions

| Setting | Value | Why |
|---|---|---|
| scale | {{small, medium, or large}} | {{reason}} |
| merge level | {{off, on-green, or full}} | {{reason}} |
| em dash | {{block or allow}} | {{reason}} |
| companion skills | {{plan, build, style skills, or none}} | {{reason}} |
| commit scopes | {{list}} | {{reason}} |

## Generated files

| File | Source | Reviewed |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | [ ] |
| `CLAUDE.md` | one line, `@AGENTS.md` | [ ] |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/PULL_REQUEST_TEMPLATE.md` | [ ] |
| `.github/PR_EXAMPLE.md` | `templates/PR_EXAMPLE.md` | [ ] |
| `.github/workflows/{{name}}.yml` | `templates/ci.yml` | [ ] |
| `.githooks/commit-msg`, `.githooks/pre-push` | `templates/githooks/` | [ ] |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | [ ] |
| `.claude/settings.json` | allow `Workflow`, deny reads of generated paths | [ ] |

## Open items

- [ ] {{anything the agent could not decide or find, one line each}}

## Undo

`git revert` the setup commit, then run `git config --unset core.hooksPath` if the git hooks were enabled.
