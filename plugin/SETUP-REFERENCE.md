# Setup reference

Read this only when `SETUP.md` sends you here. It holds the details: the agent table, the prerequisites, the repo flow, the naming rules,
the CI split, and the git hooks.

## Which agent, and what it writes

| `agents` | The agent that runs dotagent | Setup writes |
|---|---|---|
| `claude` | Claude Code | the plugin, `AGENTS.md`, `CLAUDE.md`, the docs, the config |
| `codex` | OpenAI Codex | `AGENTS.md`, the portable skill, `.codex/agents/reviewer.toml`, `.codex/hooks.json`, `.dotagent/`, the docs, the config |
| `commandcode` | Command Code | `AGENTS.md`, the portable skill, `.commandcode/settings.json`, `.dotagent/`, the docs, the config |
| `both` | Claude Code and Codex | everything for `claude` and `codex`, with one `AGENTS.md` and one `CLAUDE.md` |
| `other` | Cursor, Antigravity, or any agent that reads `AGENTS.md` and `.agents/skills` | `AGENTS.md`, the portable skill, `.dotagent/`, the docs, the config |

For `other`, `codex`, and `commandcode`, the plugin is not installed, so `.dotagent/guard.py` and `.dotagent/run.sh` are copied and the
agent's own hook file runs them. Setup never writes `.claude/` for a non-Claude agent.

## Prerequisites

Check each with `command -v` and report what is missing with its install link. Install nothing without asking.

| Tool | Why | Check |
|---|---|---|
| Claude Code, Codex, or Command Code | the agent and its hooks | the command the user runs |
| Git | branches and commits | `git --version` |
| GitHub CLI `gh`, signed in | the PR, CI, and merge steps | `gh auth status` |
| Python 3.8 or newer | the guard, through `run.sh`, which tries `python3`, `python`, then `py` | `python3 --version` |
| Node and `jq` (optional) | only dotagent's own tests | `node --version`, `jq --version` |

## The repo flow

Read it, do not ask for what you can find:

- **Host.** `git remote get-url origin`. Only GitHub with `gh` signed in supports the PR, CI, and merge steps.
- **Merge methods.** `gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`. Save `merge_method` when squash is not allowed.
- **PRs at all.** `gh pr list --state merged -L 30 --json baseRefName`. No merged PRs, or commits straight on the default branch, means a
  trunk flow without PRs: save `workflow local` and skip the `.github/` rows.
- **The base branch.** The `baseRefName` of the recent merged PRs, which is not always the default branch. Save `base_branch` when it differs.
- **The naming habit.** The last 30 subjects. Save `commit_types` when the list differs, and `commit_scope optional` when the repo writes
  `feat: add x`. When the habit has no type at all, ask whether to adopt `type(scope): summary`, do not silently change it.
- **Titles.** A commit, PR title, and merge subject say what changed. Never a plan label: no `milestone-1`, `task-2`, `slice 3`, `step 4`,
  `wip`, or "finishing task", and never `(#N)`. A hook and `.githooks/commit-msg` refuse them.
- **Trailers.** Do not ask. No `Co-Authored-By`, no `Signed-off-by`, no "Generated with" line, in a commit or a PR body. The hook refuses them.
- **Protected paths.** Recommend migrations, CODEOWNERS, lockfiles, secrets, and deploy config. Save them with `set protected "<globs>"`.
- **Generated files.** Find the paths and the regenerator command, and put the rule in `AGENTS.md`. Never block reading them, debugging needs it.

## Naming

