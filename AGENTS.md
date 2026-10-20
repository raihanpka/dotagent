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
- The PR describes the whole change. Use the PR template and delete unchecked lines.
- Merge only as far as the merge level allows. Merge subject: `<PR title> (#N)`.

## Code

- Touch only what the task needs. Note other problems, do not fix them.
- A source file stays under 350 lines. Split it in its own slice.
- A module is used through its public interface. Do not import across a module boundary.
- Do not add a dependency without asking.

## Context

- Search before reading. Read ranges, not whole large files.
- Delegate wide reading or research to a subagent and keep only its summary.
- Never edit generated files. Run the generator.

## Writing

- No em dashes. Use commas, periods, or parentheses.
- Comments and commit messages in English. Keep the one intent comment style the repo uses.
