// Plan with Sonnet, one Haiku per slice, Sonnet review, then PR and at most 2 CI fix rounds.
// Roles repeat agents/*.md in short form because a workflow agent gets only its prompt.
export const meta = {
  name: 'ship',
  description: 'Plan a task, build it in atomic slices, review it, open the PR, and fix CI twice at most',
  phases: ['branch', 'plan', 'slices', 'review', 'pr', 'ci'],
}

const MODEL = { plan: 'sonnet', slice: 'haiku', review: 'sonnet', run: 'haiku' }
const MAX_CI_ROUNDS = 2
const MAX_REVIEW_ROUNDS = 2
const task = typeof args === 'string' ? args : args && args.task
if (!task) throw new Error('pass the task as the argument, for example /harness:ship add a slugify helper')

const list = { type: 'array', items: { type: 'string' } }
const sliceSchema = {
  type: 'object',
  required: ['message', 'change', 'verify'],
  properties: { id: { type: 'string' }, message: { type: 'string' }, change: list, read: list, verify: { type: 'string' } },
}

phase('branch')
const git = await agent(
  'Find the default branch with `git symbolic-ref --short refs/remotes/origin/HEAD`. Create and switch to a ' +
    'new branch from it named feat/<short-slug-of-the-task>. Task: ' + task +
    '. Run only those git commands. Reply with the base and the branch.',
  { model: MODEL.run, label: 'branch', schema: { type: 'object', required: ['base', 'branch'], properties: { base: { type: 'string' }, branch: { type: 'string' } } } },
)

phase('plan')
const plan = await agent(
  'You are the planner. Never edit code. Read little: grep for symbols, then read ranges. Cut this task into ordered ' +
    'atomic slices: ' + task + '\n' +
    'Each slice builds and passes tests alone, changes 1 to 3 files inside one module, has a one line ' +
    '`type(scope): summary` commit message that describes exactly those files, lists only the symbols or ranges the ' +
    'worker must read, and the exact build, lint, and test commands. No source file may end above 350 lines. ' +
    'Slices touching the same file are ordered. Also write the plan to tasks/plan.md. Give a PR title and a two line summary.',
  { model: MODEL.plan, label: 'plan', schema: { type: 'object', required: ['slices', 'prTitle', 'summary'], properties: { slices: { type: 'array', items: sliceSchema }, prTitle: { type: 'string' }, summary: { type: 'string' } } } },
)

const sliceTask = (s, note) =>
  'You are the slicer. Implement exactly this slice and nothing else.\n' +
  'Commit message: ' + s.message + '\nChange: ' + s.change.join(', ') + '\nRead only: ' + (s.read || []).join(', ') + '\nVerify: ' + s.verify + '\n' +
  'Read with offset and limit. Write a failing test first when behavior is added. Run the verify commands, never weaken a check. ' +
  'Stage only the Change files and commit with the one line message. Never push. ' + (note || '')
const sliceSchemaOut = { type: 'object', required: ['commit', 'ok'], properties: { commit: { type: 'string' }, ok: { type: 'boolean' }, note: { type: 'string' } } }

phase('slices')
for (const s of plan.slices) {
  let done = await agent(sliceTask(s), { model: MODEL.slice, label: s.message, schema: sliceSchemaOut })
  if (!done.ok) done = await agent(sliceTask(s, 'The last attempt failed: ' + done.note), { model: MODEL.slice, label: s.message + ' (retry)', schema: sliceSchemaOut })
  if (!done.ok) throw new Error('slice failed twice: ' + s.message + ': ' + done.note)
}

const review = () =>
  agent(
    'You are the reviewer with a fresh context. Run `git diff ' + git.base + '...HEAD` and compare with tasks/plan.md. Report only gaps ' +
      'that affect correctness or the plan: a missing requirement, a broken edge case, a test that proves nothing, a change outside ' +
      'the plan, a crossed module boundary, a file above 350 lines. No style notes. When clean, write the PR body from templates/pr.md: ' +
      'tick only what was done and delete every unchecked line. Summary of the change: ' + plan.summary,
    { model: MODEL.review, label: 'review', schema: { type: 'object', required: ['clean', 'gaps', 'prBody'], properties: { clean: { type: 'boolean' }, gaps: list, prBody: { type: 'string' } } } },
  )

phase('review')
let verdict = await review()
for (let round = 0; !verdict.clean && round < MAX_REVIEW_ROUNDS; round++) {
  await agent(sliceTask({ message: 'fix: address review gaps', change: ['whatever the gaps name'], verify: plan.slices[0].verify }, 'Gaps: ' + verdict.gaps.join('; ')), { model: MODEL.slice, label: 'review fix ' + (round + 1), schema: sliceSchemaOut })
  verdict = await review()
}
if (!verdict.clean) return { stopped: 'review', gaps: verdict.gaps, branch: git.branch }

phase('pr')
const pr = await agent(
  'Push branch ' + git.branch + ' with `git push -u origin ' + git.branch + '`, then run `gh pr create --base ' + git.base +
    ' --title "' + plan.prTitle + '" --body-file <a temp file holding the body below>`. Body:\n' + verdict.prBody + '\nReply with the PR number and url.',
  { model: MODEL.run, label: 'open pr', schema: { type: 'object', required: ['number', 'url'], properties: { number: { type: 'number' }, url: { type: 'string' } } } },
)

phase('ci')
const checkSchema = { type: 'object', required: ['green', 'log'], properties: { green: { type: 'boolean' }, log: { type: 'string' } } }
const watch = () => agent('Run `gh pr checks ' + pr.number + ' --watch`. If a check failed, run `gh run view --log-failed` and put its last 40 lines in log.', { model: MODEL.run, label: 'ci', schema: checkSchema })
let ci = await watch()
for (let round = 0; !ci.green && round < MAX_CI_ROUNDS; round++) {
  await agent(sliceTask({ message: 'fix(ci): make the failing check pass', change: ['whatever the log names'], verify: plan.slices[0].verify }, 'Failing log:\n' + ci.log + '\nAfter the commit run `git push`.'), { model: MODEL.slice, label: 'ci fix ' + (round + 1), schema: sliceSchemaOut })
  ci = await watch()
}
return { pr: pr.url, number: pr.number, ciGreen: ci.green, ciLog: ci.green ? '' : ci.log, review: 'clean' }
