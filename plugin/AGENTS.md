# Working rules

Generic rules for agent work. Repo facts (commands, modules, generated paths) live in the
repo's own `AGENTS.md`, which wins on any conflict.

## Workflow

- One task is one branch and one PR, cut from the default branch.
- Plan before editing when the change touches several files or modules. Skip the plan when
  you could describe the diff in one sentence.
- Build in slices: change, build, lint, test, commit. Each slice leaves the repo green.
- Prove it with a check you ran, never with "looks done". Show the output.
- Review in a fresh context before the PR. Fix at most 2 CI rounds, then report.

## Commits and PRs

- A commit is one line, `type(scope): summary`, no body, no trailer. One commit is one atomic
  change and its message describes the files it touches.
- Tests go with the code they cover. A refactor is its own commit, never mixed with a feature.
- The PR describes the whole change and stays near 400 changed lines. Use the PR template and
  delete unchecked lines.
- Merge only as far as the merge level allows. Merge subject: `<PR title> (#N)`.

## Code

- Touch only what the task needs. Note other problems, do not fix them.
- Keep coupling low and cohesion high. A file or module has one responsibility and hides its
  internals behind a small public interface. Dependencies point one way, with no cycles.
- Code two modules share goes in a shared library, not into one module that the other reaches into.
- File size is a signal, not a rule. Most files sit near 100 to 300 lines, and one past about 500
  usually holds a second responsibility. Split by responsibility, in a slice of its own.
- Do not add a dependency without asking.
- Never commit code you cannot explain. If a slice is unclear, simplify it first.

## Context

- Search before reading. Read ranges, not whole large files.
- Delegate wide reading or research to a subagent and keep only its summary.
- Never edit generated files. Run the generator.

## Writing

- No em dashes. Use commas, periods, or parentheses.
- Comments and commit messages in English. Keep the one intent comment style the repo uses.
