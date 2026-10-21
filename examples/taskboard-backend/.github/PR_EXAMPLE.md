# PR example: a finished tracker description

Illustrative. Keep only the lines you finished, delete unchecked boxes, and paste real output.

Title: `feat(tasks): add a due date filter to the task list`

## Summary

The task list endpoint now accepts a `due_before` query parameter, so the app can show only the tasks that are due soon.

## Type

- [x] feat (new feature)

## Changes

- Add the `due_before` filter to the tasks list in `internal/modules/tasks`.
- Pass the filter through the tasks service and the http handler.
- Cover the filter with a service test.

## Verification

- [x] `make build` passes
- [x] `make lint` passes
- [x] `make test` passes

```text
ok  	github.com/raihanpka/taskboard/internal/modules/tasks	1.204s
0 issues.
```
