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
test -f "$TEST_HOME/.config/codex-pet-hud/config.json"
test "$(
  git -C "$DESTINATION" rev-parse HEAD
)" = "$(
  printf '%s' "$SOURCE_REF"
)"
