// Runs workflows/ship-large.js against a fake agent to check its control flow, limits, and models.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const source = readFileSync(new URL('../plugin/workflows/ship-large.js', import.meta.url), 'utf8').replace('export const meta', 'const meta')
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

const subtasks = n => Array.from({ length: n }, (_, i) => ({ id: `1.${i + 1}`, size: 'S', message: `feat(m${i}): add m${i}`, change: [`a${i}.txt`], verify: 'make test', detail: `edit a${i}.txt` }))

// run(args, script): executes the workflow with a fake agent whose answers a test can override.
async function run(args, over = {}) {
  const calls = []
  const phases = []
  const answers = {
    branch: () => ({ base: 'main', branch: 'feat/x' }),
    plan: () => ({ subtasks: subtasks(3), prTitle: 'feat(x): add x', summary: 's', prsLeft: 0 }),
    work: () => ({ commit: 'abc', ok: true }),
    review: () => ({ clean: true, gaps: [], prBody: 'body' }),
    'open pr': () => ({ number: 7, url: 'https://example/pr/7' }),
    ci: () => ({ green: true, log: '' }),
    ...over,
  }
  const agent = async (prompt, opt) => {
    calls.push({ prompt, ...opt })
    const key = /You are the worker/.test(prompt) ? 'work' : opt.label
    return answers[key](prompt, calls.length)
  }
  const fn = new AsyncFunction('agent', 'phase', 'log', 'args', source)
  const result = await fn(agent, p => phases.push(p), () => {}, args)
  return { result, calls, phases }
}

test('happy path runs every phase and one worker per subtask', async () => {
  const { result, phases, calls } = await run('add x')
  assert.deepEqual(phases, ['branch', 'plan', 'subtasks', 'review', 'pr', 'ci'])
  assert.equal(result.workerRuns, 3)
  assert.equal(result.ciGreen, true)
  assert.equal(calls.filter(c => /You are the worker/.test(c.prompt)).length, 3)
})

test('planner and reviewer use sonnet, workers use haiku', async () => {
  const { calls } = await run('add x')
  assert.equal(calls.find(c => c.label === 'plan').model, 'sonnet')
  assert.equal(calls.find(c => c.label === 'review').model, 'sonnet')
  assert.equal(calls.find(c => /You are the worker/.test(c.prompt)).model, 'haiku')
})

test('pasted requirements reach the planner verbatim', async () => {
  const { calls } = await run({ task: 'add x', context: 'PM says: must be idempotent' })
  assert.match(calls.find(c => c.label === 'plan').prompt, /must be idempotent/)
})

test('meta phases are objects with a title that phase() uses', async () => {
  const meta = new Function(source.replace(/^[\s\S]*?(const meta = \{[\s\S]*?\n\})\n[\s\S]*$/, '$1; return meta'))()
  assert.ok(meta.phases.every(p => typeof p.title === 'string'))
  const { phases } = await run('add x')
  assert.deepEqual(phases, meta.phases.map(p => p.title))
})

test('a PR past the subtask backstop stops before any worker', async () => {
  const { result, calls } = await run('add x', { plan: () => ({ subtasks: subtasks(11), prTitle: 't', summary: 's', prsLeft: 0 }) })
  assert.equal(result.stopped, 'too many subtasks')
  assert.equal(calls.filter(c => /You are the worker/.test(c.prompt)).length, 0)
})

test('ten subtasks is still fine and the result says how many PRs are left', async () => {
  const { result } = await run('add x', { plan: () => ({ subtasks: subtasks(10), prTitle: 't', summary: 's', prsLeft: 2 }) })
  assert.equal(result.prsLeft, 2)
  assert.equal(result.workerRuns, 10)
})

test('planOnly returns the plan and spawns no worker', async () => {
  const { result, calls } = await run({ task: 'add x', planOnly: true })
  assert.equal(result.stopped, 'plan only')
  assert.equal(calls.filter(c => /You are the worker/.test(c.prompt)).length, 0)
})

test('a subtask that fails once escalates to sonnet, failing again stops', async () => {
  let n = 0
  const flaky = await run('add x', { work: () => ({ commit: 'abc', ok: ++n > 1 && true, note: 'boom' }) })
  assert.equal(flaky.result.workerRuns, 4)
  assert.ok(flaky.calls.some(c => /escalated/.test(c.label) && c.model === 'sonnet'))
  const dead = await run('add x', { work: () => ({ commit: '', ok: false, note: 'boom' }) })
  assert.equal(dead.result.stopped, 'subtask')
  assert.equal(dead.result.note, 'boom')
})

test('review fixes go to haiku once, then sonnet once, then stop', async () => {
  const { result, calls } = await run('add x', { review: () => ({ clean: false, gaps: ['g'], prBody: '' }) })
  assert.equal(result.stopped, 'review')
  assert.equal(calls.filter(c => c.label === 'review').length, 3)
  const fixes = calls.filter(c => /review fix/.test(c.label))
  assert.deepEqual(fixes.map(c => c.model), ['haiku', 'sonnet'])
})

test('CI fixes go to haiku once, then sonnet once, then report the log', async () => {
  const { result, calls } = await run('add x', { ci: () => ({ green: false, log: 'lint failed' }) })
  assert.equal(result.ciGreen, false)
  assert.equal(result.ciLog, 'lint failed')
  assert.equal(calls.filter(c => c.label === 'ci').length, 3)
  assert.deepEqual(calls.filter(c => /ci fix/.test(c.label)).map(c => c.model), ['haiku', 'sonnet'])
})

