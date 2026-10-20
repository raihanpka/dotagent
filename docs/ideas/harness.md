# harness

## Problem Statement

How might we make one small repo that carries my agent workflow (plan, atomic slices,
review, PR, CI, merge by permission level) into other people's repos, with short context
files and style rules enforced by hooks instead of requested in prompts?

## Recommended Direction

A Claude Code plugin that ships skills, hooks, and one workflow, `ship.js`. Sonnet plans
and reviews, one Haiku works one slice (build, lint, test, commit, the
`incremental-implementation` cycle), CI is retried at most 2 times, then it stops and
reports. Three merge levels: `off`, `on-green`, `full` (default `off`). A `scale` setting
(`small`, `medium`, `large`) decides which steps run, so a small repo does not pay for the
plan and swarm overhead.

Context is managed by enforcement, not advice. A PreToolUse hook blocks full reads of large
files and points to a targeted read (offset and limit, or a symbol lookup). Each plan slice
carries a contract: the files it may change, the files it may read, and the public
interface of neighbouring modules, so the Haiku worker does not explore. Routing lives in
hooks because a rule in AGENTS.md can be ignored (the Spotify Portal write-up reports the
same shift from advisory to enforced).

`SETUP.md` is read by the agent and interviews the user: language, build/lint/test
commands, default branch, `scale`, merge level, and module boundaries. From the answers the
agent writes `AGENTS.md` (`CLAUDE.md` is only `@AGENTS.md`), the PR template, and the CI
file. Repo-specific content is never shipped, only asked for.

The README keeps the voice of the dotfiles README: lowercase, short, honest. It says "i
want to share my workflow, but you have to adapt it to your repo" and ends with a `bugs`
section.

## Research Notes

Checked against the Claude Code docs (best practices, memory, plugins, workflows, hooks,
goal, agent teams, large codebases) and the most starred workflow repos.

- Superpowers (obra, about 302k stars): brainstorm, worktree, plan, subagent per task with
  review after each, TDD, code review, finish branch. Same shape as `ship.js`, but as
  skills the model follows, not a script that runs. Our edge is the deterministic script.
- claude-code-best-practice (about 68k stars) and the docs agree on the rules we keep:
  CLAUDE.md under 200 lines (we target 60), hooks for anything that must always happen,
  skill descriptions written as triggers, separate fresh context for review, `paths:`
  scoped rules for module conventions.
- Docs: "give Claude a way to verify its work" is the top rule. Our slice cycle (build,
  lint, test) is that check. `/goal` or a Stop hook gates the end of the run.
- Docs: `AGENTS.md` is read directly only when no `CLAUDE.md` exists above the working
  directory. With a `CLAUDE.md` that holds `@AGENTS.md`, both work. Imports do not reduce
  context cost, so the file itself must stay short.
- Plugins can carry `skills/`, `agents/`, `hooks/hooks.json`, and `workflows/`. A plugin's
  `settings.json` only honours `agent` and `subagentStatusLine`, so `scale` and merge level
  go in the plugin's user configuration, which hooks read as `CLAUDE_PLUGIN_OPTION_<KEY>`.
- Workflows: scripts can name a model per `agent()` call (Sonnet plan and review, Haiku per
  slice), are resumable in the session, and cap at 16 concurrent agents and 1,000 per run.
  Dedicated runs prompt for approval in manual mode, so the setup must pre-allow `Workflow`.
- Agent teams are experimental, cannot resume, and same-file edits overwrite each other, so
  they stay out.
- Stripe Minions: deterministic steps around the agent loop, at most 2 CI rounds, rules
  scoped by subdirectory. We copy all three.

## Planned Layout

```
harness/
├── README.md              # dotfiles voice, share and adapt
├── SETUP.md               # agent-read interview, asks before writing
├── AGENTS.md              # generic rules, 60 lines at most
├── .claude-plugin/        # plugin.json, marketplace.json
├── skills/                # plan, slice, review, ship (80 lines each at most)
├── agents/                # planner (sonnet), slicer (haiku), reviewer (sonnet)
├── hooks/hooks.json       # commit, em dash, pr title, read block
├── workflows/ship.js      # plan, slice loop, review, pr, ci x2
├── templates/             # pr template, ci, AGENTS.md skeleton with {{fill}}
└── docs/ideas/harness.md
```

## Key Assumptions to Validate

- [ ] The planner can cut slices without reading much code. Test on one Nata feature and
      measure plan-stage tokens. Graphify or an LSP lookup may be enough.
- [ ] PreToolUse hooks also fire for subagents inside a workflow. Test with a hook that
      rejects a multi-line `git commit`.
- [ ] A plugin can carry `workflows/` and hooks. Test by installing from a local marketplace.
- [ ] Haiku finishes a slice from the contract alone. Test on 3 real slices. Editing needs
      reliable line numbers, so the contract should name symbols or line ranges.
- [ ] A friend installs it in under 10 minutes on a clean repo.

## MVP Scope

In:
- Plugin manifest, 4 hooks (single-line commit with no trailer, no em dash, PR title
  format, large-file read block).
- One fixed limit of 350 lines per source file, the usual backend best practice. It is both
  the read block threshold and the size cap for code the agent writes, so a file that grows
  past it is split in a slice of its own. Generated files are exempt through the read deny
  list. It is not a setting.
- `ship.js`, sequential version, with `/goal` as the done condition: PR open, CI green,
  review clean, or 2 CI rounds used.
- `scale` and merge-level settings in one small file.
- `SETUP.md` interview, README in the dotfiles voice.
- Size budget for the harness itself: `AGENTS.md` at most 60 lines, each skill at most 80.

Out:
- Parallel swarm, adapters beyond a neutral `AGENTS.md`, automatic token metrics.

## Not Doing (and Why)

- Parallel swarm by file ownership: sequential gives about 80 percent of the value, parallel
  comes after the contract format is proven.
- Shipping repo-specific rules (Flutter, Go, and so on): those must come from the user.
- A separate context-map system: the slice contract plus one interview question is enough.
- Delegating edits to a cheap reader model: the Portal article found worker summaries lack
  reliable line numbers, so only reads are shunted, edits stay with the slice worker.
- Carrying the old dotfiles: they move to a new private repo.

## Open Questions

- What is the maximum slice size (file count) before the planner must split again?
- Who writes the PR body: the reviewer, or the last agent after all commits?
- Where does resume state live if the workflow stops mid CI round?
- Should the large-file read hook redirect to a Haiku bulk-reader, or only to a targeted read?
