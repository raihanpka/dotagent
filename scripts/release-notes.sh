#!/usr/bin/env bash
# Prints the release notes for a version: its CHANGELOG section, then the commits since the previous tag.
set -euo pipefail
version="${1:?usage: release-notes.sh <version>}"
cd "$(dirname "$0")/.."

section="$(awk -v v="$version" '$0 == "## " v {on = 1; next} /^## / {on = 0} on' CHANGELOG.md)"
if [ -z "$(printf '%s' "$section" | tr -d '[:space:]')" ]; then
  echo "CHANGELOG.md has no section for $version" >&2
  exit 1
fi

end=HEAD
git rev-parse -q --verify "refs/tags/v$version" >/dev/null && end="v$version"
prev="$(git describe --tags --abbrev=0 --match 'v*' "$end^" 2>/dev/null || true)"
range="${prev:+$prev..}$end"

printf '%s\n\n## Changes\n\n' "$section"
git log --reverse --format='- %s (%h)' "$range"
printf '\nFull changelog: CHANGELOG.md\n'
