# Examples

What the setup generated for a real repo, so you can see the result before you run it.

## go-backend

A Go modular monolith with 14 bounded contexts (gin, fx, sqlc, asynq). I stripped the repo of its
own `AGENTS.md`, `CLAUDE.md`, `docs/`, `.github/`, and `.githooks/`, then ran
`read SETUP.md and set harness up in this repo` with scripted answers: scale `medium`, merge
`off`, the commands from the Makefile, and modules as bounded contexts. It took about 3 minutes
and $0.49 on Sonnet, and the agent made 8 commits.

The folder holds only what setup wrote:

```
go-backend/
├── AGENTS.md                           # commands, modules, rules, 26 lines
├── CLAUDE.md                           # @AGENTS.md
├── .claude/settings.json               # allow Workflow, deny reads of generated files
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md        # the tracker, with the repo's real commands
│   ├── PR_EXAMPLE.md                   # a finished description
│   └── workflows/quality.yml           # one CI run per pull request
├── .githooks/                          # commit-msg and pre-push, for humans
└── docs/
    ├── README.md  ARCHITECTURE.md  CONVENTIONS.md
    └── HARNESS-SETUP.md                # decisions, checks run, open items, review ticks
```

Start with `docs/HARNESS-SETUP.md`. It lists every file, the command behind every claim about the
code, and what is still open. In this run the agent found that five modules import other modules,
so it recorded the rule as not holding yet instead of writing that it does.

Names are changed (`acme`). It is output from one run, so read it as a sample, not a template.
