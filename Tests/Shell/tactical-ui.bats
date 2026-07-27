#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
test -f "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'Codex Pet HUD Tactical' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
if grep -E \
  'PetEffect|panicView|criticalView|panicFrames|criticalImage|Image[(]' \
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
if grep -F 'Text("🌀")' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Pet replacement must not paste spiral emoji over sprite eyes.\n' >&2
  exit 1
fi
if grep -F 'orbitingGlyph(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"; then
  printf 'Custom critical art must remain a single replacement sprite.\n' >&2
  exit 1
fi
grep -F '@Environment(\.accessibilityReduceMotion)' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let duration = 2.4' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let movingRight = reduceMotion || progress < 0.5' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let travel = layout.travel' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let bounce = -abs(sin(local * .pi * 2)) * 4' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'assets.criticalImage' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'assets.failedFrames' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let orbitDuration = 3.0' \
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
grep -F 'nativePetCover(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'RadialGradient(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'Ellipse()' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'Capsule()' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'RoundedRectangle(' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
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
