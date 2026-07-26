#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_PATH="$ROOT/.build"
APP="$ROOT/dist/Codex Pet HUD.app"

cd "$ROOT"

SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-/private/tmp/codex-pet-hud-swift-cache}" \
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/codex-pet-hud-clang-cache}" \
swift build \
  -c release \
  --disable-sandbox \
  --scratch-path "$BUILD_PATH"

rm -rf "$APP"
mkdir -p \
  "$APP/Contents/MacOS" \
  "$APP/Contents/Resources"

cp "$BUILD_PATH/release/CodexPetHUD" \
  "$APP/Contents/MacOS/CodexPetHUD"
cp "$ROOT/Resources/Info.plist" \
  "$APP/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.svg" \
  "$APP/Contents/Resources/AppIcon.svg"

chmod 755 "$APP/Contents/MacOS/CodexPetHUD"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

printf 'Built %s\n' "$APP"

