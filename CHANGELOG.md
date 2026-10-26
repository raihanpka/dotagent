# Changelog

Versions follow [semver](https://semver.org). The version lives in `plugin/.claude-plugin/plugin.json` and, equal to it, in `.codex-plugin/plugin.json`.
Claude Code caches a plugin per version, so bump it on every change users should receive.

## 0.4.0

Upgrading: `/dotagent:scale` and the `large` run are gone, and so are the planner and worker agents. A saved `scale` key in `.dotagent/config.json` is ignored, `sh hooks/run.sh set scale ...` now says why it refuses. Add nothing, run `/plugin update dotagent@dotagent` and `/reload-plugins`. If you allowed `Workflow` in `.claude/settings.json` for `ship-large.js`, you can remove it.

### One loop for every task

- `/dotagent:ship <task>` has one path. If the whole diff fits one sentence there is no plan and no TODO. Otherwise the lead writes `docs/TODO.md` read only, builds each subtask itself with one commit each, and a fresh `reviewer` checks the diff. The lead revises the plan when the work differs from it. A fix gets two tries from the lead, then the run stops.
- Why: [Anthropic's guide to folding subagents into the main loop](https://claude.com/resources/articles/building-agents-when-to-fold-subagents-into-your-main-agent-loop), and the repo's own benchmark run 1 (every arm resolved 15/15, the workflow cost 1.6x to 1.8x and took 1.5x to 1.8x longer than plain Claude Code, `large` matched `medium`). The single loop is not measured yet, `docs/BENCHMARK.md` says so.
- Every spawn (`reviewer`, `Explore`) gets an objective, an output shape, and boundaries.
- Removed: `/dotagent:scale`, the size word before a task, `plugin/workflows/ship-large.js`, `planner`, `worker`, the Codex `planner.toml` and `worker.toml`, the `Workflow` permission, and the Scale question in setup.
- `/dotagent <task>` stays as the short form of `ship`. It no longer triggers by itself, so it does not compete with `ship`.

### The gate runs once per commit

- `sh hooks/run.sh gate pass` records the HEAD the repo gate passed at, `gate check` prints `ok` or `stale` (also `stale` after an edit to a tracked file). The lead, the reviewer, and `continue` read it, so nothing runs the gate twice on one commit. `continue` checks it before any new work.

### Guards

- `rm` and `git rm` of a test file are refused (`tests/`, `__tests__/`, `x_test.go`, `x.test.js`, `x.spec.ts`, `test_x.py`). The reviewer also flags a test that was deleted, skipped, or loosened to pass.
- The workflow modes read as one ladder: `adapt` stops at local commits, `checkpoint` asks before the remote, `autopilot` goes to the merge.

### Docs

- `hooks/loop.sh` documents `CLAUDE_FLAGS="--max-budget-usd 5"` as a spend cap for each PR of a long run.
- The benchmark arms are `plain` and `dotagent`, run 1 keeps its old arms. `docs/PRACTICES.md` gains the single loop, failure mode, and long run sources, and says the 500 line read limit is a model era assumption to re-test.
- The workflow diagram, README, setup guides, and `examples/` follow the single loop. The portable ship skill drops the planner and worker steps.

## 0.3.1

Other agents can install the ship skill from the repo. Codex: `codex plugin marketplace add raihanpka/dotagent`, then install dotagent from `/plugins`. Antigravity CLI or any agent that reads `.agents/skills`: `npx skills add raihanpka/dotagent --skill dotagent-ship -a codex -a antigravity-cli -y`.

- A root `skills/dotagent-ship/SKILL.md` (same file as the template setup copies), a root `.codex-plugin/plugin.json`, and `.agents/plugins/marketplace.json` for Codex.
- `plugin/SETUP.md` gets the install commands for other agents.
- The setup checklist `docs/DOTAGENT-SETUP.md` has a Written column (the agent ticks it) and a Reviewed column (you tick it). Before, a written file still showed an unticked row.
- Claude Code users: no change in behavior.

## 0.3.0

Upgrading: `/dotagent:merge` is now `/dotagent:workflow`. An old `merge` key is read once: `on-green` and `full` become `autopilot`, `off` becomes `checkpoint`, a wrong value becomes `adapt`. Save the new key with `/dotagent:workflow`.

### Workflow modes

- `merge` is replaced by `workflow`, with three modes. `autopilot` (default) pushes, opens each PR, watches CI, merges, and goes on. `checkpoint` does the same work and local commits but asks for your yes in the chat before any push, PR, or merge; after a yes the agent runs `run.sh approve`, which covers one PR, and without it the hook asks with Claude Code's own permission prompt. `adapt` asks first, sets up the minimum, keeps every commit on one local branch, and never pushes: the hook refuses `git push` and `gh pr create` and `gh pr merge`. `full` and the old `off` are gone.
- A wrong value or a broken config file means `adapt`, the mode that sends nothing.
- In `adapt` setup skips the CI workflows, the PR template, and the PR example, and keeps the git hooks.

### Rebase, then squash

- Every merge rebases onto the latest default branch first, then squashes. Cloud: `git push --force-with-lease` on the agent's own branch, then the squash body lists the commits read after the rebase. Local (`adapt`): `git merge --squash` with the same hash list in one commit, and the branch is kept so the hashes still resolve.
- The hook refuses `git push --force` and `-f`, and allows a commit body only when every line is `- <hash> <subject>`.

### Asks, and remembers

- Skills ask with `AskUserQuestion`, load it through `ToolSearch` when it is missing, and fall back to a numbered plain text question. A headless run takes the recommended option.
- Every answer that can come back is saved: `setup` (`full`, `minimal`, `skipped`), `hooks`, and `big_plan` join `scale`, `workflow`, `protected`, and `style_skills`. The session line shows them.
- `ship` on a first run explains the defaults and asks once: set up first, or go on with only a TODO. Every skill ends with a `next:` line.
- `run.sh set` makes git ignore `.dotagent/` through `.git/info/exclude`, so the config never shows in your diff, with or without setup. The check that protects the config now compares the real path, so a copy under `examples/` is no longer refused.
- The menu description of each skill lists every option. Autocomplete shows one `argument-hint` string per skill, the docs do not describe a description per value.
- README is shorter, with install, update, and use sections.
- `ship` is 15 KB, up from 11 KB at 0.2.1. The merge flow, `adapt`, and the questions account for it.

## 0.2.2

Upgrading: merges are now squash only, see Merge is a squash. Run `/plugin marketplace update dotagent`, `/plugin update dotagent@dotagent`, then `/reload-plugins`. To protect paths, run `sh hooks/run.sh set protected "<globs>"`.

### Commands and first run

- `/dotagent` alone now does what `/dotagent:scale` does: it shows the scale, or saves it when you add `small`, `medium`, or `large`. Any other words are a task and go to `ship`. To resume unfinished work, say `continue` or run `/dotagent:ship`.
- The session line is the "learn" step. It prints on a new session, after `/clear`, and after a compact, read from the project config file, so the agent gets the saved scale, merge level, style skills, and protected paths back in one line, with no memory file and no extra context. Unfinished PRs are announced the same way.
- First run: when the config file does not exist yet, the hook adds one line with the number of tracked files and top-level folders. `ship` then tells you in two lines the scale it uses and why, that each PR merges by itself when the review is clean and CI is green and the run goes on until every PR is merged or a stop, and how to change it. It saves both choices and goes straight to the task.
- `/dotagent:merge` and `/dotagent:scale` are the place for the merge rule and the scale. They are saved for every later run, so `ship` does not repeat them.

### Guardrails and proof for big repos

- Receipt: a hook logs every subagent spawn, and `sh hooks/run.sh receipt` prints `subagents: planner 1, worker 4, reviewer 1` for the session. `ship` puts it in its report, so a run that built everything itself is visible. In the 60 benchmark runs the workers ran in only 5 of 30 `medium` and `large` runs and Haiku was about 2% of the spend, so this is how the claim gets checked.
- Scope: the planner writes a `files:` line per PR, and while building a hook refuses an edit outside it. It catches accidental drift, not a determined agent, since the TODO stays writable.
- Protected paths: the `protected` setting (globs, set with `run.sh set protected`) is refused for any edit, in any phase. Setup asks for migrations, CODEOWNERS, lockfiles, and similar. Shell writes are not covered.
- Scoped checks: `AGENTS.md` gets a one-module lint and test line and entry points per module. Workers verify only their module, `ship` runs the full gate once before the PR, and setup suggests a `pre-commit` that checks staged files only.
- Fresh context per PR: `hooks/loop.sh` runs one `claude -p` per unfinished PR, resumed from `docs/TODO.md`. A subagent cannot start subagents, so a PR cannot be handed to one.
- Speed: the agents and `ship` name the native tools (Grep, Glob, Read ranges, parallel calls, `Explore` for a wide read, background CI watch) instead of shell.
- Hook tests: 128 cases. `ship` grew from 11.0 to 12.8 KB.
- The benchmark app grew to 6 modules (`labels`, `profile`, `webhooks` added) and three harder tasks, `t6-members-roles`, `t7-task-labels`, `t8-list-race`. Graders run with `-race`. Not run, the weekly quota is spent.

### Merge is a squash

- The only merge is `gh pr merge --squash`. A merge commit and a rebase are refused by the hook. Before, squash was refused because it folds the atomic commits.
- The squash body lists every commit, one line each, `- <short hash> <commit subject>`, taken from `gh pr view --json commits`. The hook refuses any other body line, a body file, an empty body, and any trailer.
- The subject is still `<PR title> (#N)` with this PR's number.
- No AI co-author in the squash commit: `ship` first checks that no commit of the PR carries `Co-Authored-By`, `Signed-off-by`, or a "Generated with" line, and does not merge if one does, because GitHub copies such a trailer into the squash commit and it cannot be removed from the default branch afterwards. After the merge it checks `git log -1 --format=%B` and reports a trailer instead of rewriting history.
- Setup checks that the repo allows squash merging.
- Hook tests: 113 cases.

## 0.2.1

Hotfix for `/dotagent:setup`: it must not overwrite what the repo already has.

- Every file in step 4 is checked against `git ls-files` and the disk first. A file that exists is merged or shown as a diff and asked about, also the rows marked "always".
- Existing CI is never rewritten, renamed, or deleted. A workflow that already gates `pull_request` is kept and recorded in `AGENTS.md`, and a same-name `ci-pr.yml` or `ci-default.yml` is a diff, not a replacement.
- Git hooks: setup leaves `core.hooksPath` alone when the repo uses its own hooks (`core.hooksPath`, husky, lefthook, pre-commit), and shows a diff when `.githooks` exists.
- An existing `docs/ARCHITECTURE.md`, `CONVENTIONS.md`, or `README.md` is extended with the setup answers after approval, not skipped silently and not replaced. A PR template under another name counts as existing.
- `.gitignore`: skips lines already present and paths that have tracked files, so a team `.claude/settings.json` is not hidden. `.claude/settings.json` is merged after a diff.
- The setup commit stages explicit paths only, so the user's other uncommitted work stays out.
- Setup matches docs by meaning, not by file name: `architectures.md`, `arsitektur.md`, or an `architecture/` folder counts as the architecture doc, in any language, and new content goes in the existing doc's own language and structure.
- Setup reads the repo's own habit first (last commit subjects, merged PR titles, branch names) and follows it. It asks before it changes a habit the hook cannot accept.
- Setup asks which branch PRs target and never writes `main` unless the repo says so. The main check is now `ci-default.yml` (was `ci-main.yml`), and its trigger is the default branch.
- Setup asks whether to turn on a CI workflow that exists but does not run on pull requests, and shows the exact diff first.
- CI titles are `Pull Request {{ }} Gate` and `Default Branch {{ }} Check`, the agent fills the slot with one plain word. The PR gate lists what a PR check usually holds: format, lint, build, test, a dependency scan, a secret scan, under about 10 minutes.

### Benchmark and example

- `examples/go-backend` is now `examples/taskboard-backend`: a small gin task board with real code and a green `make ci`, plus the files setup writes. It is the base app of the benchmark.
- New `benchmark/`: 5 tasks with hidden graders, `run.sh` (one run, plain or `/dotagent:ship small|medium|large`), `report.py`, and `check-graders.sh`. `run-all.sh` runs the matrix. `docs/BENCHMARK.md` describes the method, the limits, and the first results: 60 runs, all resolved, dotagent costs about 1.6x to 1.8x plain Claude Code on these small tasks and never adds a trailer or a wrong commit subject, where plain added a trailer in 8 of 15.
- Shorter `ship` and `planner` prompts: the naming rule is stated once per file, not four times.

## 0.2.0

Upgrading: the old `/plugin configure` options are ignored. Run `/dotagent:scale` and `/dotagent:merge` once, or edit `.dotagent/config.json`.

### Commands and settings

- Added `/dotagent:ship`, `/dotagent:scale`, `/dotagent:merge`, `/dotagent:setup`. `/dotagent` runs `ship` with the saved settings.
- Checked in Claude Code 2.1.304: the menu lists `dotagent:dotagent`, `dotagent:ship`, `dotagent:scale`, `dotagent:merge`, `dotagent:setup`, the bare `/dotagent` also runs the main skill, `${CLAUDE_SKILL_DIR}` expands in skill content, and `ship-large` is not a menu entry. Only the main skill sets a `name`, the other four use their folder name so no bare `/scale`, `/merge`, `/setup`, or `/ship` takes a generic name.
- One settings file, `.dotagent/config.json`, shared by the plugin and the manual path. It is local and ignored by git. It replaces the plugin options (`userConfig`).
- A missing file or key means the default. A wrong value or a broken config means `merge` off. Before, a typo in `merge` allowed merging.
- `merge` defaults to `on-green`, so a plan with several PRs can run to the end. Set `off` to stop at every open PR. `--admin` is refused.
- The agent cannot edit the config file, only `/dotagent:scale` and `/dotagent:merge` change it.
- Em dash and emoji: the agent writes neither by default (`block`), and `allow` is set only when the user asks. No skill or template states it as a rule, the config is the only place.

### Plan, TODO, and PRs

- A task becomes one or more PRs, a PR becomes subtasks, one Haiku `worker` each (the `slicer` agent is now `worker`). One run goes through every PR of the plan in order, by itself, until all are merged or a stop is hit (a fix ladder ran out, a question is open, merge is `off` or blocked, a `needs` is unmerged). Ask once to go on when a plan has more than 6 PRs.
- Planning is read only: the planner may write only `docs/TODO.md`, enforced by a plan marker (`run.sh phase plan|build|done`) the hook checks. It clears on a new session and after an hour. No Claude Code plan mode, which would block the TODO.
- `docs/TODO.md` replaces `.dotagent/plan.md`: one section per PR with subtasks (id, size S/M/L, commit message, detail, verify), ticked by each worker. Replaced on every task. Layout in `plugin/templates/docs/TODO.md`, sample in `examples/go-backend/docs/TODO.example.md`.
- Ambiguous requirements come back as questions with options, a recommended answer, and the reason. The lead asks the user and plans again with the decisions. `ship-large` returns `stopped: questions` with `base` and `branch` and resumes from them.
- Requirements: with more than one point the planner numbers them `R1`, `R2` and each PR has a `covers:` line. An uncovered `R` becomes a question, and the reviewer checks only the `R` of the PR in hand. One point or none: no numbers.
- PR size is a range, not a limit: 3 to 8 subtasks and a few hundred changed lines. The fixed 8 slices and 400 lines are gone, a bigger task becomes more PRs. The workflow keeps a backstop of 10 subtasks per PR for cost.
- `ship` treats a one sentence diff as `small`, and one worker may take two subtasks in one module.

- Continue: say `continue` in plain words, or run `/dotagent` with no task. A new session prints `unfinished` when `docs/TODO.md` has a PR with an unticked subtask or an empty `done:`, and the agent resumes from git and `gh`, not from memory. A new task while an old one is unfinished asks first: finish the old one (recommended) or drop it. `done:` now holds the PR url once merged.
- `ship-large` takes `resume`, skips ticked subtasks, reuses the branch, and reuses an open PR.

- Format and lint before CI: new `.githooks/pre-commit` (format check and lint), `pre-push` now runs format, lint, build, and test like CI, the worker formats before it commits, and `--no-verify` on `git commit` or `git push` is refused. `AGENTS.md` gets a `Format` command.

- Git hooks are part of setup: setup writes them and turns them on after one confirmation. They cover every commit and push, by the agent, a person, or a script. A new session warns when `.githooks` exists but `core.hooksPath` does not use it, `run.sh hooks` prints `on`, `off`, or `none`, and `ship` checks it at the start and asks once before turning it on.

### Names and trailers

- Names say what changed. A commit message, PR title, or merge subject with `milestone-1`, `task-2`, `slice 3`, `step 4`, `wip`, or `finishing task` (a bare `stage 2` or `part 3` is fine) is refused by the hook and by the `commit-msg` git hook. It is in `AGENTS.md`, the planner, the worker, the reviewer, and the PR template.
- No trailer: a commit or PR body with `Co-Authored-By`, `Signed-off-by`, or a "Generated with" line is refused by the hook, and the `commit-msg` git hook checks the whole message. The reviewer never writes one into a PR body.

- A commit message and a PR title never carry `(#N)`, GitHub adds it. The hook and `commit-msg` refuse it. At merge, the commit message is one line the agent writes itself, `<PR title> (#N)` with this PR's own number and an empty body (`--body ""`), since a description would be a second line or a trailer. Squash is refused because it folds the atomic commits, rebase is allowed and has no subject. `--merge` is the default.

- Shell guards: while planning, a Bash command that writes files (redirect, `sed -i`, `tee`, `cp`, `mv`, `rm`, and git commands that rewrite the tree) is refused unless it targets `docs/TODO.md`. `.dotagent/config.json` cannot be changed from the shell either, only through `run.sh`.

### Setup and templates

- `/dotagent:setup` interviews in rounds like grill-me, recommends an answer per question, runs once per repo, and also writes the workflow settings. Its steps 0 to 3 only read and ask.
- Setup helps an unsure user: in an established repo it describes what the code shows and trusts the owner for the rest, in a new repo it recommends a simple architecture with the reason and asks whether they agree, and any other open answer gets a recommended option and the best practice behind it.
- Setup appends `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, and `docs/TODO.md` to the root `.gitignore`, without asking, so none of dotagent's files show up in the repo.
- `plugin/templates/` mirrors the target repo path for path: `.github/`, `.github/workflows/`, `.claude/`, `.githooks/`, `.dotagent/`, `docs/` (with `DOTAGENT-SETUP.md` and `TODO.md`), and root `AGENTS.md` and `CLAUDE.md`. `.claude/settings.json` only allows `Workflow`, the manual hooks block is in the README. Generated files are a rule in `AGENTS.md`, reading them is not blocked because debugging needs it.

### Fixes in `ship-large`

- The worker cap fits the worst case, the PR title is shell quoted, fixes run every subtask check, the reviewer runs the checks and confirms earlier gaps, and CI fixes may push.
- `ship` said two Haiku tries, it is one Haiku try and one Sonnet try everywhere.

### Platforms

- Hooks and commands start through `hooks/run.sh`, which finds `python3`, `python`, or `py`, so macOS, Linux, and Windows (Git for Windows) set up the same way. `guard.py` reads stdin as UTF-8 so an emoji is still seen on Windows.

### Docs

- Described as a minimalist agent swarm workflow, with `plugin.json` metadata (author, homepage, repository, keywords).
- README rewritten in short points. The workflow diagram has thinner arrows with small heads that stop short of the boxes, bold key words, and only high level descriptions.
- Added `docs/BENCHMARK.md`, the plan to measure the workflow, and rows in `docs/PRACTICES.md` for the TODO, plan before code, and names.

## 0.1.0

First release: plan, slices, review, PR, CI, merge by level, hooks, `ship-large` workflow.
