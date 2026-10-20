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
- `style_skills` [none]: skills to invoke at the start of a run, see step 3.

Add `Workflow` to `permissions.allow` in `.claude/settings.json` so `ship.js` can start.

## 3. Interview, with the reasoning to give the user

- **Commands.** Build, lint, test, and one test file. They must run the same locally and in CI,
  or the slicer and CI will disagree.
- **Architecture style.** Ask which fits and why: modular monolith, microservices, event driven,
  or layered. Then the structure: vertical slices by feature, or horizontal layers. Record the
  answer and the reason in `ARCHITECTURE.md`. If the user is unsure, describe what the code shows.
- **Coupling.** Lead with this one. Aim for low coupling and high cohesion: a module owns one
  thing, hides its internals behind a small public interface, depends in one direction with no
  cycles, and code that two modules share goes in a shared library. Cross-module work goes through
  the interface, or a first slice that defines the contract. This is what lets a subagent edit one
  slice without reading the rest. Ask what the shared library is called and what may depend on what.
- **Check the rule against the code.** For every module, grep all its files, tests included, for
  imports of every other module's path. Write the exact command next to your claim in
  `docs/HARNESS-SETUP.md` so a human can rerun it. Never write that a rule holds without checking.
  List each existing violation as an open item and under "Current violations" in
  `ARCHITECTURE.md`, as it is today, not as the user wishes it were.
- **Boundary check.** A rule in markdown gets ignored, a lint rule fails CI. Suggest the checker
  for the language: Dart `import_lint`, Go `internal/` plus `depguard`, TypeScript
  `eslint-plugin-boundaries` or `dependency-cruiser`, Python `import-linter`, Java ArchUnit.
- **Generated files.** Path patterns and the command that regenerates them. They go in the Read
  deny list and are never edited by hand.
- **Commit scopes.** A short list, usually the module names. The format stays
  `type(scope): summary`, the scope is required.
- **Git hooks.** Offer `.githooks/commit-msg` and `pre-push` so humans follow the same rules.
  Enabling them runs `git config core.hooksPath .githooks`, so ask first.
- **CI.** Two workflows, each with one trigger, so a branch push never runs CI twice:
  - `ci-pr.yml` runs on `pull_request` only. It is the gate: format, lint, build, test, and a
    vulnerability scan if the stack has one. No services and no deploy, so it stays fast. Tell the
    user to make it a required status check in branch protection.
  - `ci-main.yml` runs on `push` to the default branch only. It holds what is too heavy for every
    PR: services, migrations, boot and health probe, integration tests. Skip it when the repo has
    nothing heavier than the gate.
  Reuse existing workflows when there are any and split them this way. Never add a `push` trigger
  for feature branches. A plain commit on a branch must not start a run.
- **Style skills.** Optional, harness works without them. Ask which the user already has. They
  only change how the agent writes replies. Install commands, only after the user agrees:
  - `caveman` for short replies: `/plugin marketplace add JuliusBrussee/caveman`
  - `ponytail:lite` for the simplest solution: `/plugin marketplace add DietrichGebert/ponytail`

## 4. Generate, then show

| File | From | When |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | always, under 60 lines, merged with existing rules |
| `CLAUDE.md` | one line, `@AGENTS.md` | when the repo has none |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/PULL_REQUEST_TEMPLATE.md` | always, with the real commands |
| `.github/PR_EXAMPLE.md` | `templates/PR_EXAMPLE.md` | always, filled with a plausible finished example |
| `.github/workflows/ci-pr.yml` | `templates/ci-pr.yml` | always, the PR gate |
| `.github/workflows/ci-main.yml` | `templates/ci-main.yml` | only when the repo has heavier checks |
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
