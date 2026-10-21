# Conventions

Only rules that differ from the language defaults or that the code cannot tell you.

## Code

- Errors reach the client as `{"error": "..."}` through `httpx.Error`.
- Stores are in memory and guarded by a mutex held for the whole read or write.
- A module hides its internals: handlers and services are unexported, `Module` is the way in.

## Tests

- Tests sit next to the code as `*_test.go` and use `httptest` against `app.New()` or the module's own router.
- Run everything with `make test` (race detector on).
