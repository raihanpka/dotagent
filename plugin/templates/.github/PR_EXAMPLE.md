# PR example: a finished, reviewable description

Illustrative. Keep only the lines you finished, delete unchecked boxes, and paste real evidence.

Title: `feat({{scope}}): {{what the PR adds, in one line}}`

## Summary

The board list now returns only the boards owned by the caller, so one user can no longer see another user's boards.

## Motivation

The list endpoint used the unfiltered store query. A user could read every board in the system by calling `GET /api/v1/boards`.
The fix is the owner filter at the query, not a guard in the handler.

## What changed

- Filter the board query by the caller's user id and cover it with a request test.
- Add a regression test that creates two users and asserts the list holds only the caller's board.

## Test plan

- [x] `make ci` passes
- [x] `go test -race ./internal/modules/boards -run TestListOwnBoards` passes
- [x] Runtime proof: `curl -s localhost:8080/api/v1/boards` with user A's token returns one board, not user B's
- [x] Production watch: `GET /healthz` and the 5xx rate stay at 0 for 10 minutes after the deploy

## Risk and rollback

- Risk: the query now requires an index on `owner_id`; a large board table may scan without it.
- Rollback: `git revert <sha>` and redeploy. The previous query did not need the index.

## Checklist

- [x] The title and commits say what changed, with no plan label and no `(#N)`.
- [x] The change stays inside the linked issue and does not add unrequested files.
- [x] Tests cover the change, and none were deleted, skipped, or weakened.
- [x] Docs or config are updated when behavior or setup changed.
- [x] No secret, key, or generated file is committed.
- [ ] A breaking change is named, with its migration.
