# Setup

For the agent reading this. The user asked you to set up harness in their repo. Do it in order,
ask one question at a time with AskUserQuestion, and show each file before you write it. Never
overwrite a file that exists: show a diff and ask. Never push or merge anything.

## 0. Prerequisites

Check each with `command -v` and report what is missing. Do not install anything without asking.

| Tool | Why | Check |
|---|---|---|
| Claude Code, recent | plugins, hooks, and workflows | `claude --version` |
| git | branches and commits | `git --version` |
| GitHub CLI `gh`, signed in | the agent opens PRs, watches CI, and merges | `gh auth status` |
| python3 | runs `hooks/guard.py` | `python3 --version` |
| the repo's own toolchain | build, lint, and test commands | ask in step 3 |
| a GitHub remote with Actions | the PR and CI steps | `git remote -v` |
| node and jq (optional) | only to run harness's own tests | `node --version`, `jq --version` |

## 1. Look first, cheaply

Grep and read ranges, not whole files. Find: language and toolchain, default branch, the build,
lint, and test commands, an existing `AGENTS.md`, `CLAUDE.md`, CI file, PR template, git hooks,
docs, generated paths, and whether the repo is one module or many. Ask only about what you could
not find.

## 2. Install the plugin

```
/plugin marketplace add raihanpka/harness
/plugin install harness@harness
```

Options (`/plugin configure harness@harness`). Unset means the value in brackets.

- `scale` [medium]: `small` for a solo or tiny repo, `medium` for most, `large` for many modules
  or a team.
- `merge` [off]: `off`, `on-green`, or `full`. Recommend `off` first.
- `em_dash` [block]: `block` or `allow`.
- `plan_skill`, `build_skill`, `style_skills` [none]: optional companions, see step 3.

Add `Workflow` to `permissions.allow` in `.claude/settings.json` so `ship.js` can start.

## 3. Interview, with the reasoning to give the user

- **Commands.** Build, lint, test, and one test file. They must run the same locally and in CI,
  or the slicer and CI will disagree.
- **Modules.** A module owns one thing, exposes a small public interface, and imports only what
  you list. No cycles. Cross-module work goes through the interface, or a first slice that
  defines the contract. This lets a subagent edit one slice without reading the rest.
  Check the stated rule against the code: for every module, grep all its files, tests included,
  for imports of every other module's path. Record the exact command next to your claim in
  `docs/HARNESS-SETUP.md` so a human can rerun it. Never write that a rule holds without checking. List each existing violation as an open item in `docs/HARNESS-SETUP.md`
  and describe it in `ARCHITECTURE.md` as it is today, not as the user wishes it were.
- **Boundary check.** A rule in markdown gets ignored, a lint rule fails CI. Suggest the checker
  for the language: Dart `import_lint`, Go `internal/` plus `depguard`, TypeScript
  `eslint-plugin-boundaries` or `dependency-cruiser`, Python `import-linter`, Java ArchUnit.
- **Generated files.** Path patterns and the command that regenerates them. They go in the Read
  deny list and are never edited by hand.
- **Commit scopes.** A short list, usually the module names. The format stays
  `type(scope): summary`, the scope is required.
- **Git hooks.** Offer `.githooks/commit-msg` and `pre-push` so humans follow the same rules.
  Enabling them runs `git config core.hooksPath .githooks`, so ask first.
- **CI.** Reuse the existing file when there is one. Otherwise start from `templates/ci.yml`.
  One run per pull request, under 20 minutes.
- **Companion skills.** Ask which the user already has installed. They are optional, harness
  works without them. Install commands, only after the user agrees:
  - `caveman` for short replies: `/plugin marketplace add JuliusBrussee/caveman`
  - `ponytail:lite` for the simplest solution: `/plugin marketplace add DietrichGebert/ponytail`
  - `agent-skills` for plan and build: `/plugin marketplace add addyosmani/agent-skills`, then use
    `agent-skills:planning-and-task-breakdown` as `plan_skill` and
    `agent-skills:incremental-implementation` as `build_skill`

## 4. Generate, then show

| File | From | When |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | always, under 60 lines, merged with existing rules |
| `CLAUDE.md` | one line, `@AGENTS.md` | when the repo has none |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/PULL_REQUEST_TEMPLATE.md` | always, with the real commands |
| `.github/PR_EXAMPLE.md` | `templates/PR_EXAMPLE.md` | always, filled with a plausible finished example |
| `.github/workflows/<name>.yml` | `templates/ci.yml` | only when there is no CI |
| `.githooks/commit-msg`, `pre-push` | `templates/githooks/` | when the user said yes |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | missing files only |
| `docs/HARNESS-SETUP.md` | `templates/HARNESS-SETUP.md` | always, so a human can track it |
| `.claude/settings.json` | allow `Workflow`, deny reads of generated paths | merge into any existing file |

Write each file from what you found in the repo. Never invent a command, a module, or a rule.
When you cannot find something, leave the `{{...}}` out of the file and add a line to the open
items in `docs/HARNESS-SETUP.md`.

## 5. Prove it

Run build, lint, and test once. Run `bash tests/hooks.test.sh` from the harness checkout if it is
available. Offer one tiny task on `scale=small` as a smoke test.

## 6. Commit and report

Commit the generated files in atomic commits, one line each, scope required, for example
`docs(harness): add the PR template and example`. Do not push. Then list what you wrote, what you
skipped, and what the user must still decide. The user ticks each file in `docs/HARNESS-SETUP.md`
as they review it.
