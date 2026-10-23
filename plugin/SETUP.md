# Setup

For the agent reading this. The user asked you to set up dotagent in their repo. Do it in order,
and show each file before you write it. Never overwrite a file that exists: show a diff and ask.
This holds for every row in step 4, also the rows marked "always", which means the file is offered,
not forced. An existing CI workflow, git hook, template, or doc belongs to the user. Never push or
merge anything.

**Not Claude Code** (Codex, Antigravity, or any agent that reads `AGENTS.md`). The plugin, its skills, its agents, and its guard
hook are Claude Code only, so skip step 2. Everything else still applies:
- Copy `templates/.agents/skills/dotagent-ship/SKILL.md` to `.agents/skills/dotagent-ship/SKILL.md`. Codex and Antigravity both read
  `.agents/skills/<name>/SKILL.md`. It is the plain-steps version of `/dotagent:ship`.
- Write `AGENTS.md`, `docs/`, and the `.github`, `.githooks` files from step 4 as usual. Set the git hooks on with
  `git config core.hooksPath .githooks`.
- Nothing reads `.dotagent/config.json` outside Claude Code, so write the settings in `docs/DOTAGENT-SETUP.md` instead of `run.sh set`.
- The git hooks and the PR gate are the only checks outside Claude Code. The protected paths and the plan-only rule are not enforced:
  say so in the open items.
- Ask the questions in plain text, numbered, the recommended option first (see the fallback below).
- Write nothing to `.claude/`.

Ask with AskUserQuestion. If it is not in your tool list or errors, load it with ToolSearch (`select:AskUserQuestion`) and try once
more. If it is still missing, ask in plain text: a numbered list, the recommended option first, one line of reason, then wait. In a
headless run take the recommended option and say so. Never guess an answer the setup depends on.

Steps 0 to 3 only read and ask. Do not enter Claude Code plan mode, it would block the files you
write later. Write nothing until the user has answered the rounds in step 3.

Setup runs once. If `.dotagent/config.json` and `docs/DOTAGENT-SETUP.md` both exist, stop and say:
already set up, change settings with `/dotagent:scale` and `/dotagent:workflow` or edit the file, and
delete both files to run setup again. If the config says `setup` is `minimal`, the user only went on with a
TODO before: run the full setup now and save `set setup full` at the end.

When the workflow is `adapt`, setup stays small. It skips the `.github/` rows of step 4 (CI workflows, PR template, PR example),
because nothing is pushed. It keeps the git hooks, they check every local commit, and writes `AGENTS.md`, the docs, and the config as usual.

## 0. Prerequisites

Check each with `command -v` and report what is missing. Do not install anything without asking.

| Tool | Why | Check |
|---|---|---|
| Claude Code, recent | plugins, hooks, and workflows | `claude --version` |
| Git | branches and commits | `git --version` |
| GitHub CLI `gh`, signed in | the agent opens PRs, watches CI, and merges | `gh auth status` |
| Python 3.8 or newer | runs `hooks/guard.py` through `hooks/run.sh`, which tries `python3`, `python`, then `py` | `python3 --version` or `python --version` |
| The repo's own toolchain | build, lint, and test commands | ask in step 3 |
| A GitHub remote with Actions, squash merging allowed | the PR and CI steps, and the merge is always a squash | `git remote -v`, `gh repo view --json squashMergeAllowed` |
| Node and jq (optional) | only to run dotagent's own tests | `node --version`, `jq --version` |

## 1. Look first, cheaply

Grep and read ranges, not whole files. Find: language and toolchain, default branch, the build,
lint, and test commands, an existing `AGENTS.md`, `CLAUDE.md`, CI file, PR template, git hooks,
docs, generated paths, and whether the repo is one module or many. Ask only about what you could
not find.

Match by meaning, not by file name. People name things differently and in other languages, so
`ARCHITECTURE.md`, `architectures.md`, `docs/architecture/`, `arsitektur.md`, and `design/` can all be the
architecture doc, and one folder may hold the architecture, the conventions, and more. Open the
index or the first lines of a candidate before you decide it is, or is not, what a role needs.
Do this for docs, the PR template, CI, and hooks. A role that is covered already is not generated again.

Also read how the repo names things, because an established repo has a habit and it wins: the subjects
of the last 30 commits (`git log --format=%s -n 30`), merged PR titles
(`gh pr list --state merged -L 30 --json title,headRefName`), and branch names (`git branch -r`).
Note the scope words, the branch prefix, and whether PR titles carry a type. Also read the CI
inventory: every file in `.github/workflows/`, its `on:` triggers, `gh workflow list --all` for
disabled ones, and commented or `if: false` jobs.

## 2. Install the plugin

```
/plugin marketplace add raihanpka/dotagent
/plugin install dotagent@dotagent
```

