// Checks the portable ship skill that Codex, Antigravity, and other agents read from .agents/skills.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const skill = readFileSync(new URL('../plugin/templates/.agents/skills/dotagent-ship/SKILL.md', import.meta.url), 'utf8')
const front = skill.match(/^---\n([\s\S]*?)\n---/)

test('frontmatter has a lowercase name under 64 characters and a quoted description', () => {
  assert.ok(front, 'frontmatter present')
  const name = front[1].match(/^name: (.+)$/m)?.[1]
  assert.equal(name, 'dotagent-ship')
  assert.ok(name.length < 64 && /^[a-z0-9-]+$/.test(name))
  assert.match(front[1], /^description: ".+"$/m)
})

test('the body names no tool that only Claude Code has', () => {
  for (const tool of ['AskUserQuestion', 'ToolSearch', 'Workflow', 'Agent', 'run.sh', 'phase plan']) {
    assert.ok(!skill.includes(tool), `found ${tool}`)
  }
})
