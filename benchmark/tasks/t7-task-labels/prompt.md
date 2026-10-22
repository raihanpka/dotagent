Attach labels to tasks.

- `PUT /api/v1/tasks/:id/labels/:label_id` attaches a board label to a task (204, safe to repeat). `DELETE` on the same path detaches it. A label from another board, or a task the user cannot reach, returns 404.
- Every task in a response carries `labels`, an array of label ids (empty, never null).
- `GET /api/v1/boards/:id/tasks?label=<label_id>` returns only tasks that carry that label.
- Deleting a label detaches it from every task.
- Add tests. The `labels` and `tasks` modules must keep to their public interfaces.
