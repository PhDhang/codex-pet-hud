#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD"

test -x "$APP"

OUTPUT="$(
  perl -e '
    $SIG{ALRM} = sub { exit 124 };
    alarm 5;
    exec @ARGV;
  ' "$APP" --executor-check
)"

test "$OUTPUT" = "executor=ok"
