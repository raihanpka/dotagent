# Case: recurring tasks

A product manager sends a feature request. An engineer has to land it in a small service without
breaking what works. This is the everyday shape of work dotagent is built for: clear requirements
that touch several layers.

## The repo

`repo/` is `taskboard`, a Python service with two modules and a shared folder:

```
tasks/           tasks, their rules, and the HTTP handlers (public interface: __init__.py)
notifications/   sends messages (public interface: __init__.py)
shared/          code both modules use
app.py           wires modules and routes requests
tests/           existing tests, all passing
```

Its `AGENTS.md` states the facts a setup would produce: the test command, the modules, the rule
that a module is used through its `__init__.py` names only, and that handlers never touch the
repository. The repo has no build or lint step.

## The task

`task.md` is a six point request as a product manager would write it: a `repeat` field, the next
task created on completion with the due date moved from the previous due date, validation messages,
an API change, a notification to the owner, and "nothing that works today may change".

It spans the model, the service, the HTTP layer, and another module, so a good run needs about four
commits: the repeat rule, the completion flow, the API and notification, and the README.

## The hidden checks

- `acceptance.py` runs 9 behavior checks through the public API. Two of them are traps: the next
  due date must come from the previous due date and not from today, and a plain task must still
  complete with `next` set to null.
- `coupling.py` counts deep imports across modules, handlers that touch the repository, and cycles
  between modules. The natural mistake is for `notifications` to import `tasks` internals, or for
  the HTTP handler to build the next task through the repository.

Before this case was used, a reference solution passed 9 of 9 and the starting repo scored 2 of 9.
A deliberately coupled variant scored 3 violations, so the measure does catch what it claims to.
