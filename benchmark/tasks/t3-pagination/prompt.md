Paginate the task list.

`GET /api/v1/boards/:id/tasks` takes `limit` and `offset` query parameters. `limit` defaults to 50 and is at most 100, `offset` defaults to 0. A value that is not a non-negative integer, a `limit` of 0, or a `limit` over 100 returns 400. The response header `X-Total-Count` holds the number of tasks on the board before paging. The order stays oldest first. Add tests.
