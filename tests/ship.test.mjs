// Checks the Claude Code ship skill: one path for every task, the lead builds, a fresh reviewer, the gate once per commit.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'

const reviewer = readFileSync(new URL('../plugin/agents/reviewer.md', import.meta.url), 'utf8')

const skill = readFileSync(new URL('../plugin/skills/ship/SKILL.md', import.meta.url), 'utf8')
const front = skill.match(/^---\n([\s\S]*?)\n---/)

test('frontmatter has a quoted description of one short sentence and an argument hint', () => {
  assert.ok(front, 'frontmatter present')
  const description = front[1].match(/^description: "(.+)"$/m)?.[1]
  assert.ok(description, 'quoted description')
  assert.ok(description.length < 220, `description is ${description.length} characters`)
  assert.match(front[1], /^argument-hint: ".+"$/m)
})

test('the skill names no removed setting, agent, or workflow', () => {
  for (const word of ['scale', 'ship-large', 'worker', 'planner', 'haiku', '`large`', '`medium`']) {
    assert.ok(!skill.toLowerCase().includes(word), `found ${word}`)
  }
  assert.ok(!existsSync(new URL('../plugin/workflows', import.meta.url)), 'plugin/workflows is gone')
})

test('one sentence diffs skip the plan, everything else plans, builds, and is reviewed', () => {
  assert.match(skill, /describe the whole diff in one sentence, there is no plan and no TODO/)
  assert.match(skill, /build each subtask yourself/)
  assert.match(skill, /spawn `reviewer`/)
})

test('the gate runs once per commit through run.sh gate', () => {
  assert.match(skill, /gate check/)
  assert.match(skill, /gate pass/)
  assert.match(skill, /Resume[\s\S]*gate check/)
})

test('every spawn gets an objective, an output, and boundaries', () => {
  assert.match(skill, /## Delegating[\s\S]*Objective[\s\S]*Output[\s\S]*Boundaries/)
})

test('a fix gets two tries, then the run stops', () => {
  assert.match(skill, /two tries from you/)
})

test('the workflow names no model, so it runs on whichever one the session uses', () => {
  for (const text of [skill, reviewer]) {
    assert.ok(!/sonnet|opus|haiku|gpt|gemini/i.test(text), 'a model name is in the skill or the agent')
  }
  assert.match(reviewer, /^model: inherit$/m)
})
