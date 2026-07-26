#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

scripts/build-app.sh

APP="$ROOT/dist/Codex Pet HUD.app"
test -x "$APP/Contents/MacOS/CodexPetHUD"
test -f "$APP/Contents/Info.plist"
test "$(
  /usr/libexec/PlistBuddy \
    -c 'Print :LSUIElement' \
    "$APP/Contents/Info.plist"
)" = "true"
test "$(
  /usr/libexec/PlistBuddy \
    -c 'Print :CFBundleIdentifier' \
    "$APP/Contents/Info.plist"
)" = "com.codex-pet-hud.app"
codesign --verify --deep --strict "$APP"

