# Architecture

## Style

- System: {{modular monolith, microservices, event driven, or other}}, because {{one reason from this repo}}.
- Structure: {{vertical slices by feature, layers, or other}}.
- Coupling rule: {{one line. Prefer low coupling: a module is used through its public interface, shared code lives in a shared library, dependencies point one way, no cycles}}.

## Shape

{{Two sentences: how the system is cut up, for example one package per bounded context.}}

## Modules

Each module owns one thing and is used only through its public interface.

| Module | Owns | May depend on | Public interface |
|---|---|---|---|
| `{{path}}` | {{what it owns}} | {{allowed modules or shared libs}} | `{{file or package}}` |

## Current violations

{{List each place the coupling rule is broken today, with the grep that found it. If none, write "none" and the grep.}}

## Boundary check

{{The tool and command that fails CI on a forbidden import, for example `depguard` or `import-linter`.
If there is none yet, write "none yet" and add it to the open items in `DOTAGENT-SETUP.md`.}}

## Flow

{{One short paragraph: how a request, event, or screen moves through the layers.}}
