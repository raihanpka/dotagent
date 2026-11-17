# PR example: a finished, reviewable description

Illustrative. Keep only the lines you finished, delete unchecked boxes, and paste real evidence.

Title: `fix(guard): keep a lone stop visible`

## Summary

A stop recorded before a start is now visible in `run.sh state` and in the session start line, so a process that dies before it begins
still leaves the reason for the next session.

## Motivation

The old `run_summary` returned `run=none` when there was no `start`, even when a stop was recorded. The next session lost the reason and
started from scratch.

## What changed

- `plugin/hooks/guard.py`: fall back to the newest `stop` when there is no current run.
- `tests/hooks.test.sh`: cover a stop with no start, in `state` and in `SessionStart`.

## Test plan

- [x] `bash tests/hooks.test.sh` passes
- [x] `node --test tests/ship.test.mjs` passes
- [x] `node --test tests/skills.test.mjs` passes
- [x] `node --test tests/marketplace.test.mjs` passes
- [x] `python3 scripts/workflow-svg.py --check` passes
- [x] Runtime proof: `sh plugin/hooks/run.sh stop needs-human "the process died"` then `sh plugin/hooks/run.sh state` prints
      `run=stopped reason=needs-human`

## Risk and rollback

- Risk: a stale stop could be announced after a new task if the new task never calls `start`. The ship skill always calls `start` first.
- Rollback: `git revert <sha>`.

## Checklist

- [x] The title and commits say what changed, with no plan label and no `(#N)`.
- [x] The change stays inside the task and does not add unrequested files.
- [x] Tests cover the change, and none were deleted, skipped, or weakened.
- [x] Docs, the diagram, or config are updated when behavior or setup changed.
- [x] No secret, key, or generated file is committed.
- [ ] A release is intended only if the plugin version or CHANGELOG changed, and the user said yes.
