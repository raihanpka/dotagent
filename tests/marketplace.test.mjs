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

test('the root Codex hook file runs the guard with --client codex, on the tools Codex names', () => {
  const hooks = JSON.parse(read('hooks/hooks.json'))
  const commands = Object.values(hooks.hooks).flat().flatMap((group) => group.hooks.map((h) => h.command))
  assert.ok(commands.length >= 2, 'no hook commands')
  for (const command of commands) {
    assert.ok(command.includes('${PLUGIN_ROOT}/plugin/hooks/run.sh'), `not the plugin guard: ${command}`)
    assert.ok(command.endsWith('--client codex'), `no --client codex: ${command}`)
  }
  assert.ok(hooks.hooks.PreToolUse[0].matcher.split('|').includes('apply_patch'), 'PreToolUse does not match apply_patch')
  assert.ok(hooks.hooks.PreToolUse[0].matcher.split('|').includes('spawn_agent'), 'PreToolUse does not match spawn_agent')
})
