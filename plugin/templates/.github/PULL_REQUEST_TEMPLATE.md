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

<!-- Evidence, not a claim. Include the `prove:` command and its output pointer. -->

- [ ] `{{build}}` passes
- [ ] `{{lint}}` passes
- [ ] `{{test}}` passes
- [ ] Runtime proof: `{{prove command}}`, evidence: `{{output or artifact path}}`
- [ ] Production watch: `{{watch command}}`, window: `{{minutes}}`, value: `{{metric}}` (only when the PR releases)

## Risk and rollback

<!-- The blast radius, the one fact that makes it safe, and how to undo it. -->

- Risk: {{what could break, and where}}
- Rollback: {{the flag, the deploy, or `git revert <sha>`}}

## Checklist

- [ ] The title and commits say what changed, with no plan label and no `(#N)`.
- [ ] The change stays inside the linked issue or task and does not add unrequested files.
- [ ] Tests cover the change, and none were deleted, skipped, or weakened.
- [ ] Docs or config are updated when behavior or setup changed.
- [ ] No secret, key, or generated file is committed.
- [ ] A breaking change is named, with its migration.
