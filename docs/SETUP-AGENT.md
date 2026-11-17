# dotagent setup for agents without the plugin

For the agent reading this. Set up dotagent in the user's repo for an agent that does not run the Claude Code plugin (Codex, Command Code,
Cursor, Antigravity, or another). Do it in order. Show each file before you write it.

Never overwrite a file that exists: show a diff and ask. Never push, open a PR, or merge without the user's yes. Never write an em dash or
an emoji in a file. Your tools may have no question tool: ask in plain text, a numbered list, the recommended option first, one line of
reason each, then wait. Never guess an answer the setup depends on.

Raw files for this guide come from `https://raw.githubusercontent.com/raihanpka/dotagent/main/`. Fetch each with `curl -sSf <base><path>`.

## 0. Check the tools

Run `command -v git`, `command -v gh`, and `command -v python3`. Check `gh auth status` and `python3 --version` (3.8 or newer). Report what
is missing. Install nothing without asking.

## 1. Look first

Read the repo, do not guess. Find the language and the build, lint, and test commands, the default branch
(`git symbolic-ref refs/remotes/origin/HEAD`), an existing `AGENTS.md`, the CI, the PR template, the git hooks, the docs, and the commit
habit (`git log --format=%s -n 30`). Match a doc by meaning, not by name. Ask only about what you could not find.

Read the flow too: the remote host, the merge methods the repo allows, the branch PRs target, and the commit types and scope. When the host
is not GitHub, there is no remote, `gh` is missing, or work does not go through PRs, write an open item and keep the whole run local.

## 2. Ask one round

- **Agent:** `codex`, `commandcode`, `both`, or `other` (Cursor, Antigravity, another). Claude Code uses the plugin and `/dotagent:setup`.
- **Commands:** the build, the lint, and one test command. Recommend what the repo already uses.
- **Workflow:** `auto` or `local`. Recommend `auto` for a fully automated run that ends at the merge, otherwise `local`.
- **Verification:** is there a script that drives the app and proves a feature? If not, offer `docs/VERIFICATION.md` with a feature map.
  Ask once more, only for concurrency, retries, a state machine, a parser, or money: does a property need a formal check? When the repo
  deploys, ask for the release, watch, and rollback commands and fill the Production section.
- **Protected paths:** migrations, lockfiles, secrets, deploy config, CODEOWNERS. Recommend what the repo has.
- **Git hooks:** turn them on with `git config core.hooksPath .githooks`. Recommend yes.

Recommendations come with one line of reason, listed first.

## 3. Write the files

Fetch each file, write it at its path, and replace every `{{...}}` with the answers. When you cannot fill one, leave it out and add a line to
the open items in `docs/DOTAGENT-SETUP.md`. Never invent a command or a rule.

| Write to | Fetch from |
|---|---|
| `AGENTS.md` | `plugin/templates/AGENTS.md` |
| `.agents/skills/dotagent-ship/SKILL.md` | `plugin/templates/.agents/skills/dotagent-ship/SKILL.md` |
| `.codex/agents/reviewer.toml` | `plugin/templates/.codex/agents/reviewer.toml` (Codex only) |
| `.codex/hooks.json` | `plugin/templates/.codex/hooks.json` (Codex only) |
| `.commandcode/settings.json` | `plugin/templates/.commandcode/settings.json` (Command Code only) |
| `.dotagent/guard.py` | `plugin/hooks/guard.py` |
| `.dotagent/run.sh` | `plugin/hooks/run.sh` |
| `docs/README.md`, `CONVENTIONS.md`, `ARCHITECTURE.md` | `plugin/templates/docs/` |
| `docs/VERIFICATION.md` | `plugin/templates/docs/VERIFICATION.md` (when the user said yes) |
| `.github/PULL_REQUEST_TEMPLATE.md`, `PR_EXAMPLE.md` | `plugin/templates/.github/` |
| `.github/workflows/ci-pr.yml`, `ci-default.yml` | `plugin/templates/.github/workflows/` |
| `.githooks/pre-commit`, `commit-msg`, `pre-push` | `plugin/templates/.githooks/` (replace the commands with the repo's) |
| `docs/DOTAGENT-SETUP.md` | `plugin/templates/docs/DOTAGENT-SETUP.md` |
| `.dotagent/config.json` | `plugin/templates/.dotagent/config.json`, written with `sh .dotagent/run.sh set` |

The portable skill is the same file as `skills/dotagent-ship/SKILL.md`, do not edit it. Command Code also reads `.agents/skills/` directly,
so the same file works there without a copy step.

Then append to the repo's `.gitignore`, skipping any line already there: `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, `docs/TODO.md`.
Make the hook files executable: `chmod +x .githooks/* .dotagent/run.sh`.

Save each answer with `sh .dotagent/run.sh set <key> <value>`: `agents`, `workflow`, `setup`, `hooks`, `protected`, `commit_types`,
`commit_scope`, `merge_method`, and `base_branch`.

## 4. Turn on the git hooks

Only after the user says yes. Check `git config core.hooksPath` first. If it already points to another folder, or `.husky/`, `lefthook.yml`,
or `.pre-commit-config.yaml` exists, do not change it. Add an open item instead. Otherwise run `git config core.hooksPath .githooks`.

## 5. Check

Run the repo's build, lint, and test once. Run `.githooks/pre-commit` once, it must pass. Run `sh .dotagent/run.sh hooks`, it must print `on`.

- Codex: ask the user to open `/hooks` and trust the dotagent hooks once.
- Command Code: ask the user to start a session and confirm the `[dotagent]` capsule line appears.
- Other agents: no guard runs, so only the git hooks and CI check the work. Say so.

Then offer one tiny task as a smoke test: a one sentence diff, no plan, one PR.

## 6. Tick and commit

In `docs/DOTAGENT-SETUP.md`, tick `Written` `[x]` for each file you wrote, right after writing it. Leave `Reviewed` `[ ]`: only the user ticks it.

Commit in atomic commits, one line each, `type(scope): summary`, for example `docs(repo): add the agent rules`. No trailer, no `Co-Authored-By`,
no "Generated with" line, no `(#N)`, no plan label such as `milestone-1` or `task-2`. Stage explicit paths, never `git add -A`. Do not push.

Report what you wrote, what you skipped and why, and what the user must still decide. End with one `next:` line.

## Afterwards: shipping a task

Follow `.agents/skills/dotagent-ship/SKILL.md`. Ask the user for a yes before each push, each PR, and each merge, unless the workflow is
`auto`. The loop contract is in that file: a finish predicate, one verified unit at a time, a proof against the real artifact, and a stop
reason when it cannot move.

## Install, per agent

- **Codex:** `codex plugin marketplace add raihanpka/dotagent`, install dotagent from `/plugins`, then trust its hooks in `/hooks`.
- **Command Code:** `cmd skills add raihanpka/dotagent -s dotagent-ship`, or copy `skills/dotagent-ship/` to
  `.commandcode/skills/dotagent-ship/`. Run it as `/dotagent-ship <task>`.
- **Cursor, Antigravity, other:** `npx skills add raihanpka/dotagent --skill dotagent-ship -a codex -a antigravity-cli -y`, or copy
  `skills/dotagent-ship/` into `.agents/skills/dotagent-ship/`. Run it as `/dotagent-ship <task>`.
