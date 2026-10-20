// Runs workflows/ship.js against a fake agent to check its control flow, limits, and models.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const source = readFileSync(new URL('../workflows/ship.js', import.meta.url), 'utf8').replace('export const meta', 'const meta')
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor

const slices = n => Array.from({ length: n }, (_, i) => ({ message: `feat(m${i}): step ${i}`, change: [`a${i}.txt`], verify: 'make test' }))

// run(args, script): executes the workflow with a fake agent whose answers a test can override.
async function run(args, over = {}) {
  const calls = []
  const phases = []
  const answers = {
    branch: () => ({ base: 'main', branch: 'feat/x' }),
    plan: () => ({ slices: slices(3), prTitle: 'feat(x): add x', summary: 's', tooBig: false }),
    slice: () => ({ commit: 'abc', ok: true }),
    review: () => ({ clean: true, gaps: [], prBody: 'body' }),
    'open pr': () => ({ number: 7, url: 'https://example/pr/7' }),
    ci: () => ({ green: true, log: '' }),
    ...over,
  }
  const agent = async (prompt, opt) => {
    calls.push({ prompt, ...opt })
    const key = /You are the slicer/.test(prompt) ? 'slice' : opt.label
    return answers[key](prompt, calls.length)
  }
  const fn = new AsyncFunction('agent', 'phase', 'log', 'args', source)
  const result = await fn(agent, p => phases.push(p), () => {}, args)
  return { result, calls, phases }
}

test('happy path runs every phase and one slicer per slice', async () => {
  const { result, phases, calls } = await run('add x')
  assert.deepEqual(phases, ['branch', 'plan', 'slices', 'review', 'pr', 'ci'])
  assert.equal(result.slicerRuns, 3)
  assert.equal(result.ciGreen, true)
  assert.equal(calls.filter(c => /You are the slicer/.test(c.prompt)).length, 3)
})

test('planner and reviewer use sonnet, slicers use haiku', async () => {
  const { calls } = await run('add x')
  assert.equal(calls.find(c => c.label === 'plan').model, 'sonnet')
  assert.equal(calls.find(c => c.label === 'review').model, 'sonnet')
  assert.equal(calls.find(c => /slicer/.test(c.prompt)).model, 'haiku')
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

test('a task the planner calls too big stops before any slicer', async () => {
  const { result, calls } = await run('add x', { plan: () => ({ slices: slices(8), prTitle: 't', summary: 's', tooBig: true }) })
  assert.equal(result.stopped, 'too big')
  assert.equal(calls.filter(c => /slicer/.test(c.prompt)).length, 0)
})

test('more than 8 slices is too big even when the flag is false', async () => {
  const { result } = await run('add x', { plan: () => ({ slices: slices(9), prTitle: 't', summary: 's', tooBig: false }) })
  assert.equal(result.stopped, 'too big')
})

test('planOnly returns the plan and spawns no slicer', async () => {
  const { result, calls } = await run({ task: 'add x', planOnly: true })
  assert.equal(result.stopped, 'plan only')
  assert.equal(calls.filter(c => /slicer/.test(c.prompt)).length, 0)
})

test('a slice that fails once is retried, twice escalates to sonnet, then stops', async () => {
  let n = 0
  const flaky = await run('add x', { slice: () => ({ commit: 'abc', ok: ++n > 1, note: 'boom' }) })
  assert.equal(flaky.result.slicerRuns, 4)
  const esc = await run('add x', { slice: (p, c) => ({ commit: 'abc', ok: /Haiku failed twice/.test(p), note: 'boom' }) })
  assert.ok(esc.calls.some(c => /escalated/.test(c.label) && c.model === 'sonnet'))
  await assert.rejects(run('add x', { slice: () => ({ commit: '', ok: false, note: 'boom' }) }), /after escalation/)
})

test('review fixes go to haiku twice, then sonnet once, then stop', async () => {
  const { result, calls } = await run('add x', { review: () => ({ clean: false, gaps: ['g'], prBody: '' }) })
  assert.equal(result.stopped, 'review')
  assert.equal(calls.filter(c => c.label === 'review').length, 4)
  const fixes = calls.filter(c => /review fix/.test(c.label))
  assert.deepEqual(fixes.map(c => c.model), ['haiku', 'haiku', 'sonnet'])
})

test('CI fixes go to haiku twice, then sonnet once, then report the log', async () => {
  const { result, calls } = await run('add x', { ci: () => ({ green: false, log: 'lint failed' }) })
  assert.equal(result.ciGreen, false)
  assert.equal(result.ciLog, 'lint failed')
  assert.equal(calls.filter(c => c.label === 'ci').length, 4)
  assert.deepEqual(calls.filter(c => /ci fix/.test(c.label)).map(c => c.model), ['haiku', 'haiku', 'sonnet'])
})

test('the slicer spawn cap stops a runaway', async () => {
  await assert.rejects(
    run('add x', { plan: () => ({ slices: slices(8), prTitle: 't', summary: 's', tooBig: false }), slice: () => ({ commit: 'c', ok: false, note: 'x' }) }),
    /spawn cap|after escalation/,
  )
})

test('no task is an error', async () => {
  await assert.rejects(run({}), /pass the task/)
})
