# taskboard

A tiny task service. `app.handle(method, path, body, user)` returns `(status, json)`.

- `POST /tasks` with `{"title", "due_date"}` creates a task.
- `POST /tasks/{id}/complete` completes it.
- `GET /tasks` lists the caller's tasks.
