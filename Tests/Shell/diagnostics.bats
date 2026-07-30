#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/dist/Codex Pet HUD.app/Contents/MacOS/CodexPetHUD"
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT

test -x "$APP"
set +e
HOME="$TEST_HOME" \
CODEX_HOME="$TEST_HOME/.codex" \
  "$APP" --once > "$TEST_HOME/once.json"
result_code=$?
set -e
test "$result_code" -eq 3

test "$(
  plutil -extract fiveHourStatus raw "$TEST_HOME/once.json"
)" = "unavailable"
test "$(
  plutil -extract provider raw "$TEST_HOME/once.json"
)" = "authentication-required"

expected_keys="$(
  printf '%s\n' \
  configuration \
  pet \
  petWindow \
  provider \
  fiveHourStatus \
  | sort
)"
actual_keys="$(
  sed -nE \
    's/^[[:space:]]*"([^"]+)"[[:space:]]*:.*$/\1/p' \
    "$TEST_HOME/once.json" \
  | sort
)"
test "$actual_keys" = "$expected_keys"

if rg -ni \
  'resetAt|fetchedAt|usedPercent|windowDurationSeconds|rawPayload|access[_-]?token|account|email|cookie|snapshot' \
  "$TEST_HOME/once.json"; then
  printf '%s\n' '--once emitted normalized snapshot or private data.' >&2
  exit 1
fi
