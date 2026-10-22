Let a board owner share a board with other users, with roles.

- `POST /api/v1/boards/:id/members` with `{"user_id": "...", "role": "editor"|"viewer"}` adds a member. Only the owner may. An unknown role returns 400, a board the caller does not own returns 404. Adding the same user again updates the role. User ids come from `GET /api/v1/me`.
- `GET /api/v1/boards/:id/members` lists the members (the owner is not listed). The owner and any member may read it.
- `DELETE /api/v1/boards/:id/members/:user_id` removes a member, owner only, 204.
- A viewer can read the board and its tasks. An editor can also create, update, and delete tasks. Only the owner can delete or archive the board and manage members. A user who is not the owner or a member gets 404 on everything about the board.
- `GET /api/v1/boards` returns the boards the user owns plus the boards shared with them, and nothing else.
- Add tests. Keep modules behind their public interfaces.
