// A small team: Sonnet leads (plan and review), Haiku workers each do one subtask, one at a time.
// A run ships one PR from docs/TODO.md: read only plan, workers that tick their subtasks, review, PR, then CI.
// A failing fix goes to Haiku once, then to Sonnet once, then the run stops and reports.
// Roles repeat agents/*.md in short form because a workflow agent gets only its prompt.
// Workers run one at a time on purpose: one working tree has one git index, so parallel commits collide.
export const meta = {
  name: 'ship-large',
  description: 'Plan a task into PRs, ship one PR as atomic subtasks, review it, open it, and fix failures with one Haiku try then one Sonnet try',
  phases: [
    { title: 'branch', detail: 'cut the branch' },
    { title: 'plan', detail: 'Sonnet plans the PRs, read only' },
    { title: 'subtasks', detail: 'one Haiku per subtask, in order' },
    { title: 'review', detail: 'Sonnet in a fresh context' },
    { title: 'pr', detail: 'push and open the PR' },
    { title: 'ci', detail: 'watch checks, fix ladder of 2 tries' },
  ],
}

const MODEL = { plan: 'sonnet', work: 'haiku', review: 'sonnet', run: 'haiku' }
const MAX_SUBTASKS = 10 // a backstop on cost, the planner is told to aim for 3 to 8 and to split a PR that grows
// A fix gets one try from Haiku, then one from Sonnet with the full context, then the run stops and reports.
const HAIKU_ROUNDS = 1
const SONNET_ROUNDS = 1
// Worst case: every subtask escalates, then review and CI each use every fix round. Anything above is a runaway.
const MAX_WORKER_RUNS = MAX_SUBTASKS * 2 + (HAIKU_ROUNDS + SONNET_ROUNDS) * 2

// args is the task as typed, pasted requirements included, or
// { task, context, decisions, planOnly, resume, run, base, branch }.
// resume ships the first unfinished PR of the plan already in docs/TODO.md, continuing where a stopped run left off. run is the path of hooks/run.sh, it flips the plan marker so
// planning stays read only. base and branch resume after questions.
const input = typeof args === 'string' ? { task: args } : args || {}
const task = input.task || (input.resume ? 'the first unfinished PR in docs/TODO.md' : '')
if (!task) throw new Error('pass the task as the argument, for example /dotagent:ship add a slugify helper')
const context =
  (input.context ? '\nRequirements as given, verbatim:\n' + input.context : '') +
  (input.decisions ? '\nDecisions the user already made, do not ask again:\n' + input.decisions : '')
