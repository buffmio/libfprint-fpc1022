#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build="$root/.github/workflows/build.yml"
release="$root/.github/workflows/release.yml"

for id in ubuntu-24.04 ubuntu-26.04 debian-13 fedora-42 fedora-43; do
  rg -q "$id" "$build"
  rg -q "$id" "$release"
done

rg -q 'retention-days: 7' "$build"
if rg -q 'build-arch|\.pkg\.tar' "$build" "$release"; then
  printf 'Arch binaries must not be built by GitHub Actions\n' >&2
  exit 1
fi
rg -q "'v\\*-wip'" "$release"
rg -q 'contents: write' "$release"
rg -q 'needs: build' "$release"
rg -q 'collect-release\.sh' "$release"
rg -q 'SHA256SUMS' "$release"
rg -q 'docs/release-notes-v0\.1\.0-wip\.md' "$release"

printf 'GitHub workflow contract checks passed\n'
