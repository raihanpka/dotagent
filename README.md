# dotagent

A small agent loop that **verifies its own work**. Clear requirements in, one verified unit at a time, a proof against the real artifact,
a fresh review, and a stop reason when it cannot move.

Most agent setups automate a bad loop: the agent writes, the human checks, issues come back, repeat. dotagent moves the check inside the
loop. The agent runs the scoped check, drives the real artifact, logs the evidence, and only then opens the PR. When it cannot move, it
stops with one reason you can act on. A green build is not a green feature.

![the dotagent loop](docs/workflow.svg)

## install

| Agent | Install | Run |
|---|---|---|
| **Claude Code** | `/plugin marketplace add raihanpka/dotagent`, then `/plugin install dotagent@dotagent` | `/dotagent:setup`, then `/dotagent:ship <task>` |
| **Codex** | `codex plugin marketplace add raihanpka/dotagent`, install from `/plugins`, then trust its hooks in `/hooks` | follow the setup prompt below, then `$dotagent-ship <task>` |
| **Command Code** | `cmd skills add raihanpka/dotagent -s dotagent-ship` | follow the setup prompt below, then `/dotagent-ship <task>` |
| **Cursor, Antigravity, other** | `npx skills add raihanpka/dotagent --skill dotagent-ship -a codex -a antigravity-cli -y` | follow the setup prompt below, then `/dotagent-ship <task>` |

`plugin/skills/*` are the Claude Code editions. Each one names `${CLAUDE_SKILL_DIR}` once to find the plugin. The portable edition is
`skills/dotagent-ship/SKILL.md`, with no Claude-only tool or path token, for Codex, Command Code, Cursor, and other agents.

Run setup once per repo. It reads the repo, asks one short round, and writes `AGENTS.md`, the guard, the git hooks, the PR gate, and
`docs/VERIFICATION.md`, showing each file before it writes it.

```text
Set up dotagent in this repo by following the instructions here:
https://raw.githubusercontent.com/raihanpka/dotagent/main/docs/SETUP-AGENT.md
```

Skip it and `/dotagent:ship <task>` still works. The first run says which defaults it uses and asks once whether to set up first or go on
with only a TODO.

## use

```text
/dotagent add the billing endpoint. requirements from product: <paste them>
/dotagent:ship fix the board leak. repro first, then fix and prove it.
/dotagent status
/dotagent:ship continue
```

| Command | What it does |
|---|---|
| `/dotagent <task>` | The short form of `/dotagent:ship`. Alone it prints the run state and the next step. |
| `/dotagent:ship <task>` | Run the task as one loop. `continue` resumes from the recorded state. |
| `/dotagent:workflow local\|auto` | Save how far a run goes on its own. |
| `/dotagent:setup` | Set the repo up once: Claude Code, Codex, Command Code, both, or another. |
| `/dotagent:review [<pr>]` | Review a PR, or with no argument the unfinished work of this repo. Posts only what you choose. |

## the loop

```
Goal and finish -> Plan -> One unit -> Verify -> Prove -> Review -> Ship -> Progress -> next unit
                                  \-> stop: pivot, then no progress, a blocker, or budget -> report + next
```

1. **Goal.** `docs/TODO.md` starts with `goal:` and `finish:`. The finish is a command or artifact that can pass or fail. A run is done
   when it passes, not when the TODO looks empty.
2. **Plan.** One sentence diff: no plan. Otherwise the lead writes the TODO read only: one section per PR, with `files:`, `prove:`, and
   3 to 8 subtasks. Reversible points are decided and logged, not asked.
3. **One unit.** The smallest change, only the planned files, one scoped check, one commit, one tick, one `## log` row.
4. **Verify, then prove.** The scoped check proves the case. The `prove:` command drives the real artifact: run the feature, read the
   stored value, take the screenshot, compare before and after.
5. **Review.** A fresh `reviewer` checks the diff and the evidence. A behavior change proved only by the gate is a gap.
6. **Ship.** PR, CI, rebase, squash merge. The gate runs once per commit and is recorded.
7. **Progress.** `run.sh progress` records HEAD and the unfinished count. `moved` goes on. Two `same` rows are a pivot: change the idea.
   Four `same` rows are a `no-progress` stop.

A failed check gets two tries on the same hypothesis. A different hypothesis gets its own two tries. Two `same` rows are a pivot, not a
stop: change the idea and log it. Four are a `no-progress` stop. The TODO is a queue: after a merge, the next PR is the next task.
`loop.sh` runs one fresh process per PR until no PR is left or a stop fires.

For a wide verification, a competing design, or an adversarial pass, `fanout.md` covers swarm, arena, interrogate, and panel. For a release,
`production.md` covers the canary, the watch window, the rollback, and the post-release checks. The state and logs are in
[`docs/STATE.md`](docs/STATE.md).

<details>
<summary>the stop reasons</summary>

Every stop names one reason, writes it to `.dotagent/runs.jsonl`, writes a `## stopped` block in the TODO, and ends with a `next:` line.

