# Open the PR, CI, and merge

Read this before you push, open a PR, or merge, whatever the size of the task. `RUN` is defined in `SKILL.md`.

## By workflow

- **auto** and **ask**: the steps in Merge, one branch and one PR per plan item.
- **local**: ask first for what is missing (one round, see Questions), then plan. Work on one branch for the whole TODO
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

- **auto** (the default): push, open the PR, and merge when the reviewer said `clean` and CI is green. Fix review gaps first, then go on to the next PR.
- **ask**: build and commit locally as in auto, but before any push, PR, or merge ask the user in the chat and wait for a
  yes ("yes", "approve", "ya"). After a yes run `sh "$RUN" approve` (it covers one PR), then go on. Without it the hook asks the user itself.
- **local**: never push, open a PR, or merge on the remote. See By workflow.

By default a merge is a squash, and `merge=merge` or `merge=rebase` on the session line means the repo merges that way (see Merge method below). A PR targets the `base=` branch when the line has one, so read `<default>` below as that branch. Always rebase first, then squash. The branch sits on the latest default branch, so a stale branch or a conflict shows up on your
side, and the default branch stays linear with one commit per PR. The squash body lists each commit with its hash.

Cloud (auto, ask), in this order:

1. `git fetch origin` and `git rebase origin/<default>`. On a conflict fix as in Limits, never `--skip` or `--abort` to hide it.
2. The rebase moved HEAD, so run the full gate once with `sh "$RUN" gate run <the repo gate>`. Then `git push --force-with-lease`, on your own branch only (the hook refuses `--force`). Wait for CI.
3. Read the PR commits now, after the rebase, because the hashes changed: `gh pr view <n> --json commits -q '.commits[] | "- \(.oid[0:7]) \(.messageHeadline)"'`.
   Also check `.commits[].messageBody` for a `Co-Authored-By`, `Signed-off-by`, or "Generated with" line. If one is there, stop and report:
   GitHub copies such a trailer into the squash commit and it cannot be removed from the default branch afterwards.
4. Merge with the lines pasted into the body as text, never a shell variable (the hook reads the command as typed):
   `gh pr merge <n> --squash --delete-branch --subject "<PR title> (#<n>)" --body "<lines>"`. The body is only those lines,
   `- <short hash> <commit subject>`, oldest first. No prose, no trailer, no tool name.
5. Switch to the default branch, pull, and check `git log -1 --format=%B` has no `Co-authored-by`. If it does, report it, never rewrite the default branch.

Local (the `local` mode): `git rebase <default>`, the full gate once, then on the default branch `git merge --squash <branch>` and one commit,
`git commit -m "<title>"` followed by the hash lines from `git log --reverse --format='- %h %s' <default>..<branch>`. Keep the
branch, so the hashes in the body still resolve.

A commit message and a PR title never carry `(#<n>)`, GitHub adds it. A hook refuses it, and `--merge`, `--rebase`, `--admin`, `--force`,
a body that is not a commit list, and any trailer. The subject's number must be the PR you are merging. Never bypass a required check or a
required review, report it instead.

## Merge method

The method is `merge=` on the session line, squash when it is missing. With `merge=merge` run `gh pr merge <n> --merge --delete-branch`, with `merge=rebase`
run `gh pr merge <n> --rebase --delete-branch`. Neither needs a subject or a commit list, and the guard refuses the other methods and `--admin`.
Rebase onto the base branch and push with `--force-with-lease` first, as for a squash, and read the commits for a trailer before you merge.
If GitHub refuses the method (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed` shows which are allowed), stop, ask the user
which one to use, and save it with `sh "$RUN" set merge_method <squash|merge|rebase>`.
