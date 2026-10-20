# Harness setup

Written by the setup agent so a human can track and review it. Tick a file once you have read it.

## Decisions

| Setting | Value | Why |
|---|---|---|
| scale | medium | Answered by the requester: 14 modules, but one team and one repo. |
| merge level | off | Answered by the requester, and the repo has no remote yet. |
| em dash | block | Answered by the requester. |
| companion skills | plan: `agent-skills:planning-and-task-breakdown`, build: `agent-skills:incremental-implementation`, style: none | Answered by the requester. |
| commit scopes | ai, auth, billing, calendar, docs, health, home, notifications, onboarding, profile, projects, release, tasks, whatsapp, repo, ci | The module names under `internal/modules`, plus `repo` and `ci`. |

## Generated files

| File | Source | Reviewed |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | [ ] |
| `CLAUDE.md` | one line, `@AGENTS.md` | [ ] |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/PULL_REQUEST_TEMPLATE.md` | [ ] |
| `.github/PR_EXAMPLE.md` | `templates/PR_EXAMPLE.md` | [ ] |
| `.github/workflows/quality.yml` | `templates/ci.yml` | [ ] |
| `.githooks/commit-msg`, `.githooks/pre-push` | `templates/githooks/` | [ ] |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | [ ] |
| `.claude/settings.json` | allow `Workflow`, deny reads of generated paths | [ ] |

## Checks run

Run from the repo root on 2026-10-20. Build, lint, and test all passed before the setup commits.

- `make build`: exit 0
- `make lint`: `0 issues.`
- `make test`: exit 0
- `test -z "$(gofmt -l .)"`: exit 0
- `bash tests/hooks.test.sh` in the harness checkout: `passed 30, failed 0`

Module boundary check. For every module, grep all its files, tests included, for imports of any module other than itself. Empty output for a module means it holds.

```
P='github.com/acme/api/internal'
for m in $(ls internal/modules); do echo "## $m"; grep -rn --include='*.go' "\"$P/modules/" "internal/modules/${m}" | grep -v -E "\"$P/modules/${m}(/|\")"; done
```

Result: `ai`, `auth`, `calendar`, `docs`, `health`, `notifications`, `onboarding`, `projects`, and `release` hold. `billing`, `home`, `profile`, `tasks`, and `whatsapp` do not, see `ARCHITECTURE.md` for the list.

Shared libs imported by modules, and the rest of the allowed list:

```
grep -rhoE --include='*.go' "\"github.com/acme/api/internal/[a-z]+" internal/modules | sort | uniq -c
```

Result: only `config`, `db`, `email`, `http`, `observability`, `queue`, `redis`, and `testdb` (one test file) outside `modules`. `logging` is not imported by any module.

## Open items

- [ ] Prerequisite missing: the repo has no git remote, so the PR, CI, and merge steps cannot run yet. Add one with `git remote add origin <url>`.
- [ ] Fix or accept the module import violations listed in `ARCHITECTURE.md` (`billing`, `home`, `profile`, `tasks`, `whatsapp`). Most import a sub-package of `auth`, `home`, or `ai`, so each needs a public interface or a contract slice first.
- [ ] Add a boundary check once the violations are gone: `depguard` in `.golangci.yaml`, one rule per module. Adding it now fails CI.
- [ ] Decide whether `internal/testdb` is an allowed shared lib. `whatsapp/worker/habit_streak_test.go` imports it, and it is not on the allowed list.
- [ ] Decide whether `internal/http/engine_test.go` may import `modules/health`.
- [ ] `internal/idgen` and `internal/app` are not on the allowed list. No module imports `idgen` today.
- [ ] `make fmt-check` runs `gofmt -l .` and exits 0 even with unformatted files, so CI and the hooks do not use it. Make the target fail, or keep the inline check.
- [ ] `README.md` says `.githooks/` has a `pre-commit` hook that formats staged files and that `pre-push` blocks unformatted files. Neither existed in the repo. The harness `pre-push` runs `make lint` and `make test` instead, and there is no `pre-commit`.
- [ ] `make ci` also runs `vet` and `vuln`, which the CI workflow does not. Add them to `.github/workflows/quality.yml` if the old Quality Gate job should be matched.
- [ ] CI installs `golangci-lint` v2.12.2 with `go install` to match the local version. Bump it with the local binary.
- [ ] `make test` needs no services here, but `make smoke` needs Docker and Postgres, and CI does not run it.
- [ ] `sqlc` and `mockgen` are not on `PATH`, they are in `~/go/bin`, which `make generate` uses. Not checked this run, so generation is untested.
- [ ] No smoke-test task was run, since `scale` is medium.

## Undo

`git revert` the setup commits, then run `git config --unset core.hooksPath` if the git hooks were enabled.