test('the worst case fits the worker cap', async () => {
  let reviews = 0
  const { result } = await run('add x', {
    plan: () => ({ subtasks: subtasks(10), prTitle: 't', summary: 's', prsLeft: 0 }),
    work: p => ({ commit: 'c', ok: /Haiku failed|fix\(/.test(p), note: 'x' }),
    review: () => ({ clean: ++reviews > 2, gaps: ['g'], prBody: 'b' }),
    ci: () => ({ green: false, log: 'red' }),
  })
  assert.equal(result.workerRuns, 24)
})

test('ambiguous requirements stop the run before any subtask', async () => {
  const { result, calls } = await run('add x', {
    plan: () => ({ subtasks: subtasks(2), prTitle: 't', summary: 's', prsLeft: 0, questions: [{ question: 'which currency?', options: ['usd', 'eur'], recommended: 'usd', why: 'the repo is usd' }] }),
  })
  assert.equal(result.stopped, 'questions')
  assert.equal(result.questions[0].recommended, 'usd')
  assert.deepEqual([result.base, result.branch], ['main', 'feat/x'])
  assert.equal(calls.filter(c => c.model === 'haiku' && /^feat/.test(c.label)).length, 0)
})

test('the PR title is shell quoted and fixes run every subtask check', async () => {
  const { calls } = await run('add x', {
    plan: () => ({ subtasks: [{ message: 'feat(a): a', change: ['a'], verify: 'make a' }, { message: 'feat(b): b', change: ['b'], verify: 'make b' }], prTitle: "feat(a): it's $HOME", summary: 's', prsLeft: 0 }),
    review: () => ({ clean: true, gaps: [], prBody: 'b' }),
  })
  assert.match(calls.find(c => c.label === 'open pr').prompt, /--title 'feat\(a\): it'\\''s \$HOME'/)
  assert.match(calls.find(c => c.label === 'review').prompt, /make a; make b/)
})

test('a resumed run skips the branch step and carries the user decisions', async () => {
  const { calls } = await run({ task: 'add x', base: 'main', branch: 'feat/x', decisions: 'currency: usd', run: '/p/hooks/run.sh' }, {
    review: () => ({ clean: true, gaps: [], prBody: 'b' }),
  })
  assert.equal(calls.filter(c => c.label === 'branch').length, 0)
  const planPrompt = calls.find(c => c.label === 'plan').prompt
  assert.match(planPrompt, /currency: usd/)
  assert.match(planPrompt, /phase plan/)
  assert.match(planPrompt, /docs\/TODO\.md/)
  assert.match(calls.find(c => /^feat/.test(c.label)).prompt, /phase build/)
  assert.match(calls.find(c => c.label === 'open pr').prompt, /phase done/)
})

test('workers tick their subtask and never carry plan labels', async () => {
  const { calls } = await run('add x', { review: () => ({ clean: true, gaps: [], prBody: 'b' }) })
  const prompt = calls.find(c => /^feat/.test(c.label)).prompt
  assert.match(prompt, /Tick subtask 1\.1 in docs\/TODO\.md/)
  assert.match(prompt, /Never put milestone, task, step, slice/)
  assert.match(prompt, /never stage it/)
})

test('resume ships the first unfinished PR from the TODO without a task and skips ticked subtasks', async () => {
  const { calls, result } = await run({ resume: true }, {
    plan: () => ({ subtasks: subtasks(3).map((s, i) => ({ ...s, ticked: i === 0 })), prTitle: 'feat(x): add x', summary: 's', prsLeft: 0 }),
  })
  assert.match(calls.find(c => c.label === 'branch').prompt, /docs\/TODO\.md/)
  assert.match(calls.find(c => c.label === 'plan').prompt, /Do not plan again/)
  assert.equal(result.workerRuns, 2)
  assert.equal(result.ciGreen, true)
})

test('the PR step reuses an open PR instead of creating a second one', async () => {
  const { calls } = await run('add x')
  assert.match(calls.find(c => c.label === 'open pr').prompt, /already shows an open PR/)
})

test('the PR body never carries a generated-by line', async () => {
  const { calls } = await run('add x')
  assert.match(calls.find(c => c.label === 'review').prompt, /Never add a generated-by line, a Co-Authored-By trailer/)
})

test('numbered requirements reach the planner and the reviewer sees only this PR\'s covers', async () => {
  const { calls, result } = await run('add x', {
    plan: () => ({ subtasks: subtasks(1), prTitle: 'feat(x): add x', summary: 's', prsLeft: 1, covers: ['R1', 'R2'] }),
    review: () => ({ clean: true, gaps: [], prBody: 'b' }),
  })
  assert.match(calls.find(c => c.label === 'plan').prompt, /Number the requirements R1, R2/)
  assert.match(calls.find(c => c.label === 'review').prompt, /R1, R2 \(later PRs own the others\)/)
  assert.deepEqual(result.covers, ['R1', 'R2'])
})

test('no covers means the reviewer prompt names no requirement list', async () => {
  const { calls } = await run('add x')
  assert.doesNotMatch(calls.find(c => c.label === 'review').prompt, /later PRs own/)
})

test('no task is an error', async () => {
  await assert.rejects(run({}), /pass the task/)
})
