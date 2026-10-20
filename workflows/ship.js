// Plan with Sonnet, one Haiku per slice, Sonnet review, then PR and at most 2 CI fix rounds.
// Roles repeat agents/*.md in short form because a workflow agent gets only its prompt.
// Slices run one at a time on purpose: one working tree has one git index, so parallel commits collide.
export const meta = {
  name: 'ship',
  description: 'Plan a task, build it in atomic slices, review it, open the PR, and fix CI twice at most',
  phases: ['branch', 'plan', 'slices', 'review', 'pr', 'ci'],
}

const MODEL = { plan: 'sonnet', slice: 'haiku', review: 'sonnet', run: 'haiku' }
const MAX_SLICES = 8 // more than this is two tasks, a PR stays near 400 changed lines
const MAX_SLICER_RUNS = 14 // 8 slices, retries, 2 review fixes, 2 CI fixes, with room to spare
const MAX_REVIEW_ROUNDS = 2
const MAX_CI_ROUNDS = 2

// args is the task as typed, pasted requirements included, or { task, context, planOnly, companions }.
const input = typeof args === 'string' ? { task: args } : args || {}
const task = input.task
if (!task) throw new Error('pass the task as the argument, for example /harness:ship add a slugify helper')
const context = input.context ? '\nRequirements as given, verbatim:\n' + input.context : ''
const companions = input.companions || {}
const companionNote =
  (companions.plan && companions.plan !== 'none' ? 'Invoke the skill ' + companions.plan + ' with the Skill tool and follow it. ' : '') +
  (companions.build && companions.build !== 'none' ? 'Invoke the skill ' + companions.build + ' with the Skill tool and follow it. ' : '')

let slicerRuns = 0
const list = { type: 'array', items: { type: 'string' } }
const sliceSchema = {
  type: 'object',
  required: ['message', 'change', 'verify'],
  properties: { id: { type: 'string' }, message: { type: 'string' }, change: list, read: list, verify: { type: 'string' } },
}
const sliceResult = { type: 'object', required: ['commit', 'ok'], properties: { commit: { type: 'string' }, ok: { type: 'boolean' }, note: { type: 'string' } } }

// Runs one Haiku slicer, counted against the spawn cap.
const slicer = (s, label, note) => {
  if (++slicerRuns > MAX_SLICER_RUNS) throw new Error('slicer spawn cap reached: ' + MAX_SLICER_RUNS)
  return agent(
    'You are the slicer. Implement exactly this slice and nothing else. ' + companionNote + '\n' +
      'Commit message: ' + s.message + '\nChange: ' + s.change.join(', ') + '\nRead only: ' + (s.read || []).join(', ') + '\nVerify: ' + s.verify + '\n' +
      'Read with offset and limit. Write a failing test first when behavior is added. Run the verify commands, never weaken a check. ' +
      'Stage only the Change files and commit with the one line message. Never push. ' + (note || ''),
    { model: MODEL.slice, label, schema: sliceResult },
  )
}

phase('branch')
const git = await agent(
  'Find the default branch with `git symbolic-ref --short refs/remotes/origin/HEAD`. Create and switch to a new branch from it named ' +
    'feat/<short-slug-of-the-task>. Task: ' + task + '. Run only those git commands. Reply with the base and the branch.',
  { model: MODEL.run, label: 'branch', schema: { type: 'object', required: ['base', 'branch'], properties: { base: { type: 'string' }, branch: { type: 'string' } } } },
)

