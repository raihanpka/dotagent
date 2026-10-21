Add comments on tasks, in a new module.

- New module `internal/modules/comments`, wired in `internal/app`, with its own tests. It reaches tasks and boards only through small interfaces, like `tasks` does with boards.
- `POST /api/v1/tasks/:id/comments` with `{"body": "..."}` creates a comment (201) and `GET /api/v1/tasks/:id/comments` lists them oldest first. A comment has `id`, `task_id`, `author_id`, `body`, `created_at`. An empty body returns 400. A task the user cannot reach returns 404.
- Deleting a task deletes its comments.
