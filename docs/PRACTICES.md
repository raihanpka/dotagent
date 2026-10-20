# Practices behind the dotagent and this workflow

Old engineering habits and newer agent habits in this era, side by side. Each row says where the idea comes
from and where the dotagent uses it. Figures marked "reported" came from secondary write-ups.

| Practice | Where it comes from | In the dotagent |
|---|---|---|
| Small, self-contained changes, tests with the code, refactors apart from features | [Google engineering practices: small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html) | One slice is one commit. A PR stays near 400 changed lines. The planner puts a refactor in its own slice. |
| Review works best on small changes, so keep each PR small | [Google, Modern Code Review: A Case Study at Google](https://research.google/pubs/modern-code-review-a-case-study-at-google/) (ICSE-SEIP 2018: interviews, a survey, and 9 million reviewed changes). The 400 line figure is our choice, not the paper's. | The 8 slice and 400 line limit. Bigger work becomes two tasks. |
| One logical change per commit, `type(scope): summary` | [Conventional Commits](https://www.conventionalcommits.org) and plain atomic commit practice | The commit hook requires a scope and one line. A git hook gives humans the same rule. |
| Low coupling, high cohesion: a small public interface, one way dependencies, shared code in a shared library, boundaries checked in CI | [Shopify, Enforcing Modularity in Rails Apps with Packwerk](https://shopify.engineering/enforcing-modularity-rails-apps-packwerk): a modular monolith whose packages may depend only on declared packages and use only each other's public constants, checked in CI. | `ARCHITECTURE.md` records the style, the coupling rule, and each module's interface. A boundary check in CI enforces it, and setup greps the code to list today's violations. |
| Domains with clear layers and gateways at scale | [Uber, domain oriented microservice architecture](https://www.uber.com/en/blog/microservice-architecture/) | Slices stay inside one module and cross modules only through its interface. |
| Spec first, small chunks, commits as save points, never commit code you cannot explain | [Addy Osmani, my LLM coding workflow](https://addyosmani.com/blog/ai-coding-workflow/) | Plan, slice cycle, one commit per slice, and a reviewer in a fresh context. |
| Give the agent a check it can run | [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Every slice runs build, lint, test. `/goal` or a Stop hook gates the end. |
| Keep CLAUDE.md short, use hooks for what must always happen | The same best practices page | `AGENTS.md` stays under 60 lines. Commit, PR, merge, dash, and read rules are hooks. |
| Files of one responsibility, most between 100 and 300 lines, rarely past 500 | [ESLint `max-lines`](https://eslint.org/docs/latest/rules/max-lines) (default 300, docs say recommendations usually range from 100 to 500) and Clean Code (about 200 lines typical, 500 at most, "not a hard and fast rule", reported from secondary summaries) | Size is a cohesion signal. A file past about 500 lines gets split by responsibility in its own slice, and the reviewer flags it. |
| One CI trigger per event: the PR gate on `pull_request`, heavier checks on push to the default branch | [GitHub Docs, events that trigger workflows](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows): `push` fires for any pushed branch and `pull_request` for every update of a PR, so listing both runs the same checks twice. The split follows a real Go backend's PR and staging workflows. | `ci-pr.yml` and `ci-main.yml`. A plain commit on a branch starts nothing. |
| Deterministic steps around the agent loop, at most 2 CI rounds | [Stripe Minions](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents) | `ship-large.js` runs git, checks, and CI as fixed steps and stops after 2 fix rounds. |
| Scale effort to the task, avoid spawning too many agents | [Anthropic, multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) | `small` has no plan, `medium` spawns one slicer per slice, a hard cap on spawns. |
| Writing agents share one thread, parallel writers collide | [Cognition, do not build multi-agents](https://cognition.ai/blog/dont-build-multi-agents), and Anthropic's note that coding has fewer parallel pieces | Slices run one at a time. A reviewer only reads. |
| Keep context small and high signal: just in time reads, minimal tools, focused agents | [Anthropic, Effective context engineering for AI agents](https://anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Each agent gets a small prompt, a file contract, and one job. Agents read ranges, not whole files. |
| Enforce routing with hooks, keep edits with the main model | [Spotify Portal, token usage cut](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90) | The read hook blocks whole reads over 500 lines. The slicer edits, it does not delegate edits. |
| Trust but verify with a second pair of eyes | Code review as an old habit, a fresh context reviewer as the new one | The reviewer sees the diff and the plan, never the author's reasoning. |

## What is a choice, not a rule

- File size has no hard law behind it. The size and defect research I found is mixed: El Emam and
  colleagues showed that class size confounds many metrics, so size alone does not explain
  defects (El Emam and colleagues, IEEE Transactions on Software Engineering, 2001).
  So 100 to 300 lines is a typical range and 500 is a prompt to ask whether the file does two
  things, not a line that fails a build. The only hard number is the 500 line limit on whole
  reads, `READ_LINES` in `hooks/guard.py`, which saves context and does not judge the code.
- 8 slices and 400 lines per PR are starting points drawn from the review sources above.
- Sequential slices trade speed for safety. Parallel slicers need isolated worktrees, which
  the dotagent does not set up yet.
