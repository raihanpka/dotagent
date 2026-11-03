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
  const body = skill.replaceAll('.dotagent/run.sh', '')
  for (const tool of ['AskUserQuestion', 'ToolSearch', 'Workflow', 'Agent', 'run.sh', 'phase plan']) {
    assert.ok(!body.includes(tool), `found ${tool}`)
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

test('the review command posts only what the user chooses and never merges or pushes the PR branch', () => {
  const review = readFileSync(new URL('../plugin/skills/review/SKILL.md', import.meta.url), 'utf8')
  assert.match(review, /^description: ".+"$/m)
  assert.match(review, /^argument-hint: ".+"$/m)
  assert.ok(review.includes('gh pr review'), 'no gh pr review')
  assert.ok(review.includes('gh api -X POST'), 'no gh api review write')
  assert.ok(!review.includes('gh pr merge'), 'the review command merges')
  assert.ok(review.includes('Approve only when the user chooses it'), 'approve is not gated by the user')
  assert.ok(review.includes('no argument'), 'no unfinished-work mode')
  assert.ok(review.includes('docs/TODO.md'), 'the unfinished-work mode does not read the TODO')
  assert.ok(review.includes('sh "$RUN" status'), 'the unfinished-work mode does not check the state')
})

test('setup asks which agent runs dotagent and branches on the four answers', () => {
  const setup = readFileSync(new URL('../plugin/SETUP.md', import.meta.url), 'utf8')
  for (const value of ['claude', 'codex', 'both', 'other']) assert.ok(setup.includes(`\`${value}\``), `SETUP.md does not offer ${value}`)
  assert.ok(setup.includes('set agents'), 'SETUP.md does not save agents')
  assert.ok(setup.includes('.codex/agents/reviewer.toml'), 'SETUP.md does not write the Codex reviewer')
  assert.ok(setup.includes('/hooks'), 'SETUP.md does not ask the user to trust the Codex hooks')
  assert.ok(!/Claude Code only, so skip step 2/.test(setup), 'SETUP.md still says the plugin is Claude Code only')
})

test('the setup skill names the agent choice in its description', () => {
  const setup = readFileSync(new URL('../plugin/skills/setup/SKILL.md', import.meta.url), 'utf8')
  assert.match(setup, /Claude Code, Codex, both, or another/)
})
