// Checks the portable ship skill that Codex, Antigravity, and other agents read from .agents/skills.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'

const skill = readFileSync(new URL('../plugin/templates/.agents/skills/dotagent-ship/SKILL.md', import.meta.url), 'utf8')
const front = skill.match(/^---\n([\s\S]*?)\n---/)

test('frontmatter has a lowercase name under 64 characters and a quoted description', () => {
  assert.ok(front, 'frontmatter present')
  const name = front[1].match(/^name: (.+)$/m)?.[1]
  assert.equal(name, 'dotagent-ship')
  assert.ok(name.length < 64 && /^[a-z0-9-]+$/.test(name))
  assert.match(front[1], /^description: ".+"$/m)
})

test('every raw file the setup guide fetches exists in the repo', () => {
  const guide = readFileSync(new URL('../docs/SETUP-AGENT.md', import.meta.url), 'utf8')
  const base = 'https://raw.githubusercontent.com/raihanpka/dotagent/main/'
  const paths = [...guide.matchAll(/`((?:plugin\/templates|skills)\/[^`\s]+)`/g)].map((m) => m[1])
  assert.ok(paths.length >= 8, 'guide names the files')
  for (const path of paths) {
    assert.ok(existsSync(new URL(`../${path}`, import.meta.url)), `missing ${path}`)
  }
  assert.ok(guide.includes(base), 'guide uses the raw base URL')
})

test('the body names no tool that only Claude Code has', () => {
  for (const tool of ['AskUserQuestion', 'ToolSearch', 'Workflow', 'Agent', 'run.sh', 'phase plan']) {
    assert.ok(!skill.includes(tool), `found ${tool}`)
  }
})
