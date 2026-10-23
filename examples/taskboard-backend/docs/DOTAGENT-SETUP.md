# Dotagent setup

Written by the setup agent so a human can track and review it. Tick a file once you have read it.

## Decisions

| Setting | Value | Why |
|---|---|---|
| scale | small | A tiny single-team repo with 3 modules. |
| workflow | checkpoint | The benchmark copy has no remote, so nothing may be pushed without a yes. |
| em dash and emoji | block | The default, the agent writes neither. |
| companion skills | none | `style_skills` is none. |
| git hooks on | yes, `git config core.hooksPath .githooks` | They check every commit and push, by anyone, before CI does. |
| commit scopes | auth, boards, tasks, labels, profile, webhooks, app, httpx, config, repo, ci | The module names, plus `repo` for root files and `ci` for workflows. |
| git hooks | enabled | `git config core.hooksPath .githooks` was run in this clone. |
| protected paths | go.mod, go.sum | A new dependency needs the user, so no agent edits them. |

## Generated files

| File | Source | Reviewed |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | [ ] |
| `CLAUDE.md` | `templates/CLAUDE.md` | [ ] |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/.github/PULL_REQUEST_TEMPLATE.md` | [ ] |
| `.github/PR_EXAMPLE.md` | `templates/.github/PR_EXAMPLE.md` | [ ] |
| `.github/workflows/ci-pr.yml` | `templates/.github/workflows/ci-pr.yml` | [ ] |
| `.github/workflows/ci-default.yml` | `templates/.github/workflows/ci-default.yml` | [ ] |
| `.githooks/pre-commit`, `commit-msg`, `pre-push` | `templates/.githooks/` | [ ] |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | [ ] |
| `.dotagent/config.json` | `templates/.dotagent/config.json`, set with `run.sh`, ignored by git | [ ] |
| `.claude/settings.json` | `templates/.claude/settings.json`: allow `Workflow` for the large scale | [ ] |
| `.gitignore` | adds `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, `docs/TODO.md` | [ ] |

## Proof run

`make ci` (format check, `go vet`, build, `go test -race`) passes. `bash tests/hooks.test.sh` from the dotagent checkout passes.

## Open items

- [ ] The repo has no GitHub remote, so the PR and CI steps cannot run yet. Add one, push `main`, and make `Pull Request Go Gate` a required status check.
- [ ] No coupling checker exists. Add `depguard` to a `.golangci.yaml` if the repo grows.
- [ ] Stores are in memory. Pick a database before this is more than a benchmark app.

## Undo

`git revert` the setup commits, then run `git config --unset core.hooksPath` if the git hooks were enabled.
