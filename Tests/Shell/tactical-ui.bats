#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
test -f "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'Codex Pet HUD Tactical' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
if grep -Eq \
  'PetEffect|panicView|criticalView|panicFrames|criticalImage|criticalOrbit|orbitingGlyph|Text[(]"🌀"|🐦|✨|Image[(]' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"; then
  printf 'Tactical HUD must remain bars-only with no pet-state content.\n' >&2
  exit 1
fi
grep -F 'struct FlameCellView' \
  "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
FLAME_VIEW="$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
grep -F '.onChange(of: reduceMotion)' "$FLAME_VIEW"
grep -F '.onChange(of: isLit)' "$FLAME_VIEW"
grep -F 'private func restartFlicker()' "$FLAME_VIEW"
grep -F 'guard isLit, !reduceMotion else {' "$FLAME_VIEW"
grep -F 'guard generation == flickerGeneration else {' "$FLAME_VIEW"
grep -F 'transaction.disablesAnimations = true' "$FLAME_VIEW"
grep -F 'ForEach(0..<7' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'frameSize: frame.size' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
SHOW_BODY="$(sed -n \
  '/func show(/,/^    func hide()/p' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift")"
FRAME_LINE="$(printf '%s\n' "$SHOW_BODY" | nl -ba | \
  grep -F 'panel.setFrame' | head -n 1 | awk '{ print $1 }')"
ROOT_VIEW_LINE="$(printf '%s\n' "$SHOW_BODY" | nl -ba | \
  grep -F 'hostingView.rootView' | head -n 1 | awk '{ print $1 }')"
if [ -z "$FRAME_LINE" ] || [ -z "$ROOT_VIEW_LINE" ] || \
  [ "$FRAME_LINE" -gt "$ROOT_VIEW_LINE" ]; then
  printf 'HUD panel must size before replacing its SwiftUI root view.\n' >&2
  exit 1
fi
grep -F 'TacticalHUDLayoutMetrics' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'metrics.flameWidth' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'metrics.statusFontSize' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'rowHeight: metrics.flameHeight' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'data.statusLabel' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
HUD_VIEW="$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'label: "MP"' "$HUD_VIEW"
grep -F 'data.mpText' "$HUD_VIEW"
grep -F 'data.mpFraction' "$HUD_VIEW"
grep -F 'data.mpDangerLevel' "$HUD_VIEW"
grep -F 'data.mpMode == .unlimited' "$HUD_VIEW"
grep -F 'accessibilityReduceMotion' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
grep -F 'duration: 0.9' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
grep -F 'duration: 0.45' \
  "$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
