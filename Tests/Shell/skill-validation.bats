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

for keyword in tactical flame idle; do
  grep -i "$keyword" "$SKILL/SKILL.md" >/dev/null
done

for setting in podScale podOffsetX podOffsetY; do
  grep -F "$setting" "$SKILL/SKILL.md" >/dev/null
done
grep -i 'resize' "$SKILL/SKILL.md" >/dev/null
grep -F 'same PID' "$SKILL/SKILL.md" >/dev/null
grep -F 'width 20...32 and height 6...32' "$SKILL/SKILL.md" >/dev/null
grep -F 'width 20...32 and height 6...32' "$SKILL/references/troubleshooting.md" >/dev/null
grep -F 'HUD-only' "$SKILL/SKILL.md" >/dev/null
grep -F 'never changes the native pet' "$SKILL/SKILL.md" >/dev/null
grep -F 'standard v2 `pet.json` metadata' "$SKILL/SKILL.md" >/dev/null
grep -F \
  'The current four-row HUD does not render the manifest display name.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F 'PANIC · QUOTA LOW' "$SKILL/SKILL.md" >/dev/null
grep -F 'EXHAUSTED · SIGNAL CRITICAL' "$SKILL/SKILL.md" >/dev/null
grep -F 'MP is the measured five-hour percentage or sky-blue `MAX`.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F \
  'HP and MP values are centered inside the bars.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F \
  'SP reset time is accessibility-only and has no visible suffix.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F 'Safe measured values below `100%` carry a subtle same-color flow.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F 'Danger pulses HP or MP independently to white at `0.9s` or `0.45s`.' \
  "$SKILL/SKILL.md" >/dev/null
grep -F 'Reduce Motion leaves bright identity colors static' \
  "$SKILL/SKILL.md" >/dev/null
grep -F 'Lit SP flames use a `1.10` base scale' "$SKILL/SKILL.md" >/dev/null
grep -F 'no pet animation or replacement' "$SKILL/SKILL.md" >/dev/null
grep -F 'fiveHourStatus' "$SKILL/SKILL.md" >/dev/null
grep -F 'window-only screenshot' "$SKILL/SKILL.md" >/dev/null

if rg -q 'TODO|TBD|FIXME|/Users/' "$SKILL"; then
  printf 'Skill contains placeholders or local absolute paths.\n' >&2
  exit 1
fi
if rg -q "pet's display name in the tactical HUD" "$SKILL/SKILL.md"; then
  printf 'Skill still claims the manifest name is visible.\n' >&2
  exit 1
fi

for referenced in \
  'scripts/check-prerequisites.sh' \
  'scripts/install-from-source.sh' \
  'references/troubleshooting.md'; do
  grep -F "$referenced" "$SKILL/SKILL.md" >/dev/null
done
