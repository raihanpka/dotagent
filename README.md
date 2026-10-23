# dotagent

🚢 A **minimalist agent swarm workflow** for Claude Code that gets the job done: **clear requirements in, clean pull request out, merge, and ship.**

New skills and plugins show up every week, and most of us feel it: you install five skills, forget what
each does, the setup gets heavier than the work, so you end up overwhelmed. 
So I made my own, *small on purpose*, built on engineering habits I trust. I want to share it, but it only 
works once you adapt it to your
repo. The generic parts are here, the parts that depend on your code are yours to fill in.

- Small on purpose: a few skills, three agents, one hook script, one config file.
- Habits behind each rule are listed in `docs/PRACTICES.md`, so you can judge which to keep.

![the dotagent workflow](docs/workflow.svg)

## what it is for

- Shipping when the requirements are **already clear**: like you have sprint planning from the product team, a clear scope, and a defined set of acceptance criteria, and you're ready to implement.
- **Not for** ideation, diagrams, or exploring a codebase. Use other skills for that and bring the result here.

## prerequisites

- [Claude Code](https://code.claude.com) (recent) and `git`
- [GitHub CLI](https://cli.github.com), signed in
- [Python](https://www.python.org/downloads/) 3.8 or newer (runs the hooks; `python3`, `python`, or `py` all work)
- on Windows, [Git for Windows](https://gitforwindows.org) (Claude Code needs it, and the hooks run through its `sh`)

## install

```bash
claude
/plugin marketplace add raihanpka/dotagent
/plugin install dotagent@dotagent
/dotagent:setup     # once per repo, optional
```

- `/dotagent:setup` reads your repo, then interviews you in rounds like [grill-me](https://www.aihero.dev/skills-grill-me), with a recommended answer per question. It shows every file before writing it, never overwrites one, and ends with `docs/DOTAGENT-SETUP.md`, a checklist to tick as you review.
- Skip it and `/dotagent:ship <task>` still works. The first run says which defaults it uses, asks once whether to set up first or go on with only a TODO, and saves your answer.
- See `examples/` for what setup writes.
- Not on Claude Code? Codex, Antigravity, or another agent: tell it to read `plugin/SETUP.md` first. Its section for other agents covers the install and what the git hooks still check.
  - Codex: `codex plugin marketplace add raihanpka/dotagent`, then install dotagent from `/plugins`.
  - Antigravity CLI or any agent with the skills CLI: `npx skills add raihanpka/dotagent --skill dotagent-ship -a codex -a antigravity-cli -y`.

<details>
<summary>install by hand, no plugin</summary>

Copy from `plugin/` and edit. Fill every `{{...}}`. `plugin/SETUP.md` lists the questions worth answering.

| Copy from `plugin/` | To your repo | Edit |
|---|---|---|
| `templates/AGENTS.md` (and `AGENTS.md`, the generic rules) | `AGENTS.md` | commands, modules, scopes |
| `templates/CLAUDE.md` | `CLAUDE.md` | nothing |
| `templates/.dotagent/config.json` | `.dotagent/config.json` | scale, workflow, and the rest |
| `hooks/guard.py`, `hooks/run.sh` | `.dotagent/` | nothing |
| `templates/.claude/settings.json` | `.claude/settings.json` | nothing |
| `templates/.github/PULL_REQUEST_TEMPLATE.md`, `PR_EXAMPLE.md` | `.github/` | the check commands |
| `templates/.github/workflows/ci-pr.yml`, `ci-default.yml` | `.github/workflows/` | setup step, commands |
| `templates/.githooks/` | `.githooks/` | then `git config core.hooksPath .githooks` |
| `templates/docs/` (`README.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `DOTAGENT-SETUP.md`, `TODO.md`) | `docs/` | architecture, conventions |

`plugin/templates/` mirrors your repo path for path, so what setup writes is what you copy. `docs/TODO.md` is the planner's layout, copy it only to read it.

- Hooks for the manual path only (the plugin brings its own): merge this into `.claude/settings.json`.

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "sh .dotagent/run.sh" }] }],
    "PreToolUse": [{ "matcher": "Bash|Write|Edit|Read", "hooks": [{ "type": "command", "command": "sh .dotagent/run.sh" }] }]
  }
}
```

- Ignore `.dotagent`, `.claude`, `docs/DOTAGENT-SETUP.md`, and `docs/TODO.md` (the plugin path does it for you).
- Without Claude Code, the files above and the git hooks still work. The agents and `.claude` hooks need it.

</details>

## update

```
/plugin marketplace update dotagent
/plugin update dotagent@dotagent
/reload-plugins
```

- Claude Code caches a plugin per version, so you get a change when the version in `plugin.json` goes up. `CHANGELOG.md` says what changed.
- To try the repo as it is: `claude --plugin-dir ./plugin`.
- From 0.2.x: `merge` became `workflow` (`on-green` and `full` are now `autopilot`, `off` is now `checkpoint`), and a merge is always a squash.

## use

| Command | What it does |
|---|---|
| `/dotagent <task>` | Ship the task with your saved settings. Alone it shows the settings, like `/dotagent:scale`. |
| `/dotagent:ship [small\|medium\|large] <task>` | Ship the task. The size word is for this run only. `continue` resumes unfinished work. |
| `/dotagent:workflow autopilot\|checkpoint\|adapt` | Save how a run ends, for every run. |
| `/dotagent:scale small\|medium\|large` | Save the size of a run. |
| `/dotagent:setup` | Set dotagent up in this repo, once. |

Without an argument `workflow` and `scale` show the saved settings. In the `/` menu the first one is `/dotagent:dotagent`.

```
/dotagent add the billing endpoint. requirements from product: <paste them>
/dotagent:ship large add the billing endpoint. requirements: <paste them>
```

- Everything after the command is the task, pasted requirements included. Say *plan only* to stop after the plan.
- A big task becomes several PRs and one run ships all of them in order. To go on after a stop, say `continue`.
- Each new session, `/clear`, and compact prints one line with your saved settings, so nothing is repeated.

### workflow

| Mode | What happens |
|---|---|
| `autopilot` *(default)* | Runs the whole TODO. Pushes, opens each PR, watches CI, rebases, squash merges when the review is clean and CI is green, goes on to the next PR. |
| `checkpoint` | The same run and local commits, but it asks for your yes in the chat ("yes", "approve", "ya") before any push, PR, or merge. |
| `adapt` | Asks first, sets up the minimum (no CI files, no PR template, git hooks stay), puts the whole TODO on one local branch, never pushes. |

### scale

| Size | For | What happens |
|---|---|---|
| `small` | a tiny diff | No plan. Change, check, commit. |
| `medium` *(default)* | most features | Planner writes the PRs, one Haiku worker per subtask, reviewer. |
| `large` | many modules, a team | The `ship-large` workflow, limits enforced in code. *Untried on a big repo. Falls back to `medium` without the Workflow tool.* |

### settings

One file, `.dotagent/config.json`, per machine and ignored by git (written by `run.sh set`, which adds it to `.git/info/exclude`).

| Key | Default | Values |
|---|---|---|
| `workflow` | `autopilot` | `autopilot`, `checkpoint`, `adapt` |
| `scale` | `medium` | `small`, `medium`, `large` |
| `em_dash`, `emoji` | `block` | `block`, `allow` |
| `style_skills` | `none` | comma separated skills, such as `caveman,ponytail:lite` |
| `protected` | empty | globs no agent may edit, such as `db/migrations/**,.github/CODEOWNERS` |
| `setup`, `hooks`, `big_plan` | unset | answers you gave once, saved so they are not asked twice |

- `/dotagent:workflow` and `/dotagent:scale` set two of them. Any key: `sh hooks/run.sh set <key> <value>`.
- A missing key means the default. A wrong value or a broken file means `adapt`, so a typo never turns pushing on.
- The agent cannot edit this file, only you can.

### how a run works

- The planner turns the task into PRs and each PR into subtasks, read only: it writes only `docs/TODO.md`. Ambiguity comes back as a question with a recommended answer, never a guess.
- Sonnet plans and reviews, Haiku workers build one subtask each, one at a time. A failure gets one Haiku try, then one Sonnet try, then it stops.
- A PR is reviewable in one sitting, 3 to 8 subtasks. `docs/TODO.md` is the report and the state, so a new session announces unfinished work.
- Git hooks (`pre-commit`, `commit-msg`, `pre-push`) check every commit and push by anyone, so CI stays green.
- A merge is a rebase onto the latest default branch, then a squash whose body lists each commit with its hash.

<details>
<summary>what the hooks enforce</summary>

- one-line `type(scope): summary` commits, and names that say what changed, never `milestone-1`, `task-2`, `wip`, or `(#N)`
- no `Co-Authored-By` or "Generated with" trailer in a commit, the PR body, or the squash body, and a PR whose commits carry one is not merged
- no em dash or emoji unless you set `allow`, no `--no-verify`, no `--force` (only `--force-with-lease`), no `--admin`
- push, PR, and merge follow the workflow: `checkpoint` asks first, `adapt` refuses
- while building, no edit outside the PR's `files:` list in `docs/TODO.md`, and none in a `protected` path
- no whole read of a file over 500 lines
- `sh hooks/run.sh receipt` prints which subagents really ran (`planner 1, worker 4, reviewer 1`)

</details>

## skills i use around it

- [`idea-refine`](https://github.com/addyosmani/agent-skills/tree/main/skills/idea-refine) to shape
an idea, other skills for diagrams or exploring. 
- List style skills like `caveman` or `ponytail:lite` in `style_skills`. 
- The planner and worker already carry the fitting parts of [`planning-and-task-breakdown`](https://github.com/addyosmani/agent-skills/tree/main/skills/planning-and-task-breakdown) and [`incremental-implementation`](https://github.com/addyosmani/agent-skills/tree/main/skills/incremental-implementation), so those are not companions.

## structure

```
dotagent/
├── .claude-plugin/marketplace.json   # points at plugin/, only plugin/ is downloaded
├── plugin/                           # everything that installs
│   ├── SETUP.md  AGENTS.md           # setup interview, generic working rules
│   ├── hooks/  agents/  skills/      # guard.py, planner/worker/reviewer, dotagent ship scale workflow setup
│   ├── workflows/                    # ship-large.js
│   └── templates/                    # mirrors a repo 1:1: .github, .claude, .githooks, .dotagent, docs
├── examples/                         # what setup generated for a real repo
├── CHANGELOG.md                      # versions, set only in plugin.json
├── scripts/release-notes.sh          # release notes: the CHANGELOG section plus the commits since the last tag
├── .github/workflows/release.yml     # tags and releases a version when it is bumped on main
├── docs/                             # PRACTICES.md, BENCHMARK.md, workflow diagram (svg, excalidraw)
└── tests/                            # hook tests, workflow tests
```

`docs/PRACTICES.md` says where each rule comes from, `docs/BENCHMARK.md` is the plan to measure it. After a
change run `bash tests/hooks.test.sh` and `node --test tests/ship.test.mjs`.

To release: bump `version` in `plugin/.claude-plugin/plugin.json`, add a `## <version>` section to `CHANGELOG.md`, and push to `main`. The release workflow runs the tests, tags `v<version>`, and publishes the release with that section and the commits since the last tag.

## known gaps or bugs?

- Built for my own workflow.
- Tried on small tasks, not yet on a big repo. `large` (the `ship-large` workflow) most of all.
- Tried on Windows and macOS, Python comes from the device.
- Found something? Open an issue.

## credits

- [Lauren Tan, How I Shipped 2000 PRs Last Month](https://youtu.be/NjoZoUm85x0)
- [Stripe, Minions](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Spotify, Portal cut Claude Code token usage by 90 percent](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90)
- [Addy Osmani, agent-skills](https://github.com/addyosmani/agent-skills)
- [caveman](https://github.com/JuliusBrussee/caveman) and [ponytail](https://github.com/DietrichGebert/ponytail)
- The Claude Code docs, and the rest listed in `docs/PRACTICES.md`
