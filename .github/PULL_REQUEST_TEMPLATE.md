<!--
Keep only what this PR did. Tick the boxes you finished and delete every unchecked line.
Put evidence, not a claim, under Test plan. Delete the comments before you submit.
The title and every commit follow `type(scope): summary`, one line, no trailer.
-->

## Summary

<!-- One or two sentences: what changed and why. -->

## Motivation

<!-- The problem, the requirement, or the issue. Delete this section for a trivial fix. -->

## What changed

<!-- One bullet per commit or logical change. Keep it short. -->

## Test plan

<!-- Evidence, not a claim. For this repo, run every check before the PR. -->

- [ ] `bash tests/hooks.test.sh` passes
- [ ] `node --test tests/ship.test.mjs` passes
- [ ] `node --test tests/skills.test.mjs` passes
- [ ] `node --test tests/marketplace.test.mjs` passes
- [ ] `python3 scripts/workflow-svg.py --check` passes
- [ ] Runtime proof or smoke test: `{{the command you ran, and the output or artifact path}}`

## Risk and rollback

<!-- The blast radius, the one fact that makes it safe, and how to undo it. -->

- Risk: {{what could break, and where}}
- Rollback: {{the flag, the deploy, or `git revert <sha>`}}

## Checklist

- [ ] The title and commits say what changed, with no plan label and no `(#N)`.
- [ ] The change stays inside the task and does not add unrequested files.
- [ ] Tests cover the change, and none were deleted, skipped, or weakened.
- [ ] Docs, the diagram, or config are updated when behavior or setup changed.
- [ ] No secret, key, or generated file is committed.
- [ ] A release is intended only if the plugin version or CHANGELOG changed, and the user said yes.
