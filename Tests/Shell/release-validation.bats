#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

for required_file in \
  README.md \
  CHANGELOG.md \
  LICENSE \
  SECURITY.md \
  docs/architecture.md \
  docs/privacy.md \
  .github/workflows/ci.yml
do
  test -s "$required_file"
done

test ! -e docs/superpowers

grep -F 'macOS 14' README.md
grep -F 'read-only' docs/privacy.md
grep -F 'swift test' .github/workflows/ci.yml
grep -F 'Tests/Shell/' .github/workflows/ci.yml

if rg -n \
  '/Users/[A-Za-z0-9._-]+/|Bearer eyJ|sk-[A-Za-z0-9_-]{20,}' \
  README.md CHANGELOG.md SECURITY.md docs .github; then
  printf 'Release files contain a local path or credential-like value.\n' >&2
  exit 1
fi