The default is `type(scope): summary` for a commit and a PR title. Allowed types by default:
`feat`, `fix`, `hotfix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `revert`, `ci`, `build`. The scope is the module. Tests go
with the code they cover. A refactor is its own commit, never mixed with a feature. A commit message is one line. Only a local squash lists
`- <short hash> <subject>` lines.

## CI

Two workflows, one trigger each, so a branch push never runs CI twice.

- `ci-pr.yml` runs on `pull_request` only. It is the gate: format check, lint (and type check where the language has one), build, unit tests,
  a dependency vulnerability scan, and a secret scan when the stack has a tool. Keep it under about 10 minutes. Tell the user to make it a
  required status check, with "require branches to be up to date".
- `ci-default.yml` runs on `push` to the default branch only. It holds what is too heavy for every PR: services, migrations, boot and health
  probe, integration tests. Skip it when the repo has nothing heavier.

Titles use one plain word for the stack or product: `Pull Request {{ }} Gate` and `Default Branch {{ }} Check`. Existing CI is the user's:
never rewrite, rename, or delete it. When a workflow already gates `pull_request` with format, lint, build, and test, it is the gate: record
its name in `AGENTS.md`. When one exists but does not run on PRs, show the exact diff and ask before enabling it.

## Git hooks

Recommend all three and turn them on: `.githooks/pre-commit` (format check and lint), `commit-msg`, and `pre-push` (format, lint, build,
test). They check every commit and push by anyone, not only the agent. In a big repo make `pre-commit` check only the staged files. First
check `git config core.hooksPath`, `.husky/`, `lefthook.yml`, and `.pre-commit-config.yaml`. When one exists, the repo has its own hooks:
do not change `core.hooksPath` and do not write `.githooks`, add an open item instead. Turning them on runs
`git config core.hooksPath .githooks`, a local and reversible change, so ask once first.

## When the user is unsure

Do not stall and do not quiz them. Say in one sentence that you will suggest, then suggest.

- **An established repo:** the code already has an answer. Describe what it shows, name it, and record it as it is today. Do not propose a
  rewrite.
- **A new or nearly empty repo:** recommend the simplest architecture that fits the project, its size, its stack, and how many people will
  work on it. Usually a modular monolith with vertical slices. Give the best practice and the reason in two lines, and ask whether they agree.
- **Any other open answer:** give the recommended option and the best practice behind it, and go on. A guess goes to the open items.

## The generated files

`templates/` mirrors the target repo path for path: the template for `.github/workflows/ci-pr.yml` is `templates/.github/workflows/ci-pr.yml`.
Check every target first with `git ls-files` and the disk. A role covered by an existing doc is not generated again: show a new section as an
addition and ask, never replace. A PR template under another name or folder counts as existing.

`docs/TODO.md` is not generated here. The agent writes it per task from `templates/docs/TODO.md`, and it is ignored by git on purpose.

## Prove it, per agent

Run build, lint, and test once. Check `sh hooks/run.sh hooks` prints `on`, then run `.githooks/pre-commit` once to see it pass.

- `claude`: `sh hooks/run.sh show` prints the saved settings.
- `codex`: ask the user to open `/hooks` in Codex and trust the dotagent hooks once. Codex does not run an untrusted hook.
- `commandcode`: ask the user to start a session and confirm the `[dotagent]` capsule line appears. The hooks live in
  `.commandcode/settings.json` and run through `.dotagent/run.sh --client commandcode`.
- `other`: no guard runs, so only the git hooks and CI check the work. Say so.

Then offer one tiny task as a smoke test: a one sentence diff, no plan, one PR.

## Install, per agent

- **Claude Code:** `/plugin marketplace add raihanpka/dotagent`, then `/plugin install dotagent@dotagent`.
- **Codex:** `codex plugin marketplace add raihanpka/dotagent`, then install dotagent from `/plugins` and trust its hooks in `/hooks`.
- **Command Code:** `cmd skills add raihanpka/dotagent -s dotagent-ship`, or copy `skills/dotagent-ship/` to
  `.commandcode/skills/dotagent-ship/`. Command Code also reads `.agents/skills/` directly. Run it as `/dotagent-ship <task>`.
- **Cursor, Antigravity, other:** `npx skills add raihanpka/dotagent --skill dotagent-ship -a codex -a antigravity-cli -y`, or copy
  `.agents/skills/dotagent-ship/` into the repo. The agent runs it as `/dotagent-ship <task>`.
