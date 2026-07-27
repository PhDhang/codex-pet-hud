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

test -x "$APP"

OUTPUT="$(
  perl -e '
    $SIG{ALRM} = sub { exit 124 };
    alarm 5;
    exec @ARGV;
  ' "$APP" --executor-check
)"

test "$OUTPUT" = "executor=ok"
