#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
test -f "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'Codex Pet HUD Tactical' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
if grep -E \
  'PetEffect|panicView|criticalView|panicFrames|criticalImage|criticalOrbit|orbitingGlyph|Text[(]"🌀"|🐦|✨|Image[(]' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"; then
  printf 'Tactical HUD must remain bars-only with no pet-state content.\n' >&2
  exit 1
fi
grep -F 'struct FlameCellView' \
  "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
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
grep -F 'return showsDangerColor ? dangerColor : Color.white' \
  "$METER_VIEW"
grep -F 'transaction.disablesAnimations = true' "$METER_VIEW"
grep -F '.onDisappear {' "$METER_VIEW"
grep -F 'pulseGeneration += 1' "$METER_VIEW"
if grep -F '.animation(' "$METER_VIEW"; then
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

if rg -n 'PetEffect|PetDistressState|distressState|effectAssets' \
  "$ROOT/Sources"; then
  printf 'HUD runtime still contains pet-effect behavior.\n' >&2
  exit 1
fi

CAPTURE_SCRIPT="$ROOT/scripts/capture-hud.sh"
test -f "$CAPTURE_SCRIPT"
grep -F 'let tacticalName = "Codex Pet HUD Tactical"' "$CAPTURE_SCRIPT"
grep -F 'guard tacticalRects.count == 1 else' "$CAPTURE_SCRIPT"
grep -F 'let capture = tacticalRects[0].insetBy(dx: -12, dy: -12)' \
  "$CAPTURE_SCRIPT"
grep -F 'let effectName = "Codex Pet HUD Pet Effect"' "$CAPTURE_SCRIPT"
grep -F 'let effectRects = visibleRects(named: effectName)' "$CAPTURE_SCRIPT"
grep -F 'guard effectRects.isEmpty else {' "$CAPTURE_SCRIPT"
if rg -n \
  'Pet Effect|effectRects|hud-effects|hud-panic|hud-critical' \
  "$ROOT/README.md" "$ROOT/docs/architecture.md" \
  "$ROOT/skills/codex-pet-hud"; then
  printf 'Active HUD documentation still describes pet effects.\n' >&2
  exit 1
fi
