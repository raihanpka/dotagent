Let a board be archived.

- `POST /api/v1/boards/:id/archive` archives a board of the signed in user and returns 200 with the board. `POST /api/v1/boards/:id/unarchive` undoes it. Both return 404 for a board the user does not own. Boards carry an `archived` boolean.
- `GET /api/v1/boards` hides archived boards unless `?archived=true` is given, which returns only the archived ones.
- Creating, updating, or deleting a task on an archived board returns 409. Reading its tasks still works.
- Add tests.

Note: `GET /api/v1/boards` may still list other users' boards. If you see that, mention it but do not fix it here.
