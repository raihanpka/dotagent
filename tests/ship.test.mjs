// Checks the Claude Code ship skill by structure: a small core, references read on demand, one path for every task,
// the gate once per commit, and no model name. It looks for headings and commands, not for exact sentences.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync, readdirSync } from 'node:fs'

const dir = new URL('../plugin/skills/ship/', import.meta.url)
const read = (path) => readFileSync(new URL(path, dir), 'utf8')
const skill = read('SKILL.md')
const references = readdirSync(new URL('references/', dir)).filter((f) => f.endsWith('.md'))
const all = [skill, ...references.map((f) => read(`references/${f}`))]
const reviewer = readFileSync(new URL('../plugin/agents/reviewer.md', import.meta.url), 'utf8')
const front = skill.match(/^---\n([\s\S]*?)\n---/)
const headings = (text) => [...text.matchAll(/^## (.+)$/gm)].map((m) => m[1])

test('frontmatter has a quoted description of one short sentence and an argument hint', () => {
  assert.ok(front, 'frontmatter present')
  const description = front[1].match(/^description: "(.+)"$/m)?.[1]
  assert.ok(description, 'quoted description')
  assert.ok(description.length < 220, `description is ${description.length} characters`)
  assert.match(front[1], /^argument-hint: ".+"$/m)
})

test('the core stays small and every reference is linked from it and exists', () => {
  assert.ok(Buffer.byteLength(skill) < 10000, `SKILL.md is ${Buffer.byteLength(skill)} bytes, move text to a reference`)
  assert.deepEqual(references.sort(), ['merge.md', 'plan.md'])
  for (const file of references) {
    assert.ok(skill.includes('${CLAUDE_SKILL_DIR}/references/' + file), `${file} is not linked from SKILL.md`)
  }
})

test('the core keeps what every run needs, the references hold the rest', () => {
  for (const heading of ['Questions', 'Delegating', 'Start', 'Build', 'Resume', 'Limits', 'Receipt and guardrails']) {
    assert.ok(headings(skill).includes(heading), `SKILL.md has no "${heading}" section`)
  }
  assert.ok(headings(read('references/plan.md')).includes('The TODO'))
  assert.ok(headings(read('references/merge.md')).includes('Merge'))
  assert.ok(!headings(skill).includes('Merge'), 'Merge belongs in references/merge.md')
})

test('no removed setting, agent, workflow, or model name is left anywhere in the skill', () => {
  for (const text of all) {
    for (const word of ['scale', 'ship-large', 'worker', 'planner', '`large`', '`medium`', 'gate pass', 'autopilot', 'checkpoint', '`adapt`']) {
      assert.ok(!text.toLowerCase().includes(word), `found ${word}`)
    }
    assert.ok(!/sonnet|opus|haiku|gpt|gemini/i.test(text), 'a model name is in the skill')
  }
  assert.ok(!existsSync(new URL('../plugin/workflows', import.meta.url)), 'plugin/workflows is gone')
})

test('the lead builds, a reviewer checks, and a one sentence diff skips the plan', () => {
  assert.match(skill, /one sentence/)
  assert.match(skill, /`reviewer`/)
  assert.match(skill, /## The team/)
  assert.match(skill, /Do not hand a subtask to another agent/)
})

test('the gate is recorded once per commit through run.sh gate', () => {
  assert.match(skill, /gate check/)
  assert.match(skill, /gate run </)
  assert.match(headings(skill).join('\n'), /Resume/)
  assert.match(skill.slice(skill.indexOf('## Resume')), /gate check/)
})

test('every spawn gets an objective, an output, and boundaries', () => {
  const brief = skill.slice(skill.indexOf('## Delegating'), skill.indexOf('## Style skills'))
  for (const label of ['Objective', 'Output', 'Boundaries']) assert.ok(brief.includes(label), `no ${label}`)
})

test('the TODO layout keeps the fields the guard reads', () => {
  const plan = read('references/plan.md')
  for (const field of ['## PR 1:', 'files:', 'done:', '- [ ]', 'branch:', 'needs:']) assert.ok(plan.includes(field), `no ${field}`)
})

test('the three modes are local, ask, and auto', () => {
  const merge = read('references/merge.md')
  for (const mode of ['local', 'ask', 'auto']) assert.ok(merge.includes(`**${mode}**`), `merge.md does not explain ${mode}`)
})

test('a merge is a squash after a rebase, with a safe push', () => {
  const merge = read('references/merge.md')
  for (const token of ['--squash', '--force-with-lease', 'git rebase', '--delete-branch']) assert.ok(merge.includes(token), `no ${token}`)
})

test('the reviewer runs on whichever model the session uses', () => {
  assert.match(reviewer, /^model: inherit$/m)
})
