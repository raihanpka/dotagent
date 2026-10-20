# Architecture

A modular monolith: one Go binary (`cmd/server`) that wires one package per bounded context under `internal/modules` with uber/fx in `internal/app`. Shared infrastructure lives in `internal/` (db, redis, email, queue, observability, logging, http, config), and `cmd/migrate` and `cmd/seed` run migrations and reference data.

## Modules

Each module owns one thing and is used only through its public interface. The rule is: a module imports the shared libs and no other module. The table shows the rule, the violations as they are today are listed below it.

| Module | Owns | May import | Public interface |
|---|---|---|---|
| `internal/modules/ai` | gRPC stubs for the acme-ai contract | shared libs | `grpc/acmeaiv1` (generated, no `module.go`) |
| `internal/modules/auth` | sign up, sign in, Google sign in, sessions, tokens, email verification, password reset | shared libs | `module.go` |
| `internal/modules/billing` | payments, DOKU, in-app purchase | shared libs | `module.go` |
| `internal/modules/calendar` | calendar events | shared libs | `module.go` |
| `internal/modules/docs` | OpenAPI document and docs page | shared libs | `docs.go` |
| `internal/modules/health` | health probes | shared libs | `module.go` |
| `internal/modules/home` | mobile home screen | shared libs | `module.go` |
| `internal/modules/notifications` | notifications and push | shared libs | `module.go` |
| `internal/modules/onboarding` | onboarding progress and email OTP | shared libs | `module.go` |
| `internal/modules/profile` | user profile and account purge | shared libs | `module.go` |
| `internal/modules/projects` | projects | shared libs | `module.go` |
| `internal/modules/release` | release info | shared libs | `module.go` |
| `internal/modules/tasks` | tasks | shared libs | `module.go` |
| `internal/modules/whatsapp` | WhatsApp chat, workers, digests | shared libs | `module.go` |

Shared libs: `internal/{db,redis,email,queue,observability,logging,http,config}`.

Existing violations (see `docs/HARNESS-SETUP.md` for the command that finds them):

- `billing` imports `auth/data`.
- `home` imports `auth/data`.
- `profile` imports `auth/data`, `auth/tokenstore`, and `auth/signingingoogle`.
- `tasks` imports `home/service`.
- `whatsapp` imports `auth/tokenstore` and `ai/grpc/acmeaiv1` (10 files in `worker`).
- `whatsapp` tests import `internal/testdb`, and `internal/http/engine_test.go` imports `modules/health`. Neither is on the allowed list.

Most of these reach into a sub-package, not the module root, so there is no public interface to go through yet.

## Boundary check

None yet. `.golangci.yaml` has no `depguard`, and adding it now would fail CI on the violations above. See the open items in `HARNESS-SETUP.md`.

## Flow

A request enters the gin router built in `internal/http`, passes the global middleware, and reaches a module's `http` handler. The handler calls the module's `service`, which uses its `data` repository over the sqlc queries in `internal/db/sqlc`. Background work goes through asynq in `internal/queue`, with workers such as the ones in `whatsapp/worker`. The AI features call acme-ai over gRPC.
