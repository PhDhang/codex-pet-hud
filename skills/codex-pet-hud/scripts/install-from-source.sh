#!/bin/bash

set -euo pipefail

DEFAULT_REPO="https://github.com/PhDhang/codex-pet-hud.git"
REPO="${CODEX_PET_HUD_REPO_URL:-$DEFAULT_REPO}"
REF="main"
PET_PATH=""
DESTINATION="$HOME/.local/src/codex-pet-hud"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --pet-path)
      PET_PATH="$2"
      shift 2
      ;;
    --destination)
      DESTINATION="$2"
      shift 2
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$PET_PATH" ]; then
  printf 'Usage: install-from-source.sh --pet-path PATH [--repo URL] [--ref REF] [--destination PATH]\n' >&2
  exit 2
fi

if [ -e "$DESTINATION" ] && [ ! -d "$DESTINATION/.git" ]; then
  printf 'Destination exists and is not a git repository: %s\n' "$DESTINATION" >&2
  exit 2
fi

if [ ! -d "$DESTINATION/.git" ]; then
  mkdir -p "$(dirname "$DESTINATION")"
  git clone "$REPO" "$DESTINATION"
else
  current_origin="$(git -C "$DESTINATION" remote get-url origin)"
  if [ "$current_origin" != "$REPO" ]; then
    printf 'Existing destination uses a different origin.\n' >&2
    exit 2
  fi
fi

git -C "$DESTINATION" fetch --tags origin
if git -C "$DESTINATION" rev-parse --verify "$REF^{commit}" >/dev/null 2>&1; then
  TARGET_REF="$REF"
elif git -C "$DESTINATION" rev-parse --verify "origin/$REF^{commit}" >/dev/null 2>&1; then
  TARGET_REF="origin/$REF"
else
  printf 'Source ref does not exist: %s\n' "$REF" >&2
  exit 2
fi
git -C "$DESTINATION" checkout --detach "$TARGET_REF"

cd "$DESTINATION"
swift test --disable-sandbox
for test_script in Tests/Shell/*.bats; do
  if [ "$test_script" = "Tests/Shell/install-from-source.bats" ]; then
    continue
  fi
  bash "$test_script"
done
scripts/build-app.sh
scripts/install.sh --pet-path "$PET_PATH"
if [ "${CODEX_PET_HUD_TESTING:-0}" != "1" ]; then
  "$HOME/Applications/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD" \
    --diagnose
fi
