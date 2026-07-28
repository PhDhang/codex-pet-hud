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
if rg -n \
  'Pet Effect|effectName|effectRects|let rects[[:space:]]*=|dropFirst\(\)\.reduce|\.union\(' \
  "$CAPTURE_SCRIPT"; then
  printf 'Capture script must capture only the tactical HUD window.\n' >&2
  exit 1
fi
