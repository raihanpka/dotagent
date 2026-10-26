# Dotagent setup

Written by the setup agent so a human can track and review it. The agent ticks Written when it writes a file.
You tick Reviewed once you have read it.

## Decisions

| Setting | Value | Why |
|---|---|---|
| workflow | {{autopilot, checkpoint, or adapt}} | {{reason}} |
| em dash and emoji | {{block (default) or allow}} | {{reason}} |
| companion skills | {{plan, build, style skills, or none}} | {{reason}} |
| commit scopes | {{list}} | {{reason}} |
| git hooks on | {{yes (`git config core.hooksPath .githooks`) or no}} | {{reason}} |

## Generated files

| File | Source | Written | Reviewed |
|---|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | [ ] | [ ] |
| `CLAUDE.md` | `templates/CLAUDE.md` | [ ] | [ ] |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/.github/PULL_REQUEST_TEMPLATE.md` | [ ] | [ ] |
| `.github/PR_EXAMPLE.md` | `templates/.github/PR_EXAMPLE.md` | [ ] | [ ] |
| `.github/workflows/ci-pr.yml` | `templates/.github/workflows/ci-pr.yml` | [ ] | [ ] |
| `.githooks/pre-commit`, `commit-msg`, `pre-push` | `templates/.githooks/` | [ ] | [ ] |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | [ ] | [ ] |
| `.dotagent/config.json` | `templates/.dotagent/config.json`, set with `run.sh`, ignored by git | [ ] | [ ] |
| `.gitignore` | adds `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, `docs/TODO.md` | [ ] | [ ] |

## Open items

- [ ] {{anything the agent could not decide or find, one line each}}

## Undo

`git revert` the setup commit, then run `git config --unset core.hooksPath` if the git hooks were enabled.