METER_VIEW="$ROOT/Sources/CodexPetHUD/QuotaMeterFillView.swift"
DISPLAY_COLOR="$(awk '
  /private var displayColor: Color \{/ { inside = 1 }
  /private var dangerAnimation: Animation\?/ { inside = 0 }
  inside { print }
' "$METER_VIEW")"
if printf '%s\n' "$DISPLAY_COLOR" | grep -Fq 'Color.white'; then
  printf 'Critical fill must preserve the supplied base and danger colors.\n' \
    >&2
  exit 1
fi
FILL_PAIR_COUNT="$(printf '%s\n' "$DISPLAY_COLOR" | \
  grep -F 'return showsDangerColor ? dangerColor : baseColor' | \
  wc -l | tr -d '[:space:]')"
if [ "$FILL_PAIR_COUNT" -ne 2 ]; then
  printf 'Low and critical fills must share the supplied color pair.\n' >&2
  exit 1
fi
grep -F '.brightness(criticalIntensity)' "$METER_VIEW"
grep -F 'private var criticalIntensity: Double' "$METER_VIEW"
grep -F 'dangerLevel == .critical && !reduceMotion' "$METER_VIEW"
grep -F 'private static let criticalIntensityMagnitude = 0.22' \
  "$METER_VIEW"
grep -F \
  'return showsDangerColor ? Self.criticalIntensityMagnitude : 0' \
  "$METER_VIEW"
grep -F 'transaction.disablesAnimations = true' "$METER_VIEW"
grep -F '.onDisappear {' "$METER_VIEW"
grep -F 'pulseGeneration += 1' "$METER_VIEW"
if grep -Fq '.animation(' "$METER_VIEW"; then
  printf 'Quota meter must use only explicit pulse animations.\n' >&2
  exit 1
fi
PULSE_ANIMATION_COUNT="$(grep -F 'withAnimation(' "$METER_VIEW" | \
  wc -l | tr -d '[:space:]')"
if [ "$PULSE_ANIMATION_COUNT" -ne 1 ]; then
  printf 'Quota meter must start its pulse with one explicit animation.\n' >&2
  exit 1
fi
ACCENT_HELPER="$(sed -n \
  '/private var tacticalAccentColor: Color {/,/^    }/p' \
  "$HUD_VIEW")"
if ! printf '%s\n' "$ACCENT_HELPER" | \
  grep -A 1 -F 'case .low, .critical:' | \
  grep -F 'Color.red'; then
  printf 'Low and critical quota bands must share the red tactical accent.\n' \
    >&2
  exit 1
fi
ACCENT_LABEL_USE_COUNT="$(grep -F '.foregroundStyle(tacticalAccentColor)' \
  "$HUD_VIEW" | wc -l | tr -d '[:space:]')"
if [ "$ACCENT_LABEL_USE_COUNT" -ne 2 ]; then
  printf 'Tactical status and meter labels must share one accent helper.\n' \
    >&2
  exit 1
fi
grep -F '.stroke(tacticalAccentColor, lineWidth: 1)' "$HUD_VIEW"
grep -F '.accessibilityElement(children: .combine)' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F '.accessibilityHidden(true)' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'of 7 elapsed; reset in' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'accessibilityValue: String?' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'accessibilityValue: spAccessibilityValue' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F '.accessibilityValue(accessibilityValue ?? trailing)' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
grep -F 'NSWindow.Level.floating.rawValue + 1' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
PANEL_INITIALIZER="$(sed -n \
  '/final class ClickThroughPanel: NSPanel {/,/override var canBecomeKey/p' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift")"
LEVEL_ASSIGNMENT_COUNT="$(printf '%s\n' "$PANEL_INITIALIZER" | \
  grep -E -o '(self[.])?level[[:space:]]*=' | wc -l | tr -d '[:space:]')"
if [ "$LEVEL_ASSIGNMENT_COUNT" -ne 1 ]; then
  printf 'Click-through panel must assign its window level exactly once.\n' >&2
  exit 1
fi
NORMALIZED_LEVEL_ASSIGNMENT="$(printf '%s\n' "$PANEL_INITIALIZER" | perl -ne '
  while (/(?:self\.)?level\s*=\s*[^;\n]+/g) {
    $level_assignment = $&;
    $level_assignment =~ s/\s+//g;
    print $level_assignment;
  }
')"
if [ "$NORMALIZED_LEVEL_ASSIGNMENT" != 'self.level=level' ]; then
  printf 'Click-through panel must apply its injected window level.\n' >&2
  exit 1
fi
for removed in \
  PetEffectAssets.swift \
  PetEffectPanelController.swift \
  PetEffectView.swift
do
  test ! -e "$ROOT/Sources/CodexPetHUD/$removed"
done

if rg -q 'PetEffect|PetDistressState|distressState|effectAssets' \
  "$ROOT/Sources"; then
  printf 'HUD runtime still contains pet-effect behavior.\n' >&2
  exit 1
fi

CAPTURE_SCRIPT="$ROOT/scripts/capture-hud.sh"
CAPTURE_SELECTOR="$ROOT/scripts/capture-hud-window-id.swift"
test -f "$CAPTURE_SCRIPT"
test -f "$CAPTURE_SELECTOR"
grep -F 'let tacticalName = "Codex Pet HUD Tactical"' "$CAPTURE_SELECTOR"
grep -F 'let effectName = "Codex Pet HUD Pet Effect"' "$CAPTURE_SELECTOR"
grep -F 'let bundleIdentifier = "com.codex-pet-hud.app"' \
  "$CAPTURE_SELECTOR"
