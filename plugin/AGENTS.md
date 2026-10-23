# Working rules

Generic rules for agent work. Repo facts (commands, modules, generated paths) live in the
repo's own `AGENTS.md`, which wins on any conflict.

## Workflow

- One task is one branch and one PR, cut from the default branch.
- Plan before editing when the change touches several files or modules. Skip the plan when
  you could describe the diff in one sentence. Planning is read only apart from `docs/TODO.md`,
  the untracked checklist each worker ticks as it finishes.
- When a requirement is ambiguous, suggest an answer with the reason and ask the user. Do not guess.
- Build in subtasks: change, build, lint, test, commit. Each subtask leaves the repo green.
- Prove it with a check you ran, never with "looks done". Show the output.
- Review in a fresh context before the PR. Fix at most 2 CI rounds, then report.

## Commits and PRs

- A commit is one line, `type(scope): summary`, no body, no trailer. One commit is one atomic
  change and its message describes the files it touches.
- A commit message, PR title, and merge subject say what changed. Never a plan label: no
  `milestone-1`, `task-2`, `slice 3`, `step 4`, `wip`, no "finishing task". The scope is the module.
  No trailer and no "Generated with" line, in a commit or in the PR body.
  `feat(auth): add the login route`, never `feat(milestone-1): add login`.
- Tests go with the code they cover. A refactor is its own commit, never mixed with a feature.
- The PR describes the whole change and stays reviewable in one sitting, a few hundred changed lines
  is typical and a range, not a limit. Use the PR template and
  delete unchecked lines.
- Push, open a PR, and merge only as far as the workflow mode allows. A commit and a PR title never carry `(#N)`, GitHub adds it.
  Merge with a squash. The subject is `<PR title> (#N)` with this PR's number, and the body is one line per
  commit, `- <short hash> <commit subject>`, with no trailer.

## Code

- Touch only what the task needs. Note other problems, do not fix them.
- Keep coupling low and cohesion high. A file or module has one responsibility and hides its
  internals behind a small public interface. Dependencies point one way, with no cycles.
- Code two modules share goes in a shared library, not into one module that the other reaches into.
- File size is a signal, not a rule. Most files sit near 100 to 300 lines, and one past about 500
  usually holds a second responsibility. Split by responsibility, in a subtask of its own.
- Do not add a dependency without asking.
- Never commit code you cannot explain. If a subtask is unclear, simplify it first.

## Context

- Search before reading. Read ranges, not whole large files.
- Delegate wide reading or research to a subagent and keep only its summary.
- Never edit generated files. Run the generator.

## Writing

- Comments and commit messages in English. Keep the one intent comment style the repo uses.
