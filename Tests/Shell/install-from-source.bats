#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

PET="$TEST_HOME/.codex/pets/test-pet"
DESTINATION="$TEST_HOME/.local/src/codex-pet-hud"
SOURCE_REF="$(git -C "$ROOT" rev-parse HEAD)"
mkdir -p "$PET"

HOME="$TEST_HOME" \
SWIFT_MODULECACHE_PATH="$TEST_HOME/.cache/swift-module-cache" \
CLANG_MODULE_CACHE_PATH="$TEST_HOME/.cache/clang-module-cache" \
CODEX_PET_HUD_TESTING=1 \
  "$ROOT/skills/codex-pet-hud/scripts/install-from-source.sh" \
    --repo "$ROOT" \
    --ref "$SOURCE_REF" \
    --pet-path "$PET" \
    --destination "$DESTINATION"

test -x "$TEST_HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD"
CONFIG="$TEST_HOME/.config/codex-pet-hud/config.json"
test -f "$CONFIG"
grep -F '"podScale": 1.14' "$CONFIG"
grep -F '"podOffsetX": 0' "$CONFIG"
grep -F '"podOffsetY": 0' "$CONFIG"
test "$(
  git -C "$DESTINATION" rev-parse HEAD
)" = "$(
  printf '%s' "$SOURCE_REF"
)"

SCRIPT="$ROOT/skills/codex-pet-hud/scripts/install-from-source.sh"
CHECKOUT_LINE="$(grep -n -F 'git -C "$DESTINATION" checkout --detach "$TARGET_REF"' "$SCRIPT" | cut -d: -f1)"
TEST_LINE="$(grep -n -F 'for test_script in Tests/Shell/*.bats; do' "$SCRIPT" | cut -d: -f1)"
INSTALL_LINE="$(grep -n -F 'scripts/install.sh --pet-path "$PET_PATH"' "$SCRIPT" | cut -d: -f1)"
test "$CHECKOUT_LINE" -lt "$TEST_LINE"
test "$TEST_LINE" -lt "$INSTALL_LINE"
