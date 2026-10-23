// Checks the Codex plugin and marketplace at the repo root, and that they match the Claude Code plugin.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'

const read = (path) => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8')

test('the root skill is the same file as the template setup copies', () => {
  assert.equal(read('skills/dotagent-ship/SKILL.md'), read('plugin/templates/.agents/skills/dotagent-ship/SKILL.md'))
})

test('the Codex plugin and the Claude Code plugin have the same version', () => {
  const codex = JSON.parse(read('.codex-plugin/plugin.json'))
  const claude = JSON.parse(read('plugin/.claude-plugin/plugin.json'))
  assert.equal(codex.name, 'dotagent')
  assert.equal(codex.version, claude.version)
  assert.match(claude.version, /^\d+\.\d+\.\d+$/)
})

test('the marketplace points at the root plugin, which has a manifest and a skill', () => {
  const market = JSON.parse(read('.agents/plugins/marketplace.json'))
  const entry = market.plugins.find((p) => p.name === 'dotagent')
  assert.ok(entry, 'dotagent entry present')
  assert.equal(entry.source.source, 'local')
  assert.equal(entry.source.path, './')
  assert.ok(existsSync(new URL('../.codex-plugin/plugin.json', import.meta.url)))
  assert.ok(existsSync(new URL('../skills/dotagent-ship/SKILL.md', import.meta.url)))
})
