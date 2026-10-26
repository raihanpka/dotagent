# Open the PR, CI, and merge

Read this before you push, open a PR, or merge, whatever the size of the task. `RUN` is defined in `SKILL.md`.

## By workflow

- **autopilot** and **checkpoint**: the steps in Merge, one branch and one PR per plan item.
- **adapt**: ask first for what is missing (one round, see Questions), then plan. Work on one branch for the whole TODO
  (`feat/<slug>`), one local commit per subtask, no push, no PR, no CI. Run the reviewer once at the end. Then ask whether to rebase
  and squash onto the default branch locally (recommended) or to leave the branch for the user, and do what they pick.

## Open the PR

Push the branch, then `gh pr create` with the PR title (a name that says what changed, see Names) and
`.github/PULL_REQUEST_TEMPLATE.md` filled by the reviewer. The body never ends with a "Generated with" line or a
trailer, a hook refuses it. Tick only what was done and delete every unchecked line.

## CI

After the push run `gh pr checks --watch`. On a failure read the failing log, fix it, push, and watch again. Never skip, weaken, or
delete a check to get green.

## Merge

The workflow mode decides who acts:

- **autopilot** (the default): push, open the PR, and merge when the reviewer said `clean` and CI is green. Fix review gaps first.
- **checkpoint**: build and commit locally as in autopilot, but before any push, PR, or merge ask the user in the chat and wait for a
  yes ("yes", "approve", "ya"). After a yes run `sh "$RUN" approve` (it covers one PR), then go on. Without it the hook asks the user itself.
- **adapt**: never push, open a PR, or merge on the remote. See By workflow.

Always rebase first, then squash. The branch sits on the latest default branch, so a stale branch or a conflict shows up on your
side, and the default branch stays linear with one commit per PR. The squash body lists each commit with its hash.

Cloud (autopilot, checkpoint), in this order:

1. `git fetch origin` and `git rebase origin/<default>`. On a conflict fix as in Limits, never `--skip` or `--abort` to hide it.
2. The rebase moved HEAD, so run the full gate once with `sh "$RUN" gate run <the repo gate>`. Then `git push --force-with-lease`, on your own branch only (the hook refuses `--force`). Wait for CI.
3. Read the PR commits now, after the rebase, because the hashes changed: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
   Also check `.commits[].messageBody` for a `Co-Authored-By`, `Signed-off-by`, or "Generated with" line. If one is there, stop and report:
   GitHub copies such a trailer into the squash commit and it cannot be removed from the default branch afterwards.
4. Merge with the lines pasted into the body as text, never a shell variable (the hook reads the command as typed):
   `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<lines>"`. The body is only those lines,
   `- <short hash> <commit subject>`, oldest first. No prose, no trailer, no tool name.
5. Switch to the default branch, pull, and check `git log -1 --format=%B` has no `Co-authored-by`. If it does, report it, never rewrite the default branch.

Local (adapt): `git rebase <default>`, the full gate once, then on the default branch `git merge --squash <branch>` and one commit,
`git commit -m "<title>"` followed by the hash lines from `git log --reverse --format='- %h %s' <default>..<branch>`. Keep the
branch, so the hashes in the body still resolve.

A commit message and a PR title never carry `(#<n>)`, GitHub adds it. A hook refuses it, and `--merge`, `--rebase`, `--admin`, `--force`,
a body that is not a commit list, and any trailer. The subject's number must be the PR you are merging. Never bypass a required check or a
required review, report it instead. If the repo does not allow squash merging (`gh repo view --json squashMergeAllowed`), stop and say so.
