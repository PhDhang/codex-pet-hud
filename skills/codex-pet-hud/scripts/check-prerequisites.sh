#!/bin/bash

set -euo pipefail

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'status=unsupported-platform\n'
  exit 2
fi

if ! command -v swift >/dev/null 2>&1; then
  printf 'status=missing-swift\n'
  exit 2
fi

CODEX_HOME_PATH="${CODEX_HOME:-$HOME/.codex}"
AUTH="$CODEX_HOME_PATH/auth.json"
PETS_ROOT="$CODEX_HOME_PATH/pets"

printf 'platform=macOS\n'
printf 'swift=%s\n' "$(swift --version | head -1)"
if [ -f "$AUTH" ]; then
  printf 'auth=found\n'
else
  printf 'auth=missing\n'
fi

VALID_COUNT=0
if [ -d "$PETS_ROOT" ]; then
  while IFS= read -r manifest; do
    version="$(
      /usr/bin/plutil \
        -extract spriteVersionNumber raw \
        -o - \
        "$manifest" 2>/dev/null || true
    )"
    spritesheet="$(
      /usr/bin/plutil \
        -extract spritesheetPath raw \
        -o - \
        "$manifest" 2>/dev/null || true
    )"
    if [ "$version" = "2" ] &&
      [ -n "$spritesheet" ] &&
      [ -f "$(dirname "$manifest")/$spritesheet" ]; then
      VALID_COUNT=$((VALID_COUNT + 1))
      printf 'pet=%s\n' "$(dirname "$manifest")"
    fi
  done < <(find "$PETS_ROOT" -mindepth 2 -maxdepth 2 -name pet.json -type f | sort)
fi

printf 'valid_v2_pets=%s\n' "$VALID_COUNT"
if [ ! -f "$AUTH" ]; then
  exit 3
fi
if [ "$VALID_COUNT" -eq 0 ]; then
  exit 4
fi
if [ "$VALID_COUNT" -gt 1 ]; then
  exit 5
fi

printf 'status=ready\n'