Settings live in one file, `.dotagent/config.json`, local to the machine and ignored by git. Setup writes it with
`sh hooks/run.sh set <key> <value>`, the same command behind `/dotagent:scale` and
`/dotagent:workflow`. Unset means the value in brackets.

- `scale` [medium]: `small` for a solo or tiny repo, `medium` for most, `large` for many modules
  or a team.
- `workflow` [autopilot]: `autopilot`, `checkpoint`, or `adapt`, see round 1. Say what each does in a sentence.
- `em_dash` [block] and `emoji` [block]: the agent writes neither, the default. Set `allow` only when the user asks. It stops the
  agent from writing either into files, commits, and PR text.
  No skill or template states this as a rule, the config is the only place.
- `style_skills` [none]: comma separated skills to invoke at the start of a run, see step 3.

Add `Workflow` to `permissions.allow` in `.claude/settings.json` so `ship-large.js` can start.

## 3. Grill the user, in rounds

Interview the way the `grill-me` skill does ([aihero.dev/skills-grill-me](https://www.aihero.dev/skills-grill-me)),
so the user ends with a shared understanding and no unstated assumption.

- **Rounds, not a list.** Each round asks the whole *frontier*: every question whose prerequisites
  are already settled, at most 4 per AskUserQuestion call. Never ask what depends on an answer you
  do not have yet.
- **Answer from the repo first.** Anything step 1 found is not asked. Show it as the recommended
  option and let the user confirm or change it.
- **Every question carries a recommended answer** with the reason in one line, marked
  `(Recommended)` and listed first.
- **Stop when the frontier is empty:** every branch is settled or recorded as an open item. A
  question that talking cannot answer goes to open items, do not prototype.
- **Count rounds, not questions.** More than 3 rounds means the scope is too wide, narrow it.

### When the user is unsure

Some users do not know the answer, for example what their architecture is called. That is fine, do
not stall and do not quiz them. Tell them, in a sentence, that you will suggest, then suggest. What you
suggest depends on the repo:

- **An established repo** (real history, many files, a working structure): the code already has an
  answer. Describe what you found, name it, and record it as it is today. Do not propose a new
  architecture or a rewrite. A repo this size has an owner who can answer the other questions, so ask
  them plainly and trust the answer, a big repo means they know it.
- **A new or nearly empty repo:** there is nothing to read, so recommend. Pick the simplest
  architecture and structure that fit the project, its size, its stack, and how many people will work
  on it (usually a modular monolith with vertical slices for one team, split services only when the
  need is proven). Give the best practice and the reason in two lines, and ask whether they agree. They
  can change it, record what they choose.
- **Any other question they cannot answer** (scale, workflow, CI split, scopes): give the
  recommended option from the repo and the best practice behind it, and go on. A guess goes to open items
  in `docs/DOTAGENT-SETUP.md` when it is a guess and not something you checked.

Say which of the two cases you are in before you recommend, so the user knows why.

Round 1 (no prerequisites):
- **Commands.** Build, lint, test, and one test file. For a repo with many modules also the lint and test of one module, so a worker checks only its module and the full gate runs once before the PR. They must run the same locally and in CI,
  or the worker and CI will disagree.
- **Architecture style.** Modular monolith, microservices, event driven, or layered, then vertical
  slices by feature or horizontal layers. Record the answer and the reason in `ARCHITECTURE.md`.
  If the user is unsure, see When the user is unsure: describe what the code shows in an established
  repo, recommend a simple architecture in a new one.
- **Scale.** `small`, `medium`, or `large` (the default for runs). Recommend `medium`.
- **Workflow.** `autopilot` (pushes, opens each PR, merges when the review is clean and CI is green, goes on), `checkpoint` (the same, but asks for a yes in the chat before any push, PR, or merge), or `adapt` (asks first, minimal setup, one local branch, never pushes). Recommend `autopilot` only when `ci-pr.yml` is a required status check, else `checkpoint`.

Round 2 (needs the architecture and the commands):
- **Coupling.** Aim for low coupling and high cohesion: a module owns one thing, hides its
  internals behind a small public interface, depends in one direction with no cycles, and code that
  two modules share goes in a shared library. Cross-module work goes through the interface, or a
  first PR that defines the contract. This is what lets a subagent edit one subtask without reading
  the rest. Ask what the shared library is called and what may depend on what.
- **Naming.** Follow what step 1 found: the repo's scope words, branch prefix, and PR title style, as
  the recommended answer, and record them in `AGENTS.md`. Only a new repo gets a fresh list, usually the
  module names. The hook needs `type(scope): summary` for a commit and `type: summary` or
  `type(scope): summary` for a PR title. If the repo's habit does not fit that, say so and ask
  whether to adopt it, do not silently change the habit. A name never carries a plan label: no
  `milestone-1`, `task-2`, `slice 3`, and no "finishing task". Say what changed. Tell the user.
- **Trailers.** Do not ask. A commit or PR carries no Co-Authored-By trailer and no "Generated with" line, the hook and `.githooks/commit-msg` refuse them.
- **Protected paths.** Files no agent should edit even when the task seems to need it: migrations, CODEOWNERS, lockfiles, secrets, deploy config. Recommend what the repo has. Save them with `sh hooks/run.sh set protected "<glob>,<glob>"`.
- **Generated files.** Path patterns and the command that regenerates them. They are never edited by
  hand, the rule goes in `AGENTS.md`. Do not block reading them, debugging needs it.
- **Default branch.** Find it (`git symbolic-ref refs/remotes/origin/HEAD`, or `gh repo view --json defaultBranchRef`).
  A repo may merge PRs into another branch such as `dev`: ask which branch PRs target and use that
  one as `{{default-branch}}` everywhere. Never write `main` unless the repo says so.
- **CI.** Two workflows, each with one trigger, so a branch push never runs CI twice:
  - `ci-pr.yml` runs on `pull_request` only. It is the gate. What a PR check usually holds, in order
    of cost: format check, lint (and type check where the language has one), build, unit tests, a
    dependency vulnerability scan, and a secret scan (for example gitleaks). Format, lint, build, and
    test are the minimum. Add the scans when the stack has a tool, and record the ones left out as
    open items. Keep it under about 10 minutes, with no services and no deploy. Slow, flaky, or
    secret-dependent checks go to the default branch workflow. Tell the user to make it a required
    status check in branch protection, with "require branches to be up to date".
  - `ci-default.yml` runs on `push` to the default branch only. It holds what is too heavy for every
    PR: services, migrations, boot and health probe, integration tests. Skip it when the repo has
    nothing heavier than the gate.
  - **Titles.** The workflow `name:` has a fixed prefix and suffix and one `{{ }}` slot you fill:
    `Pull Request {{ }} Gate` and `Default Branch {{ }} Check`. Fill the slot with one plain word
    for the stack or the product (`Go`, `Web`, `Billing`), never a joke or a slogan.
  Existing CI is the user's. Never rewrite, rename, or delete a workflow. When one already runs on
  `pull_request` with format, lint, build, and test, it is the gate: say so, recommend not adding
  `ci-pr.yml`, and record its name in `AGENTS.md`. When a file of the same name exists, show a diff
  and ask. Suggest a trigger change as a diff, never apply it unasked. Never add a `push` trigger
  for feature branches. A plain commit on a branch must not start a run.
  **Ask about activation.** When step 1 found a workflow that exists but does not run on pull
  requests (no `pull_request` trigger, disabled in `gh workflow list --all`, or its jobs commented out),
  ask with AskUserQuestion whether to turn it on for PRs. Recommend yes when it already runs format,
  lint, and test. Show the exact diff (the `on:` block, or `gh workflow enable`), and apply it only after
  the answer. Say which jobs would then become required checks.
- **Format.** The command that fixes formatting and the one that only checks it. Both are used: the worker runs the fixer, the git hook and CI run the checker.
- **Git hooks, part of setup.** Recommend all three, and recommend turning them on: `.githooks/pre-commit`
  (format check and lint), `commit-msg`, and `pre-push` (format, lint, build, test). Unlike the agent hook, git
  hooks check every commit and push by anyone: the agent, a person, a script, another tool. That is the
  protection for everything outside the agent's own edits, so a forgotten format or lint is caught before the
  commit and the push, and CI stays green. In a big repo make `pre-commit` check only the staged files when the tools allow, and keep the whole repo for `pre-push`. First check `git config core.hooksPath`, `.husky/`,
  `lefthook.yml`, and `.pre-commit-config.yaml`. When one exists, the repo has its own hooks: do
  not change `core.hooksPath` and do not write `.githooks`, add an open item instead. When
  `.githooks` exists, show a diff per file. Turning them on runs `git config core.hooksPath .githooks`, a local
  and reversible change, so confirm it once with the answer (Recommended) first. Say that a repo that ships
  `.githooks` but has them off gets no check at all, and that every later `/dotagent` run checks this again.

Round 3 (needs the answers above):
- **Style skills.** Optional, dotagent works without them. Ask which the user already has. They
  only change how the agent writes replies. Install commands, only after the user agrees:
  - `caveman` for short replies: `/plugin marketplace add JuliusBrussee/caveman`
  - `ponytail:lite` for the simplest solution: `/plugin marketplace add DietrichGebert/ponytail`
- **Em dash and emoji.** Do not ask. The agent writes neither by default. Set `allow` (with `sh hooks/run.sh set em_dash allow`, and `emoji`) only when the user asks for them.

Between rounds, run the checks the answers make possible:
- **Check the rule against the code.** For every module, grep all its files, tests included, for
  imports of every other module's path. Write the exact command next to your claim in
  `docs/DOTAGENT-SETUP.md` so a human can rerun it. Never write that a rule holds without checking.
  List each existing violation as an open item and under "Current violations" in
  `ARCHITECTURE.md`, as it is today, not as the user wishes it were.
- **Boundary check.** A rule in markdown gets ignored, a lint rule fails CI. Suggest the checker
  for the language: Dart `import_lint`, Go `internal/` plus `depguard`, TypeScript
  `eslint-plugin-boundaries` or `dependency-cruiser`, Python `import-linter`, Java ArchUnit.

After the rounds, save `sh hooks/run.sh set setup full` and write the workflow settings with `sh hooks/run.sh set scale <v>` and
`set workflow <v>` (and `set style_skills <list>` when chosen).

## 4. Generate, then show

Check every target path first, `git ls-files` and the disk, and check the role by meaning too (step 1).
If a file or a doc that fills the role exists, do not write ours: merge or show a diff and ask. Put new
content in the existing doc's own language and structure. A PR template under another name or folder
(`pull_request_template.md`, `docs/`, repo root) counts as existing.

`plugin/templates/` mirrors the target repo path for path: the template for `.github/workflows/ci-pr.yml` is
`templates/.github/workflows/ci-pr.yml`, and so on. Generate each file from the template at its own path.

| File | From | When |
|---|---|---|
| `AGENTS.md` | `templates/AGENTS.md` | always, under 60 lines, merged with existing rules |
| `.agents/skills/dotagent-ship/SKILL.md` | `templates/.agents/skills/dotagent-ship/SKILL.md` | always, so Codex and Antigravity can ship the same way |
| `CLAUDE.md` | `templates/CLAUDE.md`, one line, `@AGENTS.md` | when the repo has none |
| `.github/PULL_REQUEST_TEMPLATE.md` | `templates/.github/PULL_REQUEST_TEMPLATE.md` | always, with the real commands |
| `.github/PR_EXAMPLE.md` | `templates/.github/PR_EXAMPLE.md` | always, filled with a plausible finished example |
| `.github/workflows/ci-pr.yml` | `templates/.github/workflows/ci-pr.yml` | always, the PR gate |
| `.github/workflows/ci-default.yml` | `templates/.github/workflows/ci-default.yml` | only when the repo has heavier checks |
| `.githooks/pre-commit`, `commit-msg`, `pre-push` | `templates/.githooks/` | when the user said yes |
| `docs/README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` | `templates/docs/` | only a role the repo does not cover yet, matched by meaning (see step 1), so an `architectures/` folder or an `arsitektur.md` counts as the architecture doc. For one that exists, show the new section (architecture style, coupling, current violations) as an addition and ask, never replace |
| `docs/DOTAGENT-SETUP.md` | `templates/docs/DOTAGENT-SETUP.md` | always, so a human can track it |
| `.dotagent/config.json` | `templates/.dotagent/config.json`, written with `run.sh set` | always |
| `.gitignore` (repo root) | append `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, and `docs/TODO.md`, so none of dotagent's own files show up as untracked and nobody has to be shy about them. Skip a line already present, and skip any path that has tracked files (`git ls-files <path>`), such as a team `.claude/settings.json`. Do it without asking, then tell the user which lines you added and which you skipped | append, never overwrite |
| `.claude/settings.json` | `templates/.claude/settings.json`: allow `Workflow` for the large scale | merge into any existing file, show the diff first, keep every existing key |

`docs/TODO.md` is not generated here. The planner writes it for each task from `templates/docs/TODO.md`:
one section per PR, each with subtasks that the workers tick. It is ignored by git on purpose, a scratch report.

Write each file from what you found in the repo. Never invent a command, a module, or a rule.
When you cannot find something, leave the `{{...}}` out of the file and add a line to the open
items in `docs/DOTAGENT-SETUP.md`.

## 5. Prove it

Run build, lint, and test once. Check the git hooks are on with `sh hooks/run.sh hooks`, it must print `on`,
then run `.githooks/pre-commit` once to see it pass. Run `bash tests/hooks.test.sh` from the dotagent checkout
if it is available. Offer one tiny task on `scale=small` as a smoke test.

## 6. Commit and report

Commit the generated files in atomic commits, one line each, scope required, for example
`docs(dotagent): add the PR template and example`. Stage by explicit path, never `git add -A`, so
the user's own uncommitted work stays out. Ignored files are not committed. Do not push. Then list what you wrote, what you
skipped, and what the user must still decide. The user ticks each file in `docs/DOTAGENT-SETUP.md`
as they review it.

End with one line `next:` that names the first thing to try, for example `/dotagent:ship <a small task>` as a smoke test.
