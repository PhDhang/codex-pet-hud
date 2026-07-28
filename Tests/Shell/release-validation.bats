#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

for required_file in \
  README.md \
  CHANGELOG.md \
  LICENSE \
  SECURITY.md \
  docs/architecture.md \
  docs/privacy.md \
  .github/workflows/ci.yml
do
  test -s "$required_file"
done

grep -F 'macOS 14' README.md
grep -F 'Version 0.3.0-rc.1' README.md
grep -F 'tactical dual-bar HUD' CHANGELOG.md
grep -F 'read-only' docs/privacy.md
grep -F 'swift test' .github/workflows/ci.yml
grep -F 'Tests/Shell/' .github/workflows/ci.yml

scan_pattern='/Users/[A-Za-z0-9._-]+/|Bearer[[:space:]]+eyJ[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9_-]{20,}'
release_content=()
while IFS= read -r tracked_file; do
  if [ "$tracked_file" != "Tests/Shell/release-validation.bats" ]; then
    release_content+=("$tracked_file")
  fi
done < <(git ls-files)

for release_file in "${release_content[@]}"; do
  if [ ! -e "$release_file" ]; then
    printf 'Release scan includes a missing tracked file: %s\n' \
      "$release_file" >&2
    exit 1
  fi
done

if rg -n "$scan_pattern" "${release_content[@]}"; then
  printf 'Release files contain a local path or credential-like value.\n' >&2
  exit 1
fi

fixture="$(mktemp)"
trap 'rm -f "$fixture"' EXIT
printf '%s\n' 'Bearer eyJfixture_token_value_1234567890' > "$fixture"
if ! rg -q "$scan_pattern" "$fixture"; then
  printf 'Release scan fixture was not detected.\n' >&2
  exit 1
fi

grep -F 'fixed at `≤3%`' README.md
grep -F 'age is `≤300s`' README.md
grep -F '`>300s` and `≤1800s`' README.md
grep -F '`>1800s`, the HUD is `OFFLINE` with `--`' README.md
grep -F 'Without `--purge`, configuration, caches, and logs remain.' README.md
grep -F "scan_pattern='/Users/[A-Za-z0-9._-]+/|Bearer[[:space:]]+eyJ[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9_-]{20,}'" \
  docs/privacy.md
grep -F 'Tests/Shell/release-validation.bats' docs/privacy.md
grep -F 'done < <(git ls-files)' docs/privacy.md
if rg -n 'critical threshold is `0\.\.\.10%`' README.md; then
  printf 'README documents a configurable critical threshold.\n' >&2
  exit 1
fi

grep -F 'HUD-only' README.md
grep -F 'never changes the native pet' skills/codex-pet-hud/SKILL.md

for removed_asset in \
  Examples/yicha/hud-effects.json \
  Examples/yicha/hud-panic.png \
  Examples/yicha/hud-critical.png \
  docs/screenshots/tactical-hud-panic.png
do
  test ! -e "$removed_asset"
done

if rg -n \
  'Pet Effect|PetEffect|PetDistressState|hud-effects|hud-panic|hud-critical|pet-replacement|orbit glyph|headAnchor|non-facial aura|integrated eye art|procedural eye overlay' \
  README.md docs/architecture.md skills/codex-pet-hud; then
  printf 'Active documentation still exposes a pet-effect feature.\n' >&2
  exit 1
fi
