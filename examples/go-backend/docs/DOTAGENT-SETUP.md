# Dotagent setup

Written by the setup agent so a human can track and review it. Tick a file once you have read it.

## Decisions

| Setting | Value | Why |
|---|---|---|
| scale | medium | A single repo with 14 modules, worked on by a small team. |
| merge level | off | Start with a human merging every PR. |
| em dash | block | Keeps files, commits, and PR text free of em dashes. |
| emoji | block | Same reason, and the generated-by line in PR bodies is dropped. |
| companion skills | none | `style_skills` is none. |
| commit scopes | ai, auth, billing, calendar, docs, health, home, notifications, onboarding, profile, projects, release, tasks, whatsapp, repo, ci | The module names, plus `repo` for root files and `ci` for workflows. |
| git hooks | enabled | `git config core.hooksPath .githooks` was run in this clone. |

## Generated files

| File | Source | Reviewed |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | [ ] |
| `CLAUDE.md` | one line, `@AGENTS.md` | [ ] |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/PULL_REQUEST_TEMPLATE.md` | [ ] |
| `.github/PR_EXAMPLE.md` | `templates/PR_EXAMPLE.md` | [ ] |
| `.github/workflows/ci-pr.yml` | `templates/ci-pr.yml` | [ ] |
| `.github/workflows/ci-main.yml` | `templates/ci-main.yml` | [ ] |
| `.githooks/commit-msg`, `.githooks/pre-push` | `templates/githooks/` | [ ] |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | [ ] |
| `.claude/settings.json` | allow `Workflow`, deny reads of generated paths | [ ] |
| `.gitignore` | added the line `.dotagent/` | [ ] |

## Proof run

`make build`, `make vet`, `make lint` (0 issues), `gofmt -l .` (clean), and `make test` all passed. `bash tests/hooks.test.sh` from the dotagent checkout passed 33 of 33. The `scale=small` smoke task was not run because this run could not ask questions.

## Open items

- [ ] The repo has no GitHub remote, so the PR and CI steps cannot run yet. Add one, push `main`, and make `PR Gate` a required status check in branch protection.
- [ ] No coupling checker exists. `docs/ARCHITECTURE.md` lists 13 imports that reach into another module's inner packages (`auth/data`, `auth/tokenstore`, `auth/signingingoogle`, `home/service`). Decide whether to expose a root-package interface for each, then add a `depguard` rule to `.golangci.yaml` so CI fails on new ones. The rule was not added because it would fail on the existing imports today.
- [ ] `internal/http/engine_test.go` imports `modules/health`, a shared lib depending on a module (test only).
- [ ] `make fmt-check` runs `gofmt -l .`, which exits 0 even when files are unformatted. CI uses `test -z "$(gofmt -l .)"` instead. Consider fixing the Makefile target and `make ci`.
- [ ] `ci-pr.yml` installs golangci-lint with `go install ...@latest`. Pin a version once you pick one.
- [ ] `make vuln` (govulncheck) is part of `make ci` but not of `PR Gate`, as requested. Add it if you want the scan on every PR.
- [ ] `make smoke` (boots the server against Postgres) is not run in CI. `ci-main.yml` builds only because this copy has no migrations or services.
- [ ] `README.md` is out of date against the repo: it describes a `pre-commit` gofmt hook, a `pre-push` that only checks formatting, `dev` branch workflows (Quality Gate, Staging, Deploy Production), and docs guides and `docs/assets` that do not exist here. The generated `pre-push` now runs `make lint` and `make test`. The Makefile `hooks` comment also mentions a pre-commit hook.
- [ ] `.dockerignore` lists `.golangci.yml` but the file is `.golangci.yaml`.

## Undo

`git revert` the setup commits, then run `git config --unset core.hooksPath` if the git hooks were enabled.
