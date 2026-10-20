# taskboard

Small Python service, standard library only.

## Commands

- Test: `python3 -m unittest` (one file: `python3 -m unittest tests.test_http`)
- There is no build or lint step.

## Modules

- `tasks`: tasks, their rules, and the HTTP handlers. Public interface: `tasks/__init__.py`.
- `notifications`: sends messages. Public interface: `notifications/__init__.py`.
- `shared`: code both modules use, for example `shared/clock.py`.
- `app.py`: wires modules and routes requests.

## Rules

- A module is used through its `__init__.py` names only. No `from tasks.models import ...` in another module.
- HTTP handlers call the service, never the repository.
- Branch from `main`. Commits are one line, `type(scope): summary`, scopes: tasks, notifications, shared, app, docs.
