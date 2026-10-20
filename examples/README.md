# Examples

What the setup generated for a real repo, so you can see the result before you run it.

## go-backend

A Go modular monolith with 14 bounded contexts (gin, fx, sqlc, asynq). I stripped the repo of its
own `AGENTS.md`, `CLAUDE.md`, `docs/`, `.github/`, and `.githooks/`, then ran
`read SETUP.md and set dotagent up in this repo` with scripted answers: scale `medium`, merge
`off`, the commands from the Makefile, and modules as bounded contexts. It took about 2.7 minutes
and $0.51 on Sonnet, and the agent made 9 one line commits.

The folder holds only what setup wrote:

```
go-backend/
├── AGENTS.md                           # commands, modules, rules, 36 lines
├── CLAUDE.md                           # @AGENTS.md
├── .dotagent/config.json               # scale, merge, em dash, emoji, style skills
├── .claude/settings.json               # allow Workflow
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md        # the tracker, with the repo's real commands
│   ├── PR_EXAMPLE.md                   # a finished description
│   └── workflows/
│       ├── ci-pr.yml                   # the PR gate, runs on pull_request only
│       └── ci-main.yml                 # the main branch check, runs on push to main only
├── .githooks/                          # commit-msg and pre-push, for humans
└── docs/
    ├── TODO.example.md                  # what the planner writes per task, ticked by the workers
    ├── README.md  ARCHITECTURE.md  CONVENTIONS.md
    └── DOTAGENT-SETUP.md                # decisions, checks run, open items, review ticks
```

Start with `docs/DOTAGENT-SETUP.md`. It lists every file, the command behind every claim about the
code, and what is still open. In this run the agent grepped the imports and found 23 imports across modules, 13 of them reaching
into another module's inner packages. It recorded the coupling rule as not holding yet, with the
grep to rerun, instead of writing that it does.

`docs/TODO.example.md` is not setup output. The planner writes `docs/TODO.md` for every task, it is untracked and replaced by the next task, and the example shows one halfway through.

Names are changed (`acme`). It is output from one run, so read it as a sample, not a template.
