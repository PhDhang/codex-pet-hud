#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/codex-pet-hud"

test -f "$SKILL/SKILL.md"
test -f "$SKILL/agents/openai.yaml"
test -x "$SKILL/scripts/check-prerequisites.sh"
test -x "$SKILL/scripts/install-from-source.sh"
test -f "$SKILL/references/troubleshooting.md"

grep -F 'name: codex-pet-hud' "$SKILL/SKILL.md"
grep -E '^description: Use when ' "$SKILL/SKILL.md"
grep -F \
  'DEFAULT_REPO="https://github.com/PhDhang/codex-pet-hud.git"' \
  "$SKILL/scripts/install-from-source.sh"

for keyword in pet HUD quota HP SP macOS; do
  grep -i "$keyword" "$SKILL/SKILL.md" >/dev/null
done

for keyword in tactical flame panic idle critical; do
  grep -i "$keyword" "$SKILL/SKILL.md" >/dev/null
done

for setting in podScale podOffsetX podOffsetY; do
  grep -F "$setting" "$SKILL/SKILL.md" >/dev/null
done
grep -i 'resize' "$SKILL/SKILL.md" >/dev/null
grep -F 'same PID' "$SKILL/SKILL.md" >/dev/null
grep -F '20...32' "$SKILL/references/troubleshooting.md" >/dev/null

if rg -n 'TODO|TBD|FIXME|/Users/' "$SKILL"; then
  printf 'Skill contains placeholders or local absolute paths.\n' >&2
  exit 1
fi

for referenced in \
  'scripts/check-prerequisites.sh' \
  'scripts/install-from-source.sh' \
  'references/troubleshooting.md'; do
  grep -F "$referenced" "$SKILL/SKILL.md" >/dev/null
done