const quote = text => "'" + text.replace(/'/g, "'\\''") + "'"
const phaseCmd = name => (input.run ? 'Run `sh ' + quote(input.run) + ' phase ' + name + '` first. ' : '')
// Plan labels say where work sits in the plan, a hook refuses them in a commit or PR title.
const NAMING = 'Names say what changed. Never put milestone, task, step, slice, or phase numbers, or "finishing task", or (#N), in a commit message or PR title, GitHub adds the PR number on merge. '

let workerRuns = 0
const list = { type: 'array', items: { type: 'string' } }
const subtaskSchema = {
  type: 'object',
  required: ['message', 'change', 'verify', 'detail'],
  properties: { id: { type: 'string' }, size: { type: 'string' }, ticked: { type: 'boolean' }, message: { type: 'string' }, change: list, read: list, verify: { type: 'string' }, detail: { type: 'string' } },
}
const question = {
  type: 'object',
  required: ['question', 'options', 'recommended', 'why'],
  properties: { question: { type: 'string' }, options: list, recommended: { type: 'string' }, why: { type: 'string' } },
}
const workResult = { type: 'object', required: ['commit', 'ok'], properties: { commit: { type: 'string' }, ok: { type: 'boolean' }, note: { type: 'string' } } }

// Runs one worker, Haiku unless told otherwise, counted against the spawn cap.
const worker = (s, label, note, model = MODEL.work) => {
  if (++workerRuns > MAX_WORKER_RUNS) throw new Error('worker spawn cap reached: ' + MAX_WORKER_RUNS)
  return agent(
    'You are the worker. Do exactly this subtask and nothing else. Simplest change that works, no unrelated cleanup. ' + '\n' +
      (workerRuns === 1 ? phaseCmd('build') : '') +
      'Commit message: ' + s.message + '\nChange: ' + s.change.join(', ') + '\nRead only: ' + (s.read || []).join(', ') + '\nVerify: ' + s.verify + '\n' +
      (s.detail ? 'Detail: ' + s.detail + '\n' : '') +
      (s.id ? 'Tick subtask ' + s.id + ' in docs/TODO.md when it is done. ' : 'Add one ticked line for this fix under ## fixes in docs/TODO.md. ') +
      'Read with offset and limit. Write a failing test first when behavior is added. Run the verify commands, format first, never weaken a check. The git hooks refuse an unformatted or unlinted commit, and --no-verify is refused. ' +
      'Stage only the Change files (a fix: the files the notes name) and commit with the one line message. docs/TODO.md is untracked, never stage it. ' +
      NAMING + 'Never push unless told below. ' + (note || ''),
    { model, label, schema: workResult },
  )
}

phase('branch')
const git =
  input.base && input.branch
    ? { base: input.base, branch: input.branch }
    : await agent(
        'Find the default branch with `git symbolic-ref --short refs/remotes/origin/HEAD`. Create and switch to a new branch from it named ' +
          'feat/<short-slug>, the slug says what the work builds' + (input.resume ? ' (take it from the first unfinished PR in docs/TODO.md)' : '') + ', or switch to that branch when it already exists. Task: ' + task + '. Run only those git commands. Reply with the base and the branch.',
        { model: MODEL.run, label: 'branch', schema: { type: 'object', required: ['base', 'branch'], properties: { base: { type: 'string' }, branch: { type: 'string' } } } },
      )

phase('plan')
const plan = await agent(
  phaseCmd('plan') + 'You are the planner. Read only: the one file you may write is docs/TODO.md, a hook refuses every other write. Read little: grep for symbols, then read ranges. ' +
    (input.resume
      ? 'Do not plan again. Read docs/TODO.md and return the first PR that has an unticked subtask or an empty done: line, exactly as written, each subtask with ticked true or false. '
      : 'Cut this task into ordered PRs, each PR into subtasks: ' + task + context + '\n' +
        'Write docs/TODO.md, replacing any older one: the goal, the requirements verbatim, the decisions, then one section per PR with its title as `type(scope): summary`, branch, read, needs (another PR that must merge first, or none), ' +
        'then one unticked "- [ ]" line per subtask: `id (S, M, or L) `commit message`. detail with the files. Verify: commands`, and an empty done: line for the PR. End with ## fixes and ## noticed. Prefer PRs that stand alone. ' +
        'A PR is reviewable in one sitting, usually 3 to 8 subtasks and a few hundred changed lines, more only for mechanical or generated change. Split a PR that grows. ') +
    'Number the requirements R1, R2 when there is more than one point and give each PR a covers: line, every R in exactly one PR, an R no PR covers goes under questions. Return the first PR only, with prsLeft, the number of PRs after it, and its covers. A subtask builds and passes tests alone, changes 1 to 3 files inside one module, has a one line `type(scope): summary` commit message ' +
    'with a scope that is the module the files belong to, lists only the symbols or ranges the worker must read, and the exact format (the fixing command), build, lint, and test commands. ' + NAMING +
    'Prefer small files with one responsibility: plan a split as its own subtask when a file would pass about 500 lines or take a second responsibility. A refactor is its own subtask, new behavior and its tests share one. Subtasks touching the same file are ordered. ' +
    'Give the PR title and a two line summary. Never guess: put every ambiguous requirement under questions, each with 2 to 3 options, your recommended option, and why from a best practice or what the repo already does.',
  { model: MODEL.plan, label: 'plan', schema: { type: 'object', required: ['subtasks', 'prTitle', 'summary', 'prsLeft'], properties: { subtasks: { type: 'array', items: subtaskSchema }, prTitle: { type: 'string' }, summary: { type: 'string' }, prsLeft: { type: 'number' }, covers: list, questions: { type: 'array', items: question } } } },
)
if (plan.questions && plan.questions.length) return { stopped: 'questions', questions: plan.questions, base: git.base, branch: git.branch }
if (plan.subtasks.length > MAX_SUBTASKS) return { stopped: 'too many subtasks', hint: 'ask the planner to split this PR in two', plan: plan.subtasks.map(s => s.message) }
if (input.planOnly) return { stopped: 'plan only', plan: plan.subtasks.map(s => s.message), prTitle: plan.prTitle, prsLeft: plan.prsLeft }

// Every subtask's check, so a fix is proven against all of them and not just the first one's.
const verifyAll = [...new Set(plan.subtasks.map(s => s.verify))].join('; ')

phase('subtasks')
for (const s of plan.subtasks) {
  if (s.ticked) continue
  let done = await worker(s, s.message)
  if (!done.ok) done = await worker(s, s.message + ' (escalated)', 'Haiku failed: ' + done.note + '. Take the time you need, read what the subtask depends on.', MODEL.plan)
  if (!done.ok) return { stopped: 'subtask', subtask: s.message, note: done.note, branch: git.branch }
}

const review = prior =>
  agent(
    'You are the reviewer with a fresh context. Run `git diff ' + git.base + '...HEAD` and compare with this PR in docs/TODO.md, every subtask ticked' + (plan.covers && plan.covers.length ? ', and each of these requirements present in the diff: ' + plan.covers.join(', ') + ' (later PRs own the others)' : '') + '. Run these checks once: ' + verifyAll + '. ' +
      (prior ? 'Gaps reported before, confirm each is closed first: ' + prior.join('; ') + '. ' : '') + 'Report only gaps that affect ' +
      'correctness or the plan: a missing requirement, a broken edge case, a test that proves nothing, a change outside the plan, a crossed module ' +
      'boundary, a refactor mixed with a feature, a commit message or PR title with a milestone, task, step, or slice label, a file past about 500 lines or with a second responsibility. No style notes. When clean, write the PR body from .github/PULL_REQUEST_TEMPLATE.md: tick only what was ' +
      'done and delete every unchecked line. Never add a generated-by line, a Co-Authored-By trailer, or a tool name. Summary of the change: ' + plan.summary,
    { model: MODEL.review, label: 'review', schema: { type: 'object', required: ['clean', 'gaps', 'prBody'], properties: { clean: { type: 'boolean' }, gaps: list, prBody: { type: 'string' } } } },
  )

// Fix ladder: Haiku once, then Sonnet once. A round only runs while the check is still red.
const fixModel = round => (round < HAIKU_ROUNDS ? MODEL.work : MODEL.plan)
const FIX_ROUNDS = HAIKU_ROUNDS + SONNET_ROUNDS

phase('review')
let verdict = await review()
for (let round = 0; !verdict.clean && round < FIX_ROUNDS; round++) {
  await worker({ message: 'fix(review): address review gaps', change: ['the files named in the notes'], verify: verifyAll }, 'review fix ' + (round + 1), 'Gaps: ' + verdict.gaps.join('; '), fixModel(round))
  verdict = await review(verdict.gaps)
}
if (!verdict.clean) return { stopped: 'review', gaps: verdict.gaps, branch: git.branch }

phase('pr')
const pr = await agent(
  phaseCmd('done') + 'If `gh pr list --head ' + git.branch + '` already shows an open PR, reply with its number and url and do nothing else. Otherwise push branch ' + git.branch + ' with `git push -u origin ' + git.branch + '`, then run `gh pr create --base ' + git.base + ' --title ' + quote(plan.prTitle) +
    ' --body-file <a temp file holding the body below>`. Body:\n' + verdict.prBody + '\nReply with the PR number and url.',
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
for (let round = 0; !ci.green && round < FIX_ROUNDS; round++) {
  await worker({ message: 'fix(ci): make the failing check pass', change: ['the files named in the log'], verify: verifyAll }, 'ci fix ' + (round + 1), 'Failing log:\n' + ci.log + '\nAfter the commit, run `git push`. Pushing is allowed for this fix.', fixModel(round))
  ci = await watch()
}
return { pr: pr.url, number: pr.number, ciGreen: ci.green, ciLog: ci.green ? '' : ci.log, review: 'clean', prsLeft: plan.prsLeft, covers: plan.covers || [], workerRuns }
