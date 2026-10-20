# dotagent

🚢 A minimalist agent swarm workflow for Claude Code that gets the job done: **clear requirements in, clean pull request out, merge, and ship.**

New skills and plugins show up every week, and most of us maybe feel it: you install five, forget what
each does, and the setup gets heavier than the work. So I made my own, *small on purpose*, built
on engineering habits I trust. I want to share it, but it only works once you adapt it to your
repo. The generic parts are here, the parts that depend on your code are yours to fill in.

![the dotagent workflow](docs/workflow.svg)

## what it is for

- Shipping when the requirements are **already clear**: plan, atomic commits, a fresh-context
review, a PR, and CI. 
- *Not suitable* for ideation, diagrams, or exploring a codebase, use other skills for
that and bring the result here.

## prerequisites

[Claude Code](https://code.claude.com) (recent), `git`, [`gh`](https://cli.github.com) signed in,
`python3` (runs the hooks), your repo's toolchain, and a GitHub remote with Actions.

## install
```bash
claude
/plugin marketplace add raihanpka/dotagent
/plugin install dotagent@dotagent
/dotagent:setup     # once per repo
```

`/dotagent:setup` reads your repo, asks a few questions (commands, architecture and coupling,
commit scopes, CI, git hooks), shows each file before writing it, and ends with
`docs/DOTAGENT-SETUP.md`, a checklist to tick as you review. See `examples/` for the output.

**Prefer to do it by hand?** No Claude Code, or no wish to install a plugin? Copy from `plugin/`
and edit:

| Copy | To your repo | Edit |
|---|---|---|
| `plugin/AGENTS.md`, `plugin/templates/AGENTS.md` | `AGENTS.md` | commands, modules, scopes |
| `plugin/templates/PULL_REQUEST_TEMPLATE.md`, `PR_EXAMPLE.md` | `.github/` | the check commands |
| `plugin/templates/ci-pr.yml`, `ci-main.yml` | `.github/workflows/` | setup step, commands |
| `plugin/templates/githooks/` | `.githooks/` | then `git config core.hooksPath .githooks` |
| `plugin/templates/docs/` | `docs/` | architecture, conventions |

Fill every `{{...}}`. `plugin/SETUP.md` lists the questions worth answering.

The hooks and agents need Claude Code, the files above work anywhere.

## use it
```
/dotagent add the billing endpoint. requirements from product: <paste them>
/dotagent fix the grpc connection from backend to the agents in python
/dotagent implement the new page in home page mobile app from ui designs in figma @(your figma link with mcp)
```

Everything after the command is the task, pasted requirements included. Say *plan only* to stop
after the plan. The scale word is optional and applies to that run only.

| Scale | For | What happens |
|---|---|---|
| `small` | a tiny diff | No plan. Change, check, commit, PR. |
| `medium` *(default)* | most features | Planner cuts slices, one Haiku slicer per slice, reviewer, PR. |
| `large` | many modules, a team, unattended | Same steps run by the `ship-large` workflow: limits enforced in code, resumable. *Falls back to `medium` without the Workflow tool.* |

Defaults live in `/plugin configure dotagent@dotagent`: `scale=medium`, `merge=off`,
`em_dash=block`, `emoji=block`, `style_skills=none`.

**The team:** Sonnet plans and reviews, Haiku slicers build, *each slice is one subagent*, one at
a time. Git, `gh`, and CI are plain commands.

**Limits, kept small to keep runs cheap:** at most 8 slices and about 400 changed lines per PR
(bigger is two tasks). A failure gets *one Haiku try, one Sonnet try*, then it stops and reports.
Merge levels: `off` (default), `on-green`, `full`.

**Hooks, not prompts, enforce:** one-line `type(scope): summary` commits with no trailer, PR title
format, the merge level, no em dash or emoji, and no whole read of a file over 500 lines.

## skills i use around it

[`idea-refine`](https://github.com/addyosmani/agent-skills/tree/main/skills/idea-refine) to shape
an idea, other skills for diagrams or exploring. List style skills like `caveman` or
`ponytail:lite` in `style_skills`. The planner and slicer already carry the fitting parts of
[`planning-and-task-breakdown`](https://github.com/addyosmani/agent-skills/tree/main/skills/planning-and-task-breakdown)
and [`incremental-implementation`](https://github.com/addyosmani/agent-skills/tree/main/skills/incremental-implementation),
so those are not companions.

## structure
```
dotagent/
├── .claude-plugin/marketplace.json   # points at plugin/, only plugin/ is downloaded
├── plugin/                           # everything that installs
│   ├── SETUP.md  AGENTS.md           # setup interview, generic working rules
│   ├── hooks/  agents/  skills/      # guard.py, planner/slicer/reviewer, dotagent + setup
│   ├── workflows/                    # ship-large.js
│   └── templates/                    # PR template, CI, git hooks, docs
├── examples/                         # what setup generated for a real repo
├── docs/                             # PRACTICES.md, workflow diagram (svg, excalidraw)
└── tests/                            # hook tests, fake agent test for the workflow
```

`docs/PRACTICES.md` says where each rule comes from, so you can judge which to keep. After a
change run `bash tests/hooks.test.sh` and `node --test tests/ship.test.mjs`.

## bugs

Built for my own workflow. `ship-large.js` is tested against a fake agent but has *not run end to
end on a real repo yet*, and headless runs lack the Workflow tool. Found something? Open an issue.

## credits

- [Lauren Tan, How I Shipped 2000 PRs Last Month](https://youtu.be/NjoZoUm85x0)
- [Stripe, Minions](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Spotify, Portal cut Claude Code token usage by 90 percent](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90)
- [Addy Osmani, agent-skills](https://github.com/addyosmani/agent-skills)
- [caveman](https://github.com/JuliusBrussee/caveman) and [ponytail](https://github.com/DietrichGebert/ponytail)
- The Claude Code docs, and the rest listed in `docs/PRACTICES.md`
