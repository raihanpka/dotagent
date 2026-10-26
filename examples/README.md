# Examples

## taskboard-backend

A small Go task board API (gin, in-memory stores) with 6 modules: `auth`, `boards`, `tasks`, `labels`, `profile`, `webhooks`. It does two jobs:

- It shows what `/dotagent:setup` generates for a repo: `AGENTS.md`, the PR template and example, CI split into a PR gate and a main check, git hooks, and `docs/`.
- It is the base app of the benchmark, see [`docs/BENCHMARK.md`](../docs/BENCHMARK.md). It has one seeded bug on purpose: `GET /api/v1/boards` lists every user's boards.

```
taskboard-backend/
├── cmd/server  internal/{app,config,httpx,modules/{auth,boards,tasks}}   # the code, `make ci` is green
├── Makefile                            # build, fmt, fmt-check, lint, test, ci
├── AGENTS.md                           # commands, modules, rules
├── CLAUDE.md                           # @AGENTS.md
├── .dotagent/config.json               # workflow checkpoint, protected go.mod and go.sum
├── .github/                            # PR template, PR example, ci-pr.yml, ci-default.yml
├── .githooks/                          # commit-msg, pre-commit, pre-push
└── docs/                               # README, ARCHITECTURE, CONVENTIONS, DOTAGENT-SETUP, TODO.example
```

Start with `docs/DOTAGENT-SETUP.md`: decisions, files to review, open items.
`docs/TODO.example.md` is not setup output. The lead writes `docs/TODO.md` per task, untracked and replaced by the next task, and the example shows one halfway through.
