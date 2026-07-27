#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDView.swift"
test -f "$ROOT/Sources/CodexPetHUD/FlameCellView.swift"
test -f "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
grep -F 'Codex Pet HUD Tactical' \
  "$ROOT/Sources/CodexPetHUD/TacticalHUDPanelController.swift"
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
grep -F '🌀' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F '🐦' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F '@Environment(\.accessibilityReduceMotion)' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let duration = 2.4' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'let movingRight = reduceMotion || progress < 0.5' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
grep -F 'min(geometry.size.width * 0.18, 28)' \
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
! grep -F '.rotationEffect(.degrees(76))' \
  "$ROOT/Sources/CodexPetHUD/PetEffectView.swift"
