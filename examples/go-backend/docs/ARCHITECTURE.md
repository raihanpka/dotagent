# Architecture

## Style

- System: modular monolith, because one Go binary (`cmd/server`) serves every bounded context and wires them with uber/fx.
- Structure: vertical slices by bounded context under `internal/modules`, each with its own `data`, `service`, and `http` layers where it needs them.
- Coupling rule: low coupling. A module is used through its public interface, shared code lives in the shared libs in `internal/` (`db`, `redis`, `email`, `queue`, `observability`, `logging`, `http`, `config`), dependencies point one way, no cycles.

## Shape

Each folder under `internal/modules` is one bounded context. `internal/app` is the composition root that wires every module and the shared libs into one fx application.

## Modules

Each module owns one thing and is used only through its public interface. The public interface is the module root package (`module.go`), except `ai`, whose contract is `grpc/acmeaiv1`.

| Module | Owns | May depend on | Public interface |
|---|---|---|---|
| `internal/modules/ai` | gRPC contract stubs for acme-ai | nothing | `grpc/acmeaiv1` |
| `internal/modules/auth` | sign up, sign in, sessions, tokens, password reset, email verification | shared libs | `module.go` |
| `internal/modules/billing` | Doku and in-app purchase billing | auth, shared libs | `module.go` |
| `internal/modules/calendar` | calendar events | shared libs | `module.go` |
| `internal/modules/docs` | OpenAPI document and the `/docs` page | shared libs | `docs.go` |
| `internal/modules/health` | liveness and readiness probes | shared libs | `module.go` |
| `internal/modules/home` | home feed, focus, score, streak | auth, shared libs | `module.go` |
| `internal/modules/notifications` | notifications and push | shared libs | `module.go` |
| `internal/modules/onboarding` | onboarding progress and email OTP | shared libs | `module.go` |
| `internal/modules/profile` | user profile and account purge | auth, shared libs | `module.go` |
| `internal/modules/projects` | projects | shared libs | `module.go` |
| `internal/modules/release` | public app version and kill switch contract | shared libs | `module.go` |
| `internal/modules/tasks` | tasks and subtasks | home, shared libs | `module.go` |
| `internal/modules/whatsapp` | WhatsApp http handler and worker | auth, ai, shared libs | `module.go` |

The "May depend on" column records what the code imports today (see the grep below), not a verified target.

## Current violations

Rule checked: a module imports another module only through its root package. The command, run from the repo root, lists every import of another module's path (tests included):

```bash
P=github.com/acme/api/internal/modules
for m in $(ls internal/modules); do grep -rnoE "\"$P/[a-z0-9/]+\"" internal/modules/$m --include="*.go" | grep -vE "\"$P/$m[/\"]"; done
```

Today it prints 23 imports. Apart from the `ai` contract, every one reaches into another module's inner package instead of its root package:

- `billing/service` imports `auth/data`.
- `home/service` imports `auth/data` (2 files).
- `profile/data` imports `auth/data`.
- `profile/http` (3 files, one a test) and `profile/module.go` import `auth/tokenstore`, and `profile/module.go` imports `auth/signingingoogle`.
- `whatsapp/http` (2 files, one a test) and `whatsapp/module.go` import `auth/tokenstore`.
- `tasks/service/module.go` imports `home/service`.
- `whatsapp/worker` imports `ai/grpc/acmeaiv1` (10 files). That is the `ai` public contract, so it is allowed.

Shared libs importing a module: `internal/http/engine_test.go` imports `modules/health` (test only). `internal/app` imports every module by design.

No cycles between modules: the dependency edges are billing, home, profile, whatsapp to auth, tasks to home, and whatsapp to ai.

## Boundary check

None yet. Go `internal/` already hides the module tree from other repos, but it does not stop one module importing another module's inner packages. A `depguard` rule in `.golangci.yaml` would fail CI on that, see the open items in `DOTAGENT-SETUP.md`.

## Flow

A request enters `cmd/server`, passes the global middleware in `internal/http`, and reaches a module's `http` handler. The handler calls the module `service`, which reads and writes through `data` on the sqlc queries in `internal/db/sqlc`. Background work goes through `internal/queue` to workers such as `whatsapp/worker`.
