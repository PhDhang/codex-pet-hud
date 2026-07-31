#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

line_printing_scan_pattern='rg[[:space:]]+-[[:alpha:]]*n[[:alpha:]]*[[:space:]]|rg[[:space:]]+--line-number([=[:space:]]|$)'
if rg -q "$line_printing_scan_pattern" \
  Tests/Shell/diagnostics.bats \
  Tests/Shell/release-validation.bats \
  Tests/Shell/skill-validation.bats \
  Tests/Shell/tactical-ui.bats \
  docs/privacy.md; then
  printf 'Forbidden-content scans must never print matched lines.\n' >&2
  exit 1
fi

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
grep -F 'Version 0.4.0' README.md
grep -F '![Warning tactical HUD showing 33% HP](docs/screenshots/tactical-hud.png)' \
  README.md
grep -F 'tactical dual-bar HUD' CHANGELOG.md
grep -F 'read-only' docs/privacy.md
grep -F 'swift test' .github/workflows/ci.yml
grep -F 'Tests/Shell/' .github/workflows/ci.yml
CI_WORKFLOW=.github/workflows/ci.yml
SETUP_SWIFT_SHA=7ca6abe6b3b0e8b5421b88be48feee39cbf52c6a
awk -v setup_sha="$SETUP_SWIFT_SHA" '
  $0 == "        uses: swift-actions/setup-swift@" setup_sha " # v2.4.0" {
    if ((getline) <= 0 || $0 != "        with:") {
      exit 1
    }
    if ((getline) <= 0 || $0 != "          swift-version: \"6.2\"") {
      exit 1
    }
    found = 1
  }
  END {
    if (!found) {
      exit 1
    }
  }
' "$CI_WORKFLOW"
workflow_line() {
  awk -v expected="$1" '
    $0 == expected {
      print NR
      found = 1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$CI_WORKFLOW"
}
setup_line="$(
  workflow_line \
    "        uses: swift-actions/setup-swift@$SETUP_SWIFT_SHA # v2.4.0"
)"
version_line="$(workflow_line '        run: swift --version')"
swift_test_line="$(
  workflow_line '        run: swift test --disable-sandbox'
)"
shell_test_line="$(
  workflow_line '          for test_script in Tests/Shell/*.bats; do'
)"
test "$setup_line" -lt "$version_line"
test "$version_line" -lt "$swift_test_line"
test "$swift_test_line" -lt "$shell_test_line"
REPORT=Sources/PetHUDCore/RedactedDiagnosticReport.swift
grep -F 'fiveHourRemainingPercent' "$REPORT"
grep -F 'fiveHourStatus' "$REPORT"
test "$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)" \
  = '0.4.0'
test "$(plutil -extract CFBundleVersion raw Resources/Info.plist)" = '4'
grep -F 'MP' README.md
grep -F \
  'HP and MP values are centered inside their bars.' \
  README.md
grep -F \
  'The weekly reset countdown remains available to accessibility tools but is not shown visually.' \
  README.md
grep -F \
  'Live same-PID fallback geometry follows dragging after current-process geometry confirmation.' \
  docs/architecture.md
tr '\n' ' ' < docs/architecture.md | grep -F \
  'Restored shell geometry does not gain live confidence until a current-process geometry observation is accepted.'
grep -F '0.4.0' CHANGELOG.md
grep -F 'five-hour' docs/architecture.md

DIAGNOSTIC_SOURCES=(
  Sources/CodexPetHUD/Diagnostics.swift
  "$REPORT"
)
if rg -q \
  'access[_-]?token|refresh[_-]?token|id[_-]?token|account|email|cookie|credential|encoder\\.encode\\(snapshot\\)' \
  "${DIAGNOSTIC_SOURCES[@]}"; then
  printf 'Diagnostics must not name credentials or emit raw provider snapshots.\n' \
    >&2
  exit 1
fi

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

if rg -q "$scan_pattern" "${release_content[@]}"; then
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
grep -F 'Weekly HP is clamped to `0...100`' README.md
grep -F 'and floored to one decimal place' README.md
grep -F 'The tactical panel hides only after three missing observations' \
  README.md
grep -F 'The current four-row HUD does not visibly render' \
  README.md
if rg -q \
  'raw weekly HP percentage|Both panels hide|HUD uses the manifest display name' \
  README.md; then
  printf 'README still contains reviewed HUD presentation inaccuracies.\n' \
    >&2
  exit 1
fi
grep -F 'Without `--purge`, configuration, caches, and logs remain.' README.md
grep -F "scan_pattern='/Users/[A-Za-z0-9._-]+/|Bearer[[:space:]]+eyJ[A-Za-z0-9._-]{20,}|sk-[A-Za-z0-9_-]{20,}'" \
  docs/privacy.md
grep -F 'Tests/Shell/release-validation.bats' docs/privacy.md
grep -F 'done < <(git ls-files)' docs/privacy.md
grep -F 'if rg -q "$scan_pattern" "${release_content[@]}"; then' \
  docs/privacy.md
grep -F "printf 'Release privacy scan failed.\\n' >&2" docs/privacy.md
grep -F 'exit 1' docs/privacy.md
if rg -q 'critical threshold is `0\.\.\.10%`' README.md; then
  printf 'README documents a configurable critical threshold.\n' >&2
  exit 1
fi

grep -F 'HUD-only' README.md
grep -F 'never changes the native pet' skills/codex-pet-hud/SKILL.md
grep -F 'full sky-blue `MAX`' docs/architecture.md
if rg -q 'orange `MAX`' docs/architecture.md; then
  printf 'Architecture still documents the obsolete MAX color.\n' >&2
  exit 1
fi

for removed_asset in \
  Examples/yicha/hud-effects.json \
  Examples/yicha/hud-panic.png \
  Examples/yicha/hud-critical.png \
  docs/screenshots/tactical-hud-panic.png
do
  test ! -e "$removed_asset"
done

if rg -q \
  'Pet Effect|PetEffect|PetDistressState|hud-effects|hud-panic|hud-critical|pet-replacement|orbit glyph|headAnchor|non-facial aura|integrated eye art|procedural eye overlay' \
  README.md docs/architecture.md skills/codex-pet-hud; then
  printf 'Active documentation still exposes a pet-effect feature.\n' >&2
  exit 1
fi

grep -F 'Historical design record' \
  docs/superpowers/plans/2026-07-27-tactical-dual-bar-hud.md
grep -F '[HUD-Only Pet Compatibility Implementation Plan](2026-07-28-hud-only-pet-compatibility.md)' \
  docs/superpowers/plans/2026-07-27-tactical-dual-bar-hud.md
grep -F 'not active release contracts' \
  docs/superpowers/plans/2026-07-27-tactical-dual-bar-hud.md
grep -F 'Historical design record' \
  docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md
grep -F '[HUD-Only Pet Compatibility Implementation Plan](../plans/2026-07-28-hud-only-pet-compatibility.md)' \
  docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md
grep -F 'not active release contracts' \
  docs/superpowers/specs/2026-07-27-tactical-dual-bar-hud-design.md
