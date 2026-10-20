# Practices behind the harness

Old engineering habits and newer agent habits, side by side. Each row says where the idea comes
from and where the harness uses it. Figures marked "reported" came from secondary write-ups.

| Practice | Where it comes from | In the harness |
|---|---|---|
| Small, self-contained changes, tests with the code, refactors apart from features | [Google engineering practices: small CLs](https://google.github.io/eng-practices/review/developer/small-cls.html) | One slice is one commit. A PR stays near 400 changed lines. The planner puts a refactor in its own slice. |
| Review quality drops past a few hundred lines | The SmartBear and Cisco review study (reported: 200 to 400 lines per review) | The 8 slice and 400 line limit. Bigger work becomes two tasks. |
| One logical change per commit, `type(scope): summary` | [Conventional Commits](https://www.conventionalcommits.org) and plain atomic commit practice | The commit hook requires a scope and one line. A git hook gives humans the same rule. |
| Modules hide one decision behind a small interface | Parnas, information hiding, and bounded contexts from domain driven design | `ARCHITECTURE.md` lists each module's owner, imports, and public interface. A boundary check in CI enforces it. |
| Domains with clear layers and gateways at scale | [Uber, domain oriented microservice architecture](https://www.uber.com/en/blog/microservice-architecture/) | Slices stay inside one module and cross modules only through its interface. |
| Spec first, small chunks, commits as save points, never commit code you cannot explain | [Addy Osmani, my LLM coding workflow](https://addyosmani.com/blog/ai-coding-workflow/) | Plan, slice cycle, one commit per slice, and a reviewer in a fresh context. |
| Give the agent a check it can run | [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Every slice runs build, lint, test. `/goal` or a Stop hook gates the end. |
| Keep CLAUDE.md short, use hooks for what must always happen | The same best practices page | `AGENTS.md` stays under 60 lines. Commit, PR, merge, dash, and read rules are hooks. |
| Deterministic steps around the agent loop, at most 2 CI rounds | [Stripe Minions](https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents) | `ship.js` runs git, checks, and CI as fixed steps and stops after 2 fix rounds. |
| Scale effort to the task, avoid spawning too many agents | [Anthropic, multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) | `small` has no plan, `medium` spawns one slicer per slice, a hard cap on spawns. |
| Writing agents share one thread, parallel writers collide | [Cognition, do not build multi-agents](https://cognition.ai/blog/dont-build-multi-agents), and Anthropic's note that coding has fewer parallel pieces | Slices run one at a time. A reviewer only reads. |
| Own your context window, small focused agents | [12-factor agents](https://github.com/humanlayer/12-factor-agents) | Each agent gets a small prompt, a file contract, and one job. |
| Enforce routing with hooks, keep edits with the main model | [Spotify Portal, token usage cut](https://engineering.atspotify.com/2026/9/portal-by-spotify-cut-my-claude-code-token-usage-by-90) | The read hook blocks whole reads over 350 lines. The slicer edits, it does not delegate edits. |
| Trust but verify with a second pair of eyes | Code review as an old habit, a fresh context reviewer as the new one | The reviewer sees the diff and the plan, never the author's reasoning. |

## What is a choice, not a rule

- 350 lines per file is a common ceiling for backend logic, not a law. It is one constant in
  `hooks/guard.py` if your repo needs another.
- 8 slices and 400 lines per PR are starting points drawn from the review sources above.
- Sequential slices trade speed for safety. Parallel slicers need isolated worktrees, which
  the harness does not set up yet.
