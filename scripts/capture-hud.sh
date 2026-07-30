#!/bin/bash

set -euo pipefail

OUTPUT="${1:?usage: capture-hud.sh OUTPUT}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WINDOW_ID="$(
  SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-${TMPDIR:-/tmp}/codex-pet-hud-swift-cache}" \
  CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${TMPDIR:-/tmp}/codex-pet-hud-clang-cache}" \
    swift "$SCRIPT_DIR/capture-hud-window-id.swift"
)"

mkdir -p "$(dirname "$OUTPUT")"
screencapture -x -o -l "$WINDOW_ID" "$OUTPUT"
