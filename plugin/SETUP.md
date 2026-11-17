# Setup

For the agent reading this. Set up dotagent in the user's repo once. Read this file, and read `SETUP-REFERENCE.md` only when a step says to.
It holds the flow table, the CI split, the naming rules, and the git hooks.

Show every file before you write it. Never overwrite a file that exists: show a diff and ask. Never push, open a PR, or merge.
`sh hooks/run.sh` below is the plugin's `hooks/run.sh`, run by the path this skill gives you. Without the plugin, use `sh .dotagent/run.sh`.

Setup runs once. If `.dotagent/config.json` and `docs/DOTAGENT-SETUP.md` both exist, stop and say: already set up, change settings with
`/dotagent:workflow` or edit the config, and delete both files to run setup again. A `setup=minimal` config means the user only went on
with a TODO before: run the full setup now and save `setup full`.

## 0. Look first, cheaply

Grep and read ranges, not whole files. Find the language, the default branch, the build, lint, test, and format commands, the docs, the
CI, the PR template, the git hooks, and the commit habit (`git log --format=%s -n 30`). Match a doc by meaning, not by name: an
`architecture/` folder or an `arsitektur.md` is the architecture doc. Ask only about what you could not find.

Read the flow too: `git remote get-url origin`, `gh auth status`,
`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`,
`gh pr list --state merged -L 30 --json baseRefName`, and the last 30 subjects. When the host is not GitHub, `gh` is missing, or work does
not go through PRs, say so in two lines, save `workflow local`, and write an open item in `docs/DOTAGENT-SETUP.md`.

## 1. Ask one round

Ask with AskUserQuestion, recommended option first. If it is missing, load it with ToolSearch and retry once; otherwise ask in plain text,
numbered, and wait. Headless: take the recommended option and say so. Never guess an answer the setup depends on.

- **Agent.** `claude`, `codex`, `commandcode`, `both`, or `other`. Recommend the one this setup runs in. `commandcode` means Command Code.
- **Commands.** Build, lint, test, one file, one module. Recommend what the repo already uses, so the agent and CI agree.
- **Workflow.** `auto` or `local`. Recommend `auto` for a fully automated run that ends at the merge, otherwise `local`. There is no
  middle mode: the loop either finishes the task or keeps every commit on the machine.
- **Verification.** Ask once: is there a script that drives the app or service and proves a feature works? If yes, record the command.
  If no, offer `docs/VERIFICATION.md` with a feature map and a proof command. Ask once more, only when the repo has concurrency, retries,
  a state machine, a parser, or money: does a property need a formal check? If yes, fill one row and tell the user the tool choice in
  one line. Otherwise leave the section empty. When the repo deploys, ask for the release, watch, and rollback commands and fill the
  Production section.
- **Protected paths.** Recommend migrations, lockfiles, secrets, deploy config, and CODEOWNERS. Save them.

Do not ask about the scope style, the merge method, or the base branch when step 0 found them. Recommend the repo's own habit. Save only
what differs from the default: `commit_types`, `commit_scope optional`, `merge_method`, `base_branch`.

## 2. Write

Read `SETUP-REFERENCE.md` before this step, then write each file at its own path, showing it first, and tick `Written` in
`docs/DOTAGENT-SETUP.md` right after. Leave `Reviewed` for the user.

| File | From | When |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | always, under 60 lines, merged with existing rules |
| `CLAUDE.md` | `templates/CLAUDE.md` | `claude` or `both`, and the repo has none |
| `.agents/skills/dotagent-ship/SKILL.md` | `templates/.agents/skills/dotagent-ship/SKILL.md` | always, so Codex, Command Code, and other agents ship the same way |
| `.codex/agents/reviewer.toml` | `templates/.codex/agents/reviewer.toml` | `codex` or `both` |
| `.codex/hooks.json` | `templates/.codex/hooks.json` | `codex` or `both` |
| `.commandcode/settings.json` | `templates/.commandcode/settings.json` | `commandcode` |
| `.dotagent/guard.py`, `.dotagent/run.sh` | `hooks/guard.py`, `hooks/run.sh` | `codex`, `commandcode`, or `other` |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | only a role the repo does not cover yet |
| `docs/VERIFICATION.md` | `templates/docs/VERIFICATION.md` | when the user said yes |
| `.github/PULL_REQUEST_TEMPLATE.md`, `PR_EXAMPLE.md` | `templates/.github/` | when work goes through PRs |
| `.github/workflows/ci-pr.yml`, `ci-default.yml` | `templates/.github/workflows/` | when work goes through PRs |
| `.githooks/pre-commit`, `commit-msg`, `pre-push` | `templates/.githooks/` | when the user said yes |
| `docs/DOTAGENT-SETUP.md` | `templates/docs/DOTAGENT-SETUP.md` | always |
| `.dotagent/config.json` | `templates/.dotagent/config.json`, written with `set` | always |

Save each answer with `sh hooks/run.sh set <key> <value>`: `set agents commandcode`, `set workflow auto`, `set setup full`, `set hooks on`,
`set protected "<globs>"`, and the repo flow keys. Append
`.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, and `docs/TODO.md` to `.gitignore`, skipping a line already there. Do it without asking,
then tell the user.

## 3. Prove

Run build, lint, and test once. `sh hooks/run.sh hooks` must print `on`; run `.githooks/pre-commit` once. For `codex`, ask the user to open
`/hooks` and trust the dotagent hooks once. For `commandcode`, ask the user to start a session and confirm the `[dotagent]` capsule appears.
Offer one tiny task as a smoke test: a one sentence diff, no plan, one PR.

## 4. Commit and report

Commit in atomic commits, one line each, scope required, explicit paths, no trailer. Never push. List what you wrote, what you skipped, and
what the user must still decide. End with one line `next:` that names the first thing to try.
