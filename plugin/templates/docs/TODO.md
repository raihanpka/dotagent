# TODO: {{the goal in one line}}

goal: {{what this run is for, in one line}}
finish: {{a command or artifact that can pass or fail, not a mood}}
budget: {{optional, for example 8 units or 2h}}
base: {{the branch the PRs target}}

## requirements

{{the user's words, verbatim. More than one point: number them R1, R2, and so on, keep the words. One point or none: no numbers.}}

## decisions

- {{question}}: {{answer}} ({{recommended and accepted, or chosen by the user}})

## log

| when | unit | decision | evidence | result |
|---|---|---|---|---|
| {{iso time}} | {{1.1}} | {{what was chosen or done}} | {{commit, path:line, command, or artifact}} | {{done, reverted, or inconclusive}} |

## PR 1: {{type(scope): summary, this is the PR title}}

branch: {{feat/short-slug}}
needs: none
covers: {{R1, R2, only when the requirements are numbered}}
files: {{path/**, other/file, every path this PR may edit, tests included}}
prove: {{the real-artifact check: run the feature, read the value, take the screenshot, compare before and after}}

- [ ] 1.1 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{format, build, lint, test}}.
- [ ] 1.2 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.
- [ ] 1.3 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.

done: {{the PR url, filled when it is merged}}

## PR 2: {{type(scope): summary}}

branch: {{feat/short-slug}}
needs: {{PR 1, or none}}
covers: {{R3}}
prove: {{the proof}}

- [ ] 2.1 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.

done:

## fixes

<!-- A fix for review gaps or red CI adds one ticked line here, and a ## log row. -->

## noticed

- {{a problem outside this task, not planned}}

<!-- On a stop, replace the two lines below with the reason, what, and next. -->

## stopped

reason: {{one of the reasons in the loop reference}}
what: {{one line}}
next: {{one concrete action}}
