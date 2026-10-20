# Setup

For the agent reading this. The user asked you to set up harness in their repo. Do it in
order, ask one question at a time with AskUserQuestion, and show each file before you write
it. Never overwrite a file that exists: show a diff and ask. Never push or merge anything.

## 1. Look first, cheaply

Grep and read ranges, not whole files. Find: language and toolchain, default branch, the
build, lint, and test commands, an existing `AGENTS.md`, `CLAUDE.md`, CI file, PR template,
generated paths, and whether the repo is one module or many. Ask only about what you could
not find.

## 2. Install the plugin

```
/plugin marketplace add raihanpka/harness
/plugin install harness@harness
```

Set the options in the dialog (or `/plugin configure harness@harness`):

- `scale`: `small` for a solo or tiny repo, `medium` for most repos, `large` for many modules
  or a team. Recommend `medium` when unsure.
- `merge`: `off` (the agent never merges), `on-green`, or `full`. Recommend `off` first.
- `em_dash`: `block` or `allow`.

Add `Workflow` to `permissions.allow` in `.claude/settings.json` so `ship.js` can start.

## 3. Interview, with the reasoning to give the user

- **Commands.** Build, lint, test, and one test file. They must run the same locally and in CI,
  or the slicer and CI will disagree.
- **Modules.** A module owns one thing, exposes a small public interface, and imports only
  what you list. No cycles. Cross-module work goes through the interface, or in a first slice
  that defines the contract. This is what lets a subagent edit one slice without reading the rest.
- **Boundary check.** A rule in a markdown file gets ignored, a lint rule fails CI. Suggest the
  checker for the language: Dart `import_lint`, Go `internal/` plus `depguard`, TypeScript
  `eslint-plugin-boundaries` or `dependency-cruiser`, Python `import-linter`, Java ArchUnit.
- **Generated files.** Path patterns, plus the command that regenerates them. They go in the
  Read deny list and are never edited by hand.
- **Commit scopes.** A short list, for example the module names. The format stays
  `type(scope): summary`.
- **CI.** Reuse the existing file when there is one. Otherwise start from `templates/ci.yml`.
  One run per pull request, under 20 minutes.

## 4. Write, then show

- `AGENTS.md` from `templates/AGENTS.md` with every `{{...}}` filled, merged with the repo's
  existing rules. Keep it under 60 lines. Drop any line the agent could learn from the code.
- `CLAUDE.md` containing only `@AGENTS.md`, if the repo has none.
- `.github/PULL_REQUEST_TEMPLATE.md` from `templates/pr.md` with the real commands.
- `.github/workflows/quality.yml` from `templates/ci.yml`, only when there is no CI.
- `.claude/settings.json`: the `Workflow` allow rule and `Read` deny rules for generated paths.

## 5. Prove it

Run build, lint, and test once. Run `claude plugin details harness` and report the token cost.
Offer one tiny task on `scale=small` as a smoke test.

## 6. Report

List what you wrote, what you skipped, and what the user must still decide.
