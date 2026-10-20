# harness

A small agent workflow for Claude Code, packed so you can try it.

There is a new skill, plugin, or workflow every week, and keeping up with them is tiring. A lot
of us feel it: you install five things, forget what each one does, and the setup gets heavier
than the work. I felt that too, so I made my own. It is small on purpose, it follows the
engineering habits I trust, and it gets the job done: take a task with clear requirements and
ship it as a clean pull request. I want to share it, but it only works if you adapt it to your
repo. The generic parts are here. The parts that depend on your code, you fill in yourself.

![the ship workflow](docs/workflow.svg)

## what it is for

harness is for shipping when the requirements are already clear. It plans the change, builds it
in atomic commits, reviews it in a fresh context, opens the PR, and gives CI two tries.

It is not for ideation, diagrams, or exploring how to improve a codebase. Use other skills for
that, then bring the result here.

## prerequisites

| Tool | Why |
|---|---|
| [Claude Code](https://code.claude.com), a recent version | plugins, hooks, workflows |
| git | branches and commits |
| [GitHub CLI](https://cli.github.com), signed in with `gh auth login` | open PRs, watch CI, merge |
| python3 | runs the hooks |
| your repo's toolchain | the build, lint, and test commands |
| a GitHub remote with Actions | the PR and CI steps |
| node and jq, optional | only to run harness's own tests |

## install
```bash
claude
/plugin marketplace add raihanpka/harness
/plugin install harness@harness
```

Then tell your agent: `read SETUP.md and set harness up in this repo`. It checks the
prerequisites, looks at your repo, asks a few questions, and shows every file before writing it.
It also writes `docs/HARNESS-SETUP.md`, a checklist you can tick as you review each file.

## use it
```
/harness:ship add the overview endpoint. requirements from product: <paste them here>
```

Everything after the command is the task, pasted product requirements included, and the planner
gets it verbatim. Say "plan only" and it stops after the plan so you can read it first.

By `scale`:

- `small`: no plan, commit and PR directly.
- `medium`: planner, then one slicer per slice, then reviewer.
- `large`: the `ship.js` workflow does the same as a script, so it can resume.

Limits: 8 slices and about 400 changed lines per PR, one Haiku slicer at a time, one retry per
slice, 2 review rounds, 2 CI rounds. Bigger work is split into two tasks. Merging has three
levels, `off`, `on-green`, `full`. Start with `off`.

Rules that must always hold are hooks, not prompts: one line `type(scope): summary` commits with
no trailer, PR title format, the merge level, no em dash, and no whole read of a file over 500
lines. A rule in a markdown file can be ignored, a hook cannot.

## skills i use around it

harness is only the shipping step and works alone. For the steps around it, use whatever fits:
[`idea-refine`](https://github.com/addyosmani/agent-skills/tree/main/skills/idea-refine) to shape
a vague idea, other skills for diagrams or for exploring how to improve a codebase. You can list
style skills like `caveman` or `ponytail:lite` in the `style_skills` option.

The planner and slicer already carry the parts of
[`planning-and-task-breakdown`](https://github.com/addyosmani/agent-skills/tree/main/skills/planning-and-task-breakdown)
and [`incremental-implementation`](https://github.com/addyosmani/agent-skills/tree/main/skills/incremental-implementation)
that fit this flow, so those two are not companions. Credit to Addy Osmani for both.

## structure
```
harness/
├── SETUP.md           # your agent reads this, asks you, then writes your files
├── AGENTS.md          # generic working rules, SETUP.md merges them into your repo's file
├── .claude-plugin/    # plugin.json and marketplace.json
├── hooks/             # guard.py: commit, PR title, merge level, em dash, big reads
├── agents/            # planner (sonnet), slicer (haiku), reviewer (sonnet)
├── skills/ship/       # the entry point
├── workflows/         # ship.js: branch, plan, slices, review, PR, CI
├── templates/         # PR template and example, PR and main CI, git hooks, docs, AGENTS.md skeleton
├── examples/          # what setup generated for a real repo
├── docs/              # PRACTICES.md, workflow diagram
├── tests/             # hook tests and a fake agent test for ship.js
└── bench/             # a small latency and token benchmark
```

## adapt it

Your commands, your modules, your boundaries, your generated paths, and your commit scopes are
yours. `SETUP.md` asks for them. Everything else works as is, and you can delete what you do not
like. `docs/PRACTICES.md` lists where each rule comes from, so you can judge which to keep. Run
`bash tests/hooks.test.sh` and `node --test tests/ship.test.mjs` after you change a hook or the workflow.

## numbers

On one tiny task the plugin added about 1.3 s and 9 percent cost. See `bench/RESULTS.md` for the
table and what was not measured.

## bugs

This is built for my own workflow. `ship.js` needs a recent Claude Code with workflows turned on.
Its control flow is tested against a fake agent, but it has not run end to end on a real repo
yet. If something does not work on yours, open an issue and I will take a look.

## credits

- [Lauren Tan, How I Shipped 2000 PRs Last Month: Trusting AI Agents](https://youtu.be/NjoZoUm85x0)
- [Stripe, Minions: one-shot, end-to-end coding agents](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Spotify, Portal: cutting Claude Code token usage by 90 percent](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90)
- [Addy Osmani, agent-skills](https://github.com/addyosmani/agent-skills): idea-refine, planning-and-task-breakdown, incremental-implementation
- [caveman](https://github.com/JuliusBrussee/caveman) and [ponytail](https://github.com/DietrichGebert/ponytail)
- The Claude Code docs on best practices, workflows, hooks, goal, plugins, and large codebases
- The rest are listed with their reasons in `docs/PRACTICES.md`
