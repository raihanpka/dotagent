## Summary

Guard now refuses a force push that is not a lease, so a rebase can only overwrite its own branch.

## Type

- [x] fix (bug fix)

## Changes

- `plugin/hooks/guard.py`: refuse `git push --force` and `-f`, allow `--force-with-lease`.
- `tests/hooks.test.sh`: two cases, one refused and one allowed.

## Verification

- [x] `bash tests/hooks.test.sh` passes
- [x] `node --test tests/ship.test.mjs` passes

## Checklist

- [x] Commit messages and the PR title follow `type(scope): summary` and say what changed, with no milestone, task, or step number and no `(#N)`.
- [x] No secret, key, or connection string is committed or logged.

## Screenshots or Logs

```
ok 1 - force push refused
ok 2 - force-with-lease allowed
```
