#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD"
SOURCE="$ROOT/Sources/CodexPetHUD/PetHUDApplication.swift"

test "$(
  grep -Ec \
    'RunLoop\.main\.add\([^,]+, forMode: \.common\)' \
    "$SOURCE"
)" -eq 3

if grep -F "Task { @MainActor" "$SOURCE"; then
  printf 'Polling still depends on nested main-actor tasks.\n' >&2
  exit 1
fi

grep -F 'PetWindowLocator.currentObservation()' "$SOURCE"
grep -F 'PetPresenceTracker' "$SOURCE"
grep -F 'PetGeometryCache' "$SOURCE"
grep -F 'TacticalHUDPanelController' "$SOURCE"
grep -F 'PetEffectPanelController' "$SOURCE"

if grep -F 'PetWindowTracker' \
  "$ROOT/Sources/PetHUDCore/PetPresenceTracker.swift"
then
  printf 'Task 2 compatibility tracker still exists.\n' >&2
  exit 1
fi

for legacy_source in \
  LifePodView.swift \
  LifePodPanelController.swift \
  CriticalEffectView.swift \
  CriticalPanelController.swift
do
  test ! -e "$ROOT/Sources/CodexPetHUD/$legacy_source"
done

test -x "$APP"

OUTPUT="$(
  perl -e '
    $SIG{ALRM} = sub { exit 124 };
    alarm 5;
    exec @ARGV;
  ' "$APP" --executor-check
)"

test "$OUTPUT" = "executor=ok"
