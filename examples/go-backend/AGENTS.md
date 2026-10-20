# acme-api

Go modular monolith for the Acme API (gin, fx, sqlc, asynq), one bounded context per package under `internal/modules`. Generic working rules come from the harness, the facts below are this repo's.

## Commands

- Build: `make build`
- Lint: `make lint`
- Test: `make test` (one package: `go test -race ./internal/modules/<module>/<package>`)
- Format check: `test -z "$(gofmt -l .)"` (`make fmt-check` prints files but never fails)

## Modules

<!-- Checked with the grep in docs/harness-setup.md. Today the rule does not hold, see docs/ARCHITECTURE.md. -->
- `internal/modules/<name>`: one bounded context each (ai, auth, billing, calendar, docs, health, home, notifications, onboarding, profile, projects, release, tasks, whatsapp). May import: the shared libs `internal/{db,redis,email,queue,observability,logging,http,config}` and no other module.
- Public interface of a module: its root package, `module.go`.
- `internal/app` wires the modules together with fx.

## Rules

- Branch from `main`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer. Scopes: ai, auth, billing, calendar, docs, health, home, notifications, onboarding, profile, projects, release, tasks, whatsapp, repo, ci.
- Never edit generated files under `internal/db/sqlc` (`*.sql.go`, `db.go`, `models.go`, `querier.go`, `querier_mock.go`) or `internal/modules/ai/grpc/acmeaiv1`. Run `make generate` (sqlc and mockgen) or `make proto` instead.
- A PR stays near 400 changed lines. Split a bigger task into slices that each build and pass.
- Schema changes are goose migrations in `internal/db/migrations` and queries in `internal/db/query`, then `make generate`.
- No em dashes in code, docs, commits, or PRs.
