# TODO: add comments to tasks

## requirements

- R1: POST /api/v1/tasks/:id/comments creates a comment, GET lists them oldest first.
- R2: A task the user cannot reach returns 404.
- R3: Deleting a task deletes its comments.

## decisions

- Where the code lives: a new `comments` module, as the repo has one module per feature (recommended and accepted)
- Storage: in memory behind a mutex, as the other modules do (recommended and accepted)

## PR 1: feat(comments): add task comments

branch: feat/task-comments
needs: none
covers: R1, R2, R3
files: internal/modules/comments/**, internal/app/app.go
read: internal/modules/tasks/module.go#Module, internal/app/app.go#New

- [x] 1.1 (S) `feat(comments): add the comments store`. New `internal/modules/comments/module.go` with `Comment`, the mutex guarded store, and the `Tasks` interface it needs. Verify: gofmt -w ., make build, make lint, make test.
- [x] 1.2 (M) `test(comments): cover create, list, and the 404 case`. Failing tests in `comments_test.go`. Verify: gofmt -w ., make test.
- [ ] 1.3 (M) `feat(comments): serve the comment routes`. `POST` and `GET /api/v1/tasks/:id/comments` in `module.go` until the tests pass. Verify: gofmt -w ., make build, make lint, make test.
- [ ] 1.4 (S) `feat(app): wire the comments module`. Mount it on the guarded group in `internal/app/app.go`. Verify: gofmt -w ., make build, make lint, make test.

done:

## fixes

## noticed

- `GET /api/v1/boards` lists every user's boards