grep -F 'kCGWindowOwnerPID' "$CAPTURE_SELECTOR"
grep -F 'runningApplications(withBundleIdentifier: bundleIdentifier)' \
  "$CAPTURE_SELECTOR"
grep -F 'effectWindows.isEmpty' "$CAPTURE_SELECTOR"
grep -F 'swift "$SCRIPT_DIR/capture-hud-window-id.swift"' \
  "$CAPTURE_SCRIPT"
grep -F 'screencapture -x -o -l "$WINDOW_ID" "$OUTPUT"' \
  "$CAPTURE_SCRIPT"
if rg -q 'screencapture.*-R|CGRect|insetBy' "$CAPTURE_SCRIPT"; then
  printf 'HUD capture must target only the titled HUD window ID.\n' >&2
  exit 1
fi

CAPTURE_TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$CAPTURE_TEST_ROOT"' EXIT
cat > "$CAPTURE_TEST_ROOT/valid.json" <<'JSON'
{
  "runningPIDs": [700],
  "windows": [
    {
      "name": "Codex Pet HUD Tactical",
      "onScreen": true,
      "windowID": 42,
      "ownerPID": 700
    },
    {
      "name": "Private Other Window",
      "onScreen": true,
      "windowID": 99,
      "ownerPID": 900
    }
  ]
}
JSON
CAPTURE_OUTPUT="$(
  SWIFT_MODULECACHE_PATH="$CAPTURE_TEST_ROOT/swift-cache" \
  CLANG_MODULE_CACHE_PATH="$CAPTURE_TEST_ROOT/clang-cache" \
    swift "$CAPTURE_SELECTOR" \
      --fixture "$CAPTURE_TEST_ROOT/valid.json"
)"
test "$CAPTURE_OUTPUT" = "42"

cat > "$CAPTURE_TEST_ROOT/spoof.json" <<'JSON'
{
  "runningPIDs": [700],
  "windows": [
    {
      "name": "Codex Pet HUD Tactical",
      "onScreen": true,
      "windowID": 99,
      "ownerPID": 900
    }
  ]
}
JSON
set +e
SPOOF_OUTPUT="$(
  SWIFT_MODULECACHE_PATH="$CAPTURE_TEST_ROOT/swift-cache" \
  CLANG_MODULE_CACHE_PATH="$CAPTURE_TEST_ROOT/clang-cache" \
    swift "$CAPTURE_SELECTOR" \
      --fixture "$CAPTURE_TEST_ROOT/spoof.json"
)"
SPOOF_RESULT=$?
set -e
test "$SPOOF_RESULT" -eq 5
test -z "$SPOOF_OUTPUT"

cat > "$CAPTURE_TEST_ROOT/mixed.json" <<'JSON'
{
  "runningPIDs": [700],
  "windows": [
    {
      "name": "Codex Pet HUD Tactical",
      "onScreen": true,
      "windowID": 42,
      "ownerPID": 700
    },
    {
      "name": "Codex Pet HUD Tactical",
      "onScreen": true,
      "windowID": 99,
      "ownerPID": 900
    }
  ]
}
JSON
set +e
MIXED_OUTPUT="$(
  SWIFT_MODULECACHE_PATH="$CAPTURE_TEST_ROOT/swift-cache" \
  CLANG_MODULE_CACHE_PATH="$CAPTURE_TEST_ROOT/clang-cache" \
    swift "$CAPTURE_SELECTOR" \
      --fixture "$CAPTURE_TEST_ROOT/mixed.json"
)"
MIXED_RESULT=$?
set -e
test "$MIXED_RESULT" -eq 5
test -z "$MIXED_OUTPUT"

if rg -q \
  'Pet Effect|effectRects|hud-effects|hud-panic|hud-critical' \
  "$ROOT/README.md" "$ROOT/docs/architecture.md" \
  "$ROOT/skills/codex-pet-hud"; then
  printf 'Active HUD documentation still describes pet effects.\n' >&2
  exit 1
fi
