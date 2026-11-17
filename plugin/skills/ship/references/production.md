# Production verification

Tests prove the cases someone wrote. A canary, a live metric, a log line, and a rollback path prove what a real user gets after the merge.
Read this when a PR has a `release:` or `watch:` line, or when the change touches auth, money, data, or availability.

## The four stages

| Stage | What you run | What it proves |
|---|---|---|
| Pre-production | format, lint, build, unit, integration, contract, security scan, formal property | the change is well formed and its known cases hold |
| Deploy | canary or staging deploy, boot and health probe, smoke, config check | the artifact starts and answers in an environment like production |
| Release | canary percentage, feature flag, traffic shaping, monitoring, exception tracking, logs | real traffic reaches the change without a bad signal |
| Post-release | profiling, tracing, A/B, RUM, audit, chaos, on-call review | the change holds under real load and is observable |

A release with no `watch:` is `inconclusive`, not done.

## The TODO fields

Add these to a PR only when the repo has the tooling. Do not invent a deploy system.

```
release: the deploy command or pipeline, or "the merge triggers deploy"
watch: the health, canary, or metric check, the threshold, and the window
rollback: the command, the flag, or "revert the squash commit"
```

`prove:` stays the pre-merge proof. `watch:` is the post-merge proof.

## After the merge

1. Run `watch:` for the stated window. Record the command, the window, and the value in `## log`. A green check is evidence; "it looks
   fine" is not.
2. If the watch passes, the PR is done and the run goes on.
3. If the watch fails, stop `regression`. Run `rollback:` when it exists and the user allowed it. When it does not, leave the change in
   place only if the failure is safe and open a fix PR with the failing signal and the smallest fix. Never hide a regression by weakening
   the threshold.
4. A production-only failure is a new unit with the same proof bar. It gets its own PR and its own watch.

## The checks, and when they matter

- **Canary:** a small slice of traffic before the full rollout. Compare error rate and latency against the baseline.
- **Feature flag:** ship off by default, turn it on for a small cohort, then widen. The flag is the rollback.
- **Monitoring and alerting:** the signal that would page someone. Name the metric, the threshold, and the window.
- **Logs and events:** the one line that shows the change ran, and the error that must not appear.
- **Exception tracking:** new error classes for the changed path.
- **Tracing:** the span and the latency of the changed path end to end.
- **Profiling:** CPU, allocation, or I/O against a baseline, with the limiter named.
- **A/B test:** the metric, the sample, the duration, and the decision rule.
- **Real user monitoring:** the browser or device metric for a UI change.
- **Audit:** who changed what, for security and money paths.
- **Chaos and fault injection:** a dependency down, a timeout, a retry storm. Use only in a safe environment.
- **On-call review:** the dashboard, the runbook, and the alert that a human will see.

## Safety

- A production action is irreversible until proven otherwise. Ask before a deploy that can delete data, send messages, or force a rollout.
- Prefer staging, a dry run, or a canary. A dry run that still touches the network is not a dry run; observe what it skips.
- Record the rollback before the release, not after the failure. If there is no rollback, say so and stop `needs-human`.
- The evidence is a pointer: a dashboard URL, a query, a log line, a metric with its window, or a run id. Never paste a full production log.