phase('plan')
const plan = await agent(
  'You are the planner. Never edit code. Read little: grep for symbols, then read ranges. ' + companionNote + 'Cut this task into ordered atomic slices: ' + task + context + '\n' +
    'At most ' + MAX_SLICES + ' slices and about 400 changed lines in total. If the task needs more, return the first ' + MAX_SLICES + ' slices and set tooBig to true. ' +
    'Each slice builds and passes tests alone, changes 1 to 3 files inside one module, has a one line `type(scope): summary` commit message ' +
    'with a scope that describes exactly those files, lists only the symbols or ranges the worker must read, and the exact build, lint, and test commands. ' +
    'No source file may end above 350 lines. Slices touching the same file are ordered. Write the plan to tasks/plan.md. Give a PR title and a two line summary.',
  { model: MODEL.plan, label: 'plan', schema: { type: 'object', required: ['slices', 'prTitle', 'summary', 'tooBig'], properties: { slices: { type: 'array', items: sliceSchema }, prTitle: { type: 'string' }, summary: { type: 'string' }, tooBig: { type: 'boolean' } } } },
)
if (plan.tooBig || plan.slices.length > MAX_SLICES) return { stopped: 'too big', hint: 'split the task into two PRs', plan: plan.slices.map(s => s.message) }
if (input.planOnly) return { stopped: 'plan only', plan: plan.slices.map(s => s.message), prTitle: plan.prTitle }

phase('slices')
for (const s of plan.slices) {
  let done = await slicer(s, s.message)
  if (!done.ok) done = await slicer(s, s.message + ' (retry)', 'The last attempt failed: ' + done.note)
  if (!done.ok) throw new Error('slice failed twice: ' + s.message + ': ' + done.note)
}

const review = () =>
  agent(
    'You are the reviewer with a fresh context. Run `git diff ' + git.base + '...HEAD` and compare with tasks/plan.md. Report only gaps that affect ' +
      'correctness or the plan: a missing requirement, a broken edge case, a test that proves nothing, a change outside the plan, a crossed module ' +
      'boundary, a file above 350 lines. No style notes. When clean, write the PR body from templates/PULL_REQUEST_TEMPLATE.md: tick only what was ' +
      'done and delete every unchecked line. Summary of the change: ' + plan.summary,
    { model: MODEL.review, label: 'review', schema: { type: 'object', required: ['clean', 'gaps', 'prBody'], properties: { clean: { type: 'boolean' }, gaps: list, prBody: { type: 'string' } } } },
  )

phase('review')
let verdict = await review()
for (let round = 0; !verdict.clean && round < MAX_REVIEW_ROUNDS; round++) {
  await slicer({ message: 'fix(review): address review gaps', change: ['the files the gaps name'], verify: plan.slices[0].verify }, 'review fix ' + (round + 1), 'Gaps: ' + verdict.gaps.join('; '))
  verdict = await review()
}
if (!verdict.clean) return { stopped: 'review', gaps: verdict.gaps, branch: git.branch }

phase('pr')
const pr = await agent(
  'Push branch ' + git.branch + ' with `git push -u origin ' + git.branch + '`, then run `gh pr create --base ' + git.base + ' --title "' + plan.prTitle +
    '" --body-file <a temp file holding the body below>`. Body:\n' + verdict.prBody + '\nReply with the PR number and url.',
  { model: MODEL.run, label: 'open pr', schema: { type: 'object', required: ['number', 'url'], properties: { number: { type: 'number' }, url: { type: 'string' } } } },
)

phase('ci')
const watch = () =>
  agent('Run `gh pr checks ' + pr.number + ' --watch`. If a check failed, run `gh run view --log-failed` and put its last 40 lines in log.', {
    model: MODEL.run,
    label: 'ci',
    schema: { type: 'object', required: ['green', 'log'], properties: { green: { type: 'boolean' }, log: { type: 'string' } } },
  })
let ci = await watch()
for (let round = 0; !ci.green && round < MAX_CI_ROUNDS; round++) {
  await slicer({ message: 'fix(ci): make the failing check pass', change: ['the files the log names'], verify: plan.slices[0].verify }, 'ci fix ' + (round + 1), 'Failing log:\n' + ci.log + '\nAfter the commit run `git push`.')
  ci = await watch()
}
return { pr: pr.url, number: pr.number, ciGreen: ci.green, ciLog: ci.green ? '' : ci.log, review: 'clean', slicerRuns }
