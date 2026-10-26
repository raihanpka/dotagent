# dotagent setup for agents without the plugin

For the agent reading this. Set up dotagent in the user's repo, for an agent that does not run the Claude Code plugin
(Codex, Antigravity, Cursor, or another). Do it in order. Show each file before you write it.

Never overwrite a file that exists: show a diff and ask. Never push, open a PR, or merge without the user's yes.
Never write an em dash or an emoji in a file.

Your tools may have no question tool. Ask in plain text: a numbered list, the recommended option first, one line of reason
each, then wait for the answer. Never guess an answer the setup depends on.

Raw files for this guide come from `https://raw.githubusercontent.com/raihanpka/dotagent/main/`. Fetch each with
`curl -sSf <base><path>`.

## 0. Check the tools

Run `command -v git`, `command -v gh`, and `command -v python3`. Check `gh auth status` and `python3 --version` (3.8 or newer).
Report what is missing. Install nothing without asking.

## 1. Look first

Read the repo, do not guess. Find:

- the language and the build, lint, and test commands (from the manifest or the CI file),
- the default branch: `git symbolic-ref refs/remotes/origin/HEAD`,
- an existing `AGENTS.md`, CI workflow in `.github/workflows/`, PR template, git hooks (`git config core.hooksPath`, `.husky/`, `lefthook.yml`), and docs,
- how commits are named: `git log --format=%s -n 30`.

Match a file by meaning, not by name. `architecture.md`, `docs/architecture/`, and `arsitektur.md` can all be the architecture doc.
Ask only about what you could not find.

## 2. Ask, in rounds

Round 1 (no prerequisites):

- Commands: the build, the lint, and one test command. Recommend what the repo already uses.

Round 2 (needs round 1):

- Protected paths: files no agent should edit (migrations, lockfiles, secrets, the release workflow, the license). Recommend what the repo has.
- Commit scopes: recommend the scope words from the commit history.
- Git hooks: turn them on with `git config core.hooksPath .githooks`. Recommend yes.

Round 3:

- PR gate: a workflow that runs the test command on each pull request. Recommend yes.

Recommendations come with one line of reason. Each question has a recommended answer, listed first.

## 3. Write the files

Fetch each file, write it at its path, and replace every `{{...}}` with the answers from steps 1 and 2. When you cannot fill
one, leave it out of the file and add a line to the open items in `docs/DOTAGENT-SETUP.md`. Never invent a command or a rule.

| Write to | Fetch from |
|---|---|
| `AGENTS.md` | `plugin/templates/AGENTS.md` |
| `.agents/skills/dotagent-ship/SKILL.md` | `skills/dotagent-ship/SKILL.md` (the file is the same, do not edit it) |
| `.github/PULL_REQUEST_TEMPLATE.md` | `plugin/templates/.github/PULL_REQUEST_TEMPLATE.md` |
| `.github/PR_EXAMPLE.md` | `plugin/templates/.github/PR_EXAMPLE.md` |
| `.github/workflows/ci-pr.yml` | `plugin/templates/.github/workflows/ci-pr.yml` (replace its test steps with the repo's commands) |
| `.githooks/pre-commit` | `plugin/templates/.githooks/pre-commit` (replace the checks with the repo's format and lint, or remove them) |
| `.githooks/commit-msg` | `plugin/templates/.githooks/commit-msg` (use as is) |
| `.githooks/pre-push` | `plugin/templates/.githooks/pre-push` (replace the test lines with the repo's test command) |
| `docs/ARCHITECTURE.md` | `plugin/templates/docs/ARCHITECTURE.md` |
| `docs/DOTAGENT-SETUP.md` | `plugin/templates/docs/DOTAGENT-SETUP.md` (the checklist, see step 6) |
| `.codex/agents/reviewer.toml` | `plugin/templates/.codex/agents/reviewer.toml` (Codex only, see below) |

The `.codex/agents/reviewer.toml` file is the one subagent role for Codex: it checks the diff in a fresh context before the PR. You plan and
build yourself. Write it only when you can run subagents. Agents without subagents review in a fresh pass, yourself.

Then append to the repo's `.gitignore`, skipping any line already there: `docs/DOTAGENT-SETUP.md` and `docs/TODO.md`.
Tell the user which lines you added.

Make the hook files executable: `chmod +x .githooks/*`.

## 4. Turn on the git hooks

Only after the user says yes in round 2. Check first: `git config core.hooksPath`. If it already points to another
folder, or `.husky/`, `lefthook.yml`, or `.pre-commit-config.yaml` exists, do not change it. Add an open item instead.
Otherwise run `git config core.hooksPath .githooks`.

## 5. Check

Run the repo's build, lint, and test once. Run `.githooks/pre-commit` once, it must pass.

## 6. Tick and commit

In `docs/DOTAGENT-SETUP.md`, tick `Written` `[x]` for each file you wrote, right after writing it. Leave `Reviewed` `[ ]`:
only the user ticks it.

Commit in atomic commits, one line each, `type(scope): summary`, for example `docs(repo): add the agent rules`. No trailer,
no `Co-Authored-By`, no "Generated with" line, no `(#N)`, no plan label such as `milestone-1` or `task-2`.
Stage explicit paths, never `git add -A`. Do not push.

Report to the user: what you wrote, what you skipped and why, and what the user must still decide.

## Afterwards: shipping a task

To ship a task later, follow `.agents/skills/dotagent-ship/SKILL.md`. Ask the user for a yes before each push, each
PR, and each merge.
