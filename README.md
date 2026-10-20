# harness

My agent workflow for Claude Code, packed so you can try it.

I write a lot of code with agents, over 200 commits on some days. This is the setup that
keeps it fast and tidy: one plan, small atomic commits, a fresh reviewer, a PR, and CI that
gets two tries. I want to share it, but it only works if you adapt it to your repo. The
generic parts are here. The parts that depend on your code, you fill in yourself.

## what's inside

A Claude Code plugin with a few hooks, three small agents, one skill, and one workflow
script. Plus a `SETUP.md` that your agent reads and uses to interview you. Check the folders
and take what's useful.

## structure
```
harness/
├── SETUP.md           # your agent reads this, asks you, then writes your files
├── AGENTS.md          # generic working rules, SETUP.md merges them into your repo's file
├── .claude-plugin/    # plugin.json and marketplace.json
├── hooks/             # guard.py: commit style, PR title, merge level, em dash, big reads
├── agents/            # planner (sonnet), slicer (haiku), reviewer (sonnet)
├── skills/ship/       # the entry point
├── workflows/         # ship.js: plan, slices, review, PR, CI
├── templates/         # PR template, CI, AGENTS.md skeleton
├── tests/             # hook tests
└── bench/             # a small latency and token benchmark
```

## install
```bash
claude
/plugin marketplace add raihanpka/harness
/plugin install harness@harness
```

Then tell your agent: `read SETUP.md and set harness up in this repo`. It looks at your repo,
asks a few questions, and shows every file before writing it.

## how it works

You give a task. Depending on `scale` the agent plans, builds one commit per slice, reviews
in a fresh context, opens the PR, and fixes CI at most twice.

- `small`: no plan, commit and PR directly.
- `medium`: planner, then one slicer per slice, then reviewer.
- `large`: the `/harness:ship` workflow does the same as a script, so it can resume.

Merging has three levels: `off`, `on-green`, `full`. Start with `off`.

Rules that must always hold are hooks, not prompts: one line commits, `type(scope): summary`
titles, no em dash, the merge level, and no whole read of a file over 350 lines. A rule in a
markdown file can be ignored, a hook cannot.

## adapt it

Your commands, your modules, your boundaries, your generated paths, and your commit scopes
are yours. `SETUP.md` asks for them. Everything else works as is, and you can delete what you
do not like. Run `bash tests/hooks.test.sh` after you change a hook.

## numbers

On one tiny task the plugin added about 1.3 s and 9 percent cost, and every commit came out in
the right format. See `bench/RESULTS.md` for the table and what was not measured.

## bugs

This is built for my own workflow. `ship.js` needs a recent Claude Code with workflows turned
on, and it has not run end to end yet: the hooks, the agents, and the skill are tested, the
workflow script is written from the docs only. If something does not work on yours, open an
issue and I will take a look.
