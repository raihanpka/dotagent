# Conventions

Only rules that differ from the language defaults or that the code cannot tell you.

## Code

- Formatting is `gofmt` and `goimports`. `make fmt-check` prints unformatted files but exits 0, so CI uses `test -z "$(gofmt -l .)"`.
- Lint is the curated set in `.golangci.yaml`. Adding a linter is a deliberate choice, not default-on.
- A module with a `module.go` exposes an fx `Module` in its root package, and `internal/app` composes them.
- Errors to clients are RFC 7807 problem responses from `internal/http`.
- Config comes from environment variables through `internal/config`, no module reads the environment directly today.

## Tests

- Tests sit next to the code as `*_test.go`.
- Run one package with `go test -race ./internal/modules/<module>/<package>`, the whole suite with `make test`.
- `make smoke` boots the built server against a throwaway Postgres and probes health.

## Generated files

- `internal/db/sqlc/*.sql.go`, `db.go`, `models.go`, `querier.go`: regenerate with `make sqlc`, never edit by hand.
- `internal/db/sqlc/querier_mock.go`: regenerate with `make generate`, never edit by hand.
- `internal/modules/ai/grpc/acmeaiv1/*.pb.go`: regenerate with `make proto` (needs the sibling `acme-ai` checkout), never edit by hand.
