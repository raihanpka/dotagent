---
description: "Review a pull request you did not plan here: a fresh reviewer reads the diff against its description, you choose what to post, and it goes to GitHub as a review through gh. Nothing is pushed or merged."
argument-hint: "<pr number or url>"
disable-model-invocation: true
---
# dotagent review

Usage: `/dotagent:review <pr number or url>`. It reviews one pull request and posts only what you choose. It never checks the PR
out over your branch, never pushes to its branch, and never merges it.

`RUN` is `${CLAUDE_SKILL_DIR}/../../hooks/run.sh`.

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

End with one line `next:` that names `/dotagent:review <another pr>` or `/dotagent:ship <task>` for your own work.
