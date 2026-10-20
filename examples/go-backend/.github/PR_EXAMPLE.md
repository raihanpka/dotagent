# PR example: a finished tracker description

Illustrative. Keep only the lines you finished, delete unchecked boxes, and paste real output.

Title: `feat(tasks): add a due date filter to the task list`

## Summary

The task list endpoint accepts a `due_before` query parameter, so the mobile app can show overdue tasks without fetching every page.

## Type

- [x] feat (new feature)

## Changes

- Add a `ListTasksDueBefore` query in `internal/db/query` and regenerate sqlc.
- Pass `due_before` from the tasks handler through the service to the repository.
- Cover the filter in the tasks service and handler tests.

## Verification

- [x] `make build` passes
- [x] `make lint` passes
- [x] `make test` passes

```
ok  	github.com/acme/api/internal/modules/tasks/service	0.412s
ok  	github.com/acme/api/internal/modules/tasks/http	0.298s
```
