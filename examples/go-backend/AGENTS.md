# acme-api

Go backend for the Acme productivity app, a lean modular monolith served over REST under `/api/v1`. Generic working rules come from the dotagent, the facts below are this repo's.

## Commands

- Build: `make build`
- Lint: `make lint`
- Test: `make test` (one package: `go test -race ./internal/modules/tasks/service -run TestName`)

## Architecture

- Style: modular monolith. Structure: vertical slices by bounded context under `internal/modules`.
- Coupling: a module is used only through its public interface, shared code lives in the shared libs in `internal/` (`db`, `redis`, `email`, `queue`, `observability`, `logging`, `http`, `config`), dependencies point one way. Not enforced by a tool yet, see `docs/ARCHITECTURE.md`.

## Modules

<!-- Public interface = the module root package (`module.go`). May depend on = other modules and shared libs. -->
- `internal/modules/ai`: gRPC contract stubs for acme-ai. Public interface: `grpc/acmeaiv1`. May depend on: nothing.
- `internal/modules/auth`: sign up, sign in, sessions, tokens, password reset, email verification. Public interface: `module.go`. May depend on: shared libs.
- `internal/modules/billing`: Doku and in-app purchase billing. Public interface: `module.go`. May depend on: auth, shared libs.
- `internal/modules/calendar`, `projects`, `tasks`, `notifications`, `onboarding`: one feature each. Public interface: `module.go`. May depend on: shared libs, plus `home` for tasks.
- `internal/modules/home`: home feed, focus, score, streak. Public interface: `module.go`. May depend on: auth, shared libs.
- `internal/modules/profile`: user profile and account purge. Public interface: `module.go`. May depend on: auth, shared libs.
- `internal/modules/whatsapp`: WhatsApp handler and worker. Public interface: `module.go`. May depend on: auth, ai, shared libs.
- `internal/modules/docs`, `health`, `release`: OpenAPI docs, probes, app version contract. Public interface: package root. May depend on: shared libs.
- `internal/app` is the composition root and the only place that wires every module together.

## Rules

- Branch from `main`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer. Scopes: `ai`, `auth`, `billing`, `calendar`, `docs`, `health`, `home`, `notifications`, `onboarding`, `profile`, `projects`, `release`, `tasks`, `whatsapp`, `repo`, `ci`.
- Never edit generated files under `internal/db/sqlc` (not `*_test.go`) or `internal/modules/ai/grpc/acmeaiv1`. Run `make generate` or `make proto` instead.
- A PR stays near 400 changed lines. Split a bigger task into slices that each build and pass.
- Schema changes go in `internal/db/migrations` and queries in `internal/db/query`, then run `make generate`.
- No em dashes and no emojis in files, commits, or PR text.
