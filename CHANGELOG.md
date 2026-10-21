# Changelog

Versions follow [semver](https://semver.org). The version lives only in `plugin/.claude-plugin/plugin.json`.
Claude Code caches a plugin per version, so bump it on every change users should receive.

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
