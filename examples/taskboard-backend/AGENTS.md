# taskboard-backend

Go backend for a small team task board, a modular monolith served over REST under `/api/v1` (gin, in-memory stores). It is the dotagent benchmark app, see `../../docs/BENCHMARK.md`. Generic working rules come from the dotagent, the facts below are this repo's.

## Commands

- Build: `make build`
- Format: `gofmt -w .` (check only: `make fmt-check`)
- Lint: `make lint` (`go vet`)
- Test: `make test` (one package: `go test -race ./internal/modules/tasks -run TestName`)
- Whole gate: `make ci`

## Architecture

- Style: modular monolith. Structure: vertical slices by bounded context under `internal/modules`.
- Coupling: a module is used only through its public interface. Shared code lives in `internal/httpx` and `internal/config`. A module that needs another declares a small interface (as `tasks` does for boards). Dependencies point one way. See `docs/ARCHITECTURE.md`.

## Modules

- `internal/modules/auth`: sign up, log in, bearer token middleware. Public interface: `Module`, `Middleware`, `UserID`. May depend on: `httpx`.
- `internal/modules/boards`: boards owned by a user. Public interface: `Module`, `Owns`. May depend on: auth, `httpx`.
- `internal/modules/tasks`: tasks on a board. Public interface: `Module`. May depend on: auth, `httpx`, and boards only through its `Boards` interface.
- `internal/app` is the composition root and the only place that wires every module together.

## Rules

- Branch from `main`. One task is one branch and one PR.
- Commits are one line, `type(scope): summary`, no trailer, and never a plan label like `milestone-1` or `finishing task-2`, nor `(#N)`. Scopes: `auth`, `boards`, `tasks`, `app`, `httpx`, `config`, `repo`, `ci`, plus the name of any new module.
- Tests sit next to the code as `*_test.go` and use `httptest`. A new module gets its own tests.
- A PR stays reviewable in one sitting, a few hundred changed lines is typical, a range and not a limit. A bigger task is more PRs that each build and pass.
- Do not add a dependency without asking.
