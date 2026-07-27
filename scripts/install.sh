#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SOURCE="$ROOT/dist/Codex Pet HUD.app"
PET_PATH=""
SHOULD_LAUNCH=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    --app)
      APP_SOURCE="$2"
      shift 2
      ;;
    --pet-path)
      PET_PATH="$2"
      shift 2
      ;;
    --no-launch)
      SHOULD_LAUNCH=0
      shift
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'Codex Pet HUD currently supports macOS only.\n' >&2
  exit 2
fi

if [ ! -x "$APP_SOURCE/Contents/MacOS/CodexPetHUD" ]; then
  printf 'Invalid app bundle: %s\n' "$APP_SOURCE" >&2
  exit 2
fi

case "$PET_PATH" in
  *\"*|*$'\n'*)
    printf 'Pet path contains unsupported characters.\n' >&2
    exit 2
    ;;
esac

APP_DESTINATION="$HOME/Applications/Codex Pet HUD.app"
CONFIG_DIRECTORY="$HOME/.config/codex-pet-hud"
CONFIG="$CONFIG_DIRECTORY/config.json"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
PLIST="$LAUNCH_AGENTS/com.codex-pet-hud.agent.plist"
LOG_DIRECTORY="$HOME/Library/Logs/CodexPetHUD"

mkdir -p \
  "$HOME/Applications" \
  "$CONFIG_DIRECTORY" \
  "$LAUNCH_AGENTS" \
  "$LOG_DIRECTORY"

if [ -e "$APP_DESTINATION" ]; then
  rm -rf "$APP_DESTINATION"
fi
/usr/bin/ditto "$APP_SOURCE" "$APP_DESTINATION"

if [ -f "$CONFIG" ]; then
  cp "$CONFIG" "$CONFIG.backup.$(date -u +%Y%m%dT%H%M%SZ)"
fi

CONFIG_TEMP="$CONFIG.tmp.$$"
if [ -n "$PET_PATH" ]; then
  printf '%s\n' \
    '{' \
    "  \"petPath\": \"$PET_PATH\"," \
    '  "refreshIntervalSeconds": 300,' \
    '  "criticalThresholdPercent": 3,' \
    '  "podScale": 1.14,' \
    '  "podOffsetX": 0,' \
    '  "podOffsetY": 0,' \
    '  "launchAtLogin": true' \
    '}' > "$CONFIG_TEMP"
else
  printf '%s\n' \
    '{' \
    '  "refreshIntervalSeconds": 300,' \
    '  "criticalThresholdPercent": 3,' \
    '  "podScale": 1.14,' \
    '  "podOffsetX": 0,' \
    '  "podOffsetY": 0,' \
    '  "launchAtLogin": true' \
    '}' > "$CONFIG_TEMP"
fi
chmod 600 "$CONFIG_TEMP"
mv "$CONFIG_TEMP" "$CONFIG"

xml_escape() {
  printf '%s' "$1" |
    sed \
      -e 's/&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g' \
      -e 's/"/\&quot;/g' \
      -e "s/'/\&apos;/g"
}

APP_EXECUTABLE="$APP_DESTINATION/Contents/MacOS/CodexPetHUD"
ESCAPED_EXECUTABLE="$(xml_escape "$APP_EXECUTABLE")"
ESCAPED_LOG_DIRECTORY="$(xml_escape "$LOG_DIRECTORY")"
sed \
  -e "s|__APP_EXECUTABLE__|$ESCAPED_EXECUTABLE|g" \
  -e "s|__LOG_DIRECTORY__|$ESCAPED_LOG_DIRECTORY|g" \
  "$ROOT/scripts/com.codex-pet-hud.agent.plist.template" \
  > "$PLIST"
chmod 600 "$PLIST"
plutil -lint "$PLIST" >/dev/null

if [ "${CODEX_PET_HUD_TESTING:-0}" != "1" ]; then
  launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
  if [ "$SHOULD_LAUNCH" -eq 1 ]; then
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
  fi
fi

printf 'Installed %s\n' "$APP_DESTINATION"
printf 'Configuration: %s\n' "$CONFIG"
