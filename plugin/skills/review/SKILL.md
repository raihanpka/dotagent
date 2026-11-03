---
description: "Review a pull request, or with no argument review the unfinished work of this repo: the PRs left in docs/TODO.md and any uncommitted change. A fresh reviewer reads the diff. Nothing is pushed, merged, or posted without your choice."
argument-hint: "[<pr number or url>]"
disable-model-invocation: true
---
# dotagent review

Usage:

- `/dotagent:review <pr number or url>`: reviews one pull request, and posts only what you choose. See "With a PR".
- `/dotagent:review` with no argument: reviews the work in this repo that is not finished, for example after a cut session. It reports
  only, it posts nothing. See "Without a PR".

It never commits, pushes, merges, or switches your branch.

`RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`.

## Without a PR: the unfinished work

1. Check the state: `sh "$RUN" status` prints how many PRs in `docs/TODO.md` are unfinished (an unticked subtask, or an empty `done:` line).
   Read `docs/TODO.md` for the layout. With no `docs/TODO.md`, skip to step 3.
2. For each unfinished PR, in TODO order: its `branch:`, its subtasks (ticked and unticked), and what the branch holds. Use
   `git log --oneline <base>..<branch>`, where `<base>` is `base=` on the session line, else the default branch, and
   `gh pr list --head <branch> --json number,state` for an open PR. A branch that does not exist yet is said so, not guessed.
3. The uncommitted work: `git status --short` and `git diff`. Say what is staged and what is not, and which PR's `files:` it belongs to.
4. Review each unfinished branch and the uncommitted change with a `reviewer` subagent. Objective: check the ticked subtasks against their
   code, and the unticked subtasks against what is still missing, for that PR in `docs/TODO.md`. Output: `clean`, or a numbered list of
   gaps with `path:line` and the fix. Boundaries: read only, do not run the gate.
5. Report per PR: subtasks done, subtasks left, the gaps or `clean`, and the uncommitted state. Fix nothing here.
   `next:` `/dotagent:ship continue` resumes the work. With nothing unfinished, say so and give
   `next:` `/dotagent:ship <task>`.

## With a PR: review one pull request

1. Read the pull request: `gh pr view <pr> --json title,body,author,baseRefName,headRefName`, then `gh pr diff <pr>`. The description
   is the requirement the diff is checked against.
2. Read the code without switching branches: `git fetch origin pull/<pr>/head:review/<pr>`, then read files with
   `git show review/<pr>:<path>`. Read ranges, not whole files.
3. Spawn `reviewer` with the three lines from `ship`. Objective: review PR `<pr>` against its description, against `baseRefName`.
   Output: `clean`, or a numbered list of gaps with `path:line` and the fix. Boundaries: read only. The reviewer runs the gate only
   when you ask, CI already runs it on the PR.
4. Show the findings in the chat. Then ask with AskUserQuestion, the recommended option first: post as a comment (Recommended), request
   changes, approve, or post nothing. Approve only when the user chooses it.
5. Post what the user chose. The guard follows the workflow mode: `local` refuses it, `ask` shows a permission prompt, `auto` posts.
   - Summary only: `gh pr review <pr> --comment --body-file <file>`, or `--request-changes` or `--approve` in place of `--comment`.
   - Comments on lines: write a JSON file outside the repo with `event` (`COMMENT`, `REQUEST_CHANGES`, or `APPROVE`), `body`, and `comments`
     (each with `path`, `line`, `side`, `body`), then `gh api -X POST repos/{owner}/{repo}/pulls/<pr>/reviews --input <file>`.
6. Delete the local `review/<pr>` branch only when the user asks. Run `sh "$RUN" receipt` and put its line in the report.

End with one line `next:` that names `/dotagent:review` for the unfinished work, `/dotagent:review <another pr>`, or `/dotagent:ship <task>`.
