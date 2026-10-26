# TODO: {{the goal in one line}}

## requirements

{{the user's words, verbatim. More than one point: number them R1, R2, and so on, keep the words. One point or none: no numbers.}}

## decisions

- {{question}}: {{answer}} ({{recommended and accepted, or chosen by the user}})

## PR 1: {{type(scope): summary, this is the PR title}}

branch: {{feat/short-slug}}
needs: none
covers: {{R1, R2, only when the requirements are numbered}}
files: {{path/**, other/file, every path this PR may edit, tests included}}

- [ ] 1.1 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{format, build, lint, test}}.
- [ ] 1.2 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.
- [ ] 1.3 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.

done: {{the PR url, filled when it is merged}}

## PR 2: {{type(scope): summary}}

branch: {{feat/short-slug}}
needs: {{PR 1, or none}}
covers: {{R3}}

- [ ] 2.1 `{{type(scope): summary}}`. {{What changes, in which files.}} Verify: {{commands}}.

done:

## fixes

<!-- A fix for review gaps or red CI adds one ticked line here. -->

## noticed

- {{a problem outside this task, not planned}}
