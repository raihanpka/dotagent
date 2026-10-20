# Conventions

Only rules that differ from the language defaults or that the code cannot tell you.

## Code

- Run `make lint` before a push. The curated linter set lives in `.golangci.yaml`, adding one is a deliberate choice.
- `make fmt-check` only lists unformatted files and still exits 0. CI uses `test -z "$(gofmt -l .)"` instead.
- Schema changes are goose migrations in `internal/db/migrations`, queries are in `internal/db/query`.

## Tests

- Tests sit next to the code as `*_test.go`. Postgres-backed tests use testcontainers, so Docker must be running.
- Run everything with `make test` (race detector on). Run one package with `go test -race ./internal/modules/tasks/service -run TestName`.

## Generated files

- `internal/db/sqlc/*.sql.go`, `models.go`, `db.go`, `querier.go`: regenerate with `make sqlc`, never edit by hand.
- `internal/db/sqlc/querier_mock.go`: regenerate with `make generate`, never edit by hand.
- `internal/modules/ai/grpc/acmeaiv1/*.pb.go`: regenerate with `make proto` (needs the sibling `../acme-ai` checkout), never edit by hand.
