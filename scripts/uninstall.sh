#!/bin/bash

set -euo pipefail

PURGE=0
if [ "${1:-}" = "--purge" ]; then
  PURGE=1
  shift
fi
if [ "$#" -ne 0 ]; then
  printf 'Usage: scripts/uninstall.sh [--purge]\n' >&2
  exit 2
fi

APP="$HOME/Applications/Codex Pet HUD.app"
PLIST="$HOME/Library/LaunchAgents/com.codex-pet-hud.agent.plist"
CONFIG_DIRECTORY="$HOME/.config/codex-pet-hud"

if [ "${CODEX_PET_HUD_TESTING:-0}" != "1" ] &&
  [ -f "$PLIST" ]; then
  launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
fi

rm -rf "$APP"
rm -f "$PLIST"

if [ "$PURGE" -eq 1 ]; then
  rm -rf "$CONFIG_DIRECTORY"
fi

printf 'Uninstalled Codex Pet HUD.\n'
