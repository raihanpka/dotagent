# Architecture

## Style

- System: modular monolith, because one Go binary (`cmd/server`) serves every bounded context.
- Structure: vertical slices by bounded context under `internal/modules`, each with its routes, logic, and tests in one folder.
- Coupling rule: low coupling. A module is used through its public interface, shared code lives in `internal/httpx` and `internal/config`, dependencies point one way, no cycles.

## Modules

| Module | Owns | May depend on | Public interface |
|---|---|---|---|
| `internal/modules/auth` | users, tokens, the auth middleware | `httpx` | `Module`, `Middleware`, `UserID` |
| `internal/modules/boards` | boards and their owner | auth, `httpx` | `Module`, `Owns` |
| `internal/modules/tasks` | tasks on a board | auth, `httpx`, boards through `tasks.Boards` | `Module` |

`internal/app` wires them in `New()`. Routes under `/api/v1` need a bearer token except `signup` and `login`.

## Current violations

Rule checked: a module imports another module only through its root package. Command, from the repo root:

```bash
P=github.com/raihanpka/taskboard/internal/modules
for m in $(ls internal/modules); do grep -rnoE "\"$P/[a-z0-9/]+\"" internal/modules/$m --include="*.go" | grep -vE "\"$P/$m[/\"]"; done
```

It prints the imports of `auth` by `boards` and `tasks`, both of the root package, so none reaches an inner package. No cycles: boards and tasks depend on auth, and tasks reaches boards only through an interface.

## Boundary check

None yet. Go `internal/` hides the tree from other repos but does not stop one module importing another's inner package. A `depguard` rule would, see the open items in `DOTAGENT-SETUP.md`.

## Flow

A request enters `internal/app`, passes `auth.Middleware`, and reaches a module handler. The handler calls the module's in-memory store behind a mutex. Data is lost on restart by design.
