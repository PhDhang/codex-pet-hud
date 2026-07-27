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
test -f "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
test -f "$ROOT/Sources/CodexPetHUD/PetEffectAssets.swift"
test -f "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'Codex Pet HUD Pet Effect' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'level: .statusBar' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'level: .floating' \
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
if grep -F 'Text("🌀")' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Pet replacement must not paste spiral emoji over sprite eyes.\n' >&2
  exit 1
fi
if grep -F '.rotationEffect(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Reduce Motion contract forbids rotating critical glyphs.\n' >&2
  exit 1
fi
grep -F 'criticalOrbit(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'orbitingGlyph(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'CriticalOrbitLayout(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'PetEffectAnimation.orbitPhase(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'reduceMotion: reduceMotion' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
test "$(
  grep -F -o '"🐦"' \
    "$ROOT/Sources/CodexPetHUD/PetEffectView.swift" |
    wc -l |
    tr -d '[:space:]'
)" -eq 2
test "$(
  grep -F -o '"✨"' \
    "$ROOT/Sources/CodexPetHUD/PetEffectView.swift" |
    wc -l |
    tr -d '[:space:]'
)" -eq 2
grep -F '@Environment(\.accessibilityReduceMotion)' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let duration = 2.4' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let movingRight = reduceMotion || progress < 0.5' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let leftTravel = layout.leftTravel' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let rightTravel = layout.rightTravel' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let panicBounce = layout.panicBounce' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'layout.criticalImageFrame(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'assets.criticalImage' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'assets.failedFrames' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'PetEffectAnimation.criticalOrbitDuration' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'guard state != .normal else' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'petFrame: CGRect' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'PetEffectLayout(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectPanelController.swift"
grep -F 'let layout: PetEffectLayout' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'width: layout.panelSize.width' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'height: layout.panelSize.height' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
if grep -E 'nativePetCover|Ellipse[(][)]|RoundedRectangle[(]|Capsule[(]' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Pet replacement layers must remain fully transparent.\n' >&2
  exit 1
fi
grep -F 'genericCriticalHeadAura(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
if grep -F 'Rectangle()' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Pet effect still uses a rectangular native-pet mask.\n' >&2
  exit 1
fi
grep -F 'assets.panicCustomFrames' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'assets.panicCustomFrames?.count ?? 0' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let panicFramesPerSecond: Double' \
  "$ROOT/Sources/CodexPetHUD/PetEffectAssets.swift"
grep -F 'panic?.framesPerSecond ?? 8' \
  "$ROOT/Sources/CodexPetHUD/PetEffectAssets.swift"
grep -F 'PetEffectAnimation.frameIndex(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'framesPerSecond: assets.panicFramesPerSecond' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'case .custom' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'if assets.criticalImage == nil {' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
! grep -F '.rotationEffect(.degrees(76))' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"

test -x "$ROOT/scripts/capture-hud.sh"
grep -F 'let tacticalName = "Codex Pet HUD Tactical"' \
  "$ROOT/scripts/capture-hud.sh"
grep -F 'let effectName = "Codex Pet HUD Pet Effect"' \
  "$ROOT/scripts/capture-hud.sh"
grep -F 'guard tacticalRects.count == 1 else {' \
  "$ROOT/scripts/capture-hud.sh"
grep -F 'guard effectRects.count <= 1 else {' \
  "$ROOT/scripts/capture-hud.sh"
grep -F 'let rects = tacticalRects + effectRects' \
  "$ROOT/scripts/capture-hud.sh"
