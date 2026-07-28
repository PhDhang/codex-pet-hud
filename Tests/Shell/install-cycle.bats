#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

APP="$ROOT/dist/Codex Pet HUD.app"
test -d "$APP"

TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

PET="$TEST_HOME/.codex/pets/test-pet"
mkdir -p "$PET"

HOME="$TEST_HOME" CODEX_PET_HUD_TESTING=1 \
  scripts/install.sh \
    --app "$APP" \
    --pet-path "$PET"

INSTALLED_APP="$TEST_HOME/Applications/Codex Pet HUD.app"
CONFIG="$TEST_HOME/.config/codex-pet-hud/config.json"
PLIST="$TEST_HOME/Library/LaunchAgents/com.codex-pet-hud.agent.plist"
LOGS="$TEST_HOME/Library/Logs/CodexPetHUD"
SUPPORT="$TEST_HOME/Library/Application Support/CodexPetHUD"
SNAPSHOT="$SUPPORT/snapshot.json"
GEOMETRY="$SUPPORT/pet-geometry.json"

test -x "$INSTALLED_APP/Contents/MacOS/CodexPetHUD"
test -f "$CONFIG"
test -f "$PLIST"
grep -F "\"petPath\": \"$PET\"" "$CONFIG"
grep -F '"podScale": 1.14' "$CONFIG"
grep -F '"podOffsetX": 0' "$CONFIG"
grep -F '"podOffsetY": 0' "$CONFIG"
grep -F "$INSTALLED_APP/Contents/MacOS/CodexPetHUD" "$PLIST"
mkdir -p "$LOGS" "$SUPPORT"
printf 'log\n' > "$LOGS/app.log"
printf 'snapshot\n' > "$SNAPSHOT"
printf 'geometry\n' > "$GEOMETRY"

HOME="$TEST_HOME" CODEX_PET_HUD_TESTING=1 \
  scripts/uninstall.sh

test ! -e "$INSTALLED_APP"
test ! -e "$PLIST"
test -f "$CONFIG"
test -f "$LOGS/app.log"
test -f "$SNAPSHOT"
test -f "$GEOMETRY"

HOME="$TEST_HOME" CODEX_PET_HUD_TESTING=1 \
  scripts/uninstall.sh --purge

test ! -e "$CONFIG"
test ! -e "$LOGS"
test ! -e "$SNAPSHOT"
test ! -e "$GEOMETRY"
