# Architecture

{{Two sentences: the shape of the system, for example a modular monolith with one package per context.}}

## Modules

Each module owns one thing and is used only through its public interface.

| Module | Owns | May import | Public interface |
|---|---|---|---|
| `{{path}}` | {{what it owns}} | {{allowed modules or none}} | `{{file or package}}` |

## Boundary check

{{The tool and command that fails CI on a forbidden import, for example `depguard` or `import-linter`.
If there is none yet, write "none yet" and add it to the open items in `harness-setup.md`.}}

## Flow

{{One short paragraph: how a request, event, or screen moves through the layers.}}