| Reason | Fires when |
|---|---|
| `done` | The `finish:` predicate passes |
| `no-progress` | Four units in a row moved neither HEAD nor the unfinished count, after one pivot |
| `premise` | Two fixes that share one premise failed the same check |
| `needs-human` | An irreversible action, a secret, or a user-only call blocks the next unit |
| `question` | The requirement contradicts itself or the repo |
| `red-base` | The gate fails on resume or on the base branch |
| `conflict` | A rebase conflict survives two tries |
| `denied` | The workflow mode or a permission prompt refused a push, PR, or merge |
| `budget` | The unit, turn, or time budget is spent |
| `error` | A tool or CLI failed twice |
| `regression` | A post-merge `watch:` fails |

For a long plan, `sh plugin/hooks/loop.sh` runs one fresh process per PR, stops on a recorded stop or a stall, and compares HEAD and the
unfinished count after each PR. `CLAUDE_FLAGS="--max-turns 40"` caps each process.
</details>

## verification

The ladder, from cheapest to strongest:

1. Static: format, lint, types, build.
2. Scoped test: the subtask `Verify:`.
3. Runtime proof: drive the real artifact. This is the rung that proves the behavior a user gets.
4. Formal: a property over every state or input in a stated scope, when tests rarely reach the case. TLA+ for interleavings, a
   code-level verifier for every-input properties, a proof assistant when a bound is not enough.

`docs/VERIFICATION.md` keeps the feature map (what exists, how a user reaches it, what proves it works) and one row per formal property
with the tool, the covered code, the command, and the sync commit. A formal check you have never seen fail proves nothing.

## workflow

| Mode | What happens |
|---|---|
| `auto` *(default)* | Runs the whole TODO, opens each PR, watches CI, merges when the review is clean and CI is green, then starts the next PR. |
| `local` | One local branch, never pushes, never opens a PR. |

There are two modes only. A run either finishes the task end to end or keeps every commit on the machine.

<details>
<summary>settings</summary>

One file, `.dotagent/config.json`, per machine and ignored by git.

| Key | Default | Values |
|---|---|---|
| `workflow` | `auto` | `auto`, `local` |
| `agents` | unset | `claude`, `codex`, `commandcode`, `both`, `other` |
| `merge_method` | `squash` | `squash`, `merge`, `rebase` |
| `commit_types`, `commit_scope` | the default list, `required` | a comma separated list, and `optional` |
| `base_branch` | the default branch | the branch PRs target, such as `develop` |
| `em_dash`, `emoji` | `block` | `block`, `allow` |
| `style_skills` | `none` | comma separated skills |
| `protected` | empty | globs no agent may edit |
| `setup`, `hooks` | unset | answers saved once |

`sh plugin/hooks/run.sh set <key> <value>` writes one. A wrong value or a broken file means `local`, so a typo never turns pushing on.
</details>

<details>
<summary>what the hooks enforce</summary>

- one-line `type(scope): summary` commits, names that say what changed, no `milestone-1`, `task-2`, `wip`, or `(#N)`
- no `Co-Authored-By` or "Generated with" trailer, no `--no-verify`, no `--force`, no `--admin`
- push, PR, and merge follow the workflow mode
- an edit outside the PR's `files:` is refused until the path is added with a reason
- an edit or a shell write to a `protected` path is refused. A shell write is a redirect, `sed -i`, `cp`/`mv`/`rm`, or a `git`
  restore/checkout/apply/rm that names the path
- the guard sees the tool call. A script or tool that writes internally, a path built at runtime, or another agent without the hook is
  outside it; CI and branch protection are the backstop
- the guard runs in Claude Code, Codex, and Command Code; other agents get the git hooks and CI

</details>

<details>
<summary>structure</summary>

```
dotagent/
├── plugin/                     # what installs
│   ├── hooks/  agents/  skills/
│   ├── SETUP.md  SETUP-REFERENCE.md
│   └── templates/              # mirrors a repo 1:1
├── skills/dotagent-ship/       # the portable skill
├── hooks/hooks.json            # the Codex hook entry
├── scripts/  docs/  tests/
└── CHANGELOG.md
```

`docs/STATE.md` documents every `.dotagent` event. `sh plugin/hooks/run.sh log` prints the human log as TSV.

`docs/PRACTICES.md` says where each rule comes from. After a change:

```
bash tests/hooks.test.sh
node --test tests/ship.test.mjs tests/skills.test.mjs tests/marketplace.test.mjs
python3 scripts/workflow-svg.py --check
```

</details>

## known gaps

- Built for my own workflow. The guard needs Python 3.8 or newer.
- The gate record is bookkeeping the agent trusts. CI is the real check, and the proof is what the reviewer reads.
- Cursor, Antigravity, and other agents get the portable skill, the git hooks, and CI, but not the guard hook.
- Tried on Linux and macOS. Windows not tested.

**Found something?** Open an issue.

## credits

- [Lauren Tan, How I Shipped 2000 PRs Last Month](https://youtu.be/NjoZoUm85x0), and the
  [pstack skills](https://github.com/cursor/plugins/tree/main/pstack/skills): the trust pyramid, the stop-or-advance loop, the decision
  log, and "prove it works".
- [Stripe, Minions](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents)
- [Spotify, Portal](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90)
- [Addy Osmani, agent-skills](https://github.com/addyosmani/agent-skills)
- [caveman](https://github.com/JuliusBrussee/caveman), [ponytail](https://github.com/DietrichGebert/ponytail), and the Anthropic posts
  listed in `docs/PRACTICES.md`.

MIT.
