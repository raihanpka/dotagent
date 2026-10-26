// Checks the portable ship skill that Codex, Antigravity, and other agents read from .agents/skills.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'
import { spawnSync } from 'node:child_process'

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

test('each Codex agent file has a name, a description, and developer instructions, and no Claude tool', () => {
  for (const role of ['reviewer']) {
    const toml = readFileSync(new URL(`../plugin/templates/.codex/agents/${role}.toml`, import.meta.url), 'utf8')
    assert.match(toml, new RegExp(`^name = "${role}"$`, 'm'))
    assert.match(toml, /^description = ".+"$/m)
    assert.match(toml, /^developer_instructions = """$/m)
    assert.ok(toml.trimEnd().endsWith('"""'), `${role} closes its string`)
    for (const tool of ['AskUserQuestion', 'ToolSearch', 'Workflow', 'run.sh']) {
      assert.ok(!toml.includes(tool), `${role} names ${tool}`)
    }
  }
})

test('the body names no tool that only Claude Code has', () => {
  for (const tool of ['AskUserQuestion', 'ToolSearch', 'Workflow', 'Agent', 'run.sh', 'phase plan']) {
    assert.ok(!skill.includes(tool), `found ${tool}`)
  }
})

test('the root skill is the same file as the template copy', () => {
  const root = readFileSync(new URL('../skills/dotagent-ship/SKILL.md', import.meta.url), 'utf8')
  assert.equal(root, skill)
})

test('docs/workflow.svg is drawn from docs/workflow.excalidraw', () => {
  const run = spawnSync('python3', ['scripts/workflow-svg.py', '--check'], { cwd: new URL('..', import.meta.url), encoding: 'utf8' })
  assert.equal(run.status, 0, run.stderr)
})
