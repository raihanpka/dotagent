# Verification

How this repo proves a change works. Fill a row when a feature exists, and keep the proof cheap enough that an agent runs it on every
change to that feature. A green gate is not a green feature.

## The ladder

1. Static: `{{format-check}}`, `{{lint}}`, `{{build}}`.
2. Scoped test: the command in a subtask `Verify:`.
3. Runtime proof: drive the real artifact, for the changed feature.
4. Formal: a property over every state or input in a stated scope, when tests rarely reach the case.
5. CI: the PR gate on a clean machine.

## Feature map

| Feature | How a user reaches it | What proves it works |
|---|---|---|
| {{feature}} | {{the command, route, or UI path a user takes}} | {{the observable end state, not a test-only setter}} |

## Proof commands

- Whole gate: `{{test}}` plus `{{lint}}` and `{{format-check}}`.
- App or service: `{{how to launch it}}`, then `{{the command or request that proves a feature}}`.
- Evidence goes to: `{{a path, a temp dir, or a PR comment}}`.

## Formal properties

Add a row only when a property is worth checking on every change. Keep one property per row, stated in one sentence with the harm.

| Property | Tool | Covers | Command | Bounds | Sync |
|---|---|---|---|---|---|
| {{one sentence, for example "a job is never leased twice at once"}} | {{TLA+, Lean, an SMT verifier, or generated inputs}} | {{files and functions}} | {{make verify-...}} | {{2 processes, 3 jobs}} | {{commit sha}} |

- Show the check fail on a broken variant before you trust a pass. A check you have never seen fail proves nothing.
- Findings stay findings. Do not weaken the property or the model to get a pass. Report the counterexample in the code's words.
- A pass covers the model or the bound, not the whole system. Say what is left out.
- When the covered code changes, rerun the check and move `Sync` only after you confirm the model still describes the code.

## Not covered

- {{a property or feature with no check, and why}}
