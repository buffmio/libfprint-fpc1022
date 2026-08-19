#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
build="$root/.github/workflows/build.yml"
release="$root/.github/workflows/release.yml"

for image in 'ubuntu:latest' 'debian:stable' 'fedora:latest'; do
  grep -Fq "$image" "$build"
  grep -Fq "$image" "$release"
done
grep -Fq "cron: '17 3 * * 1'" "$release"
grep -Fq 'workflow_dispatch:' "$release"

if grep -Fq "cron: '17 3 * * 1'" "$build"; then
  printf 'Scheduled builds must publish through the release workflow\n' >&2
  exit 1
fi

if grep -Eq 'ubuntu-[0-9]|debian-[0-9]|fedora-[0-9]' "$build" "$release"; then
  printf 'Build workflows must not pin a distro release version\n' >&2
  exit 1
fi

grep -Eq 'retention-days: 7' "$build"
if grep -Eq 'apt-get|ripgrep' "$build"; then
  printf 'Build workflow must not require APT network access for contract tests\n' >&2
  exit 1
fi
if grep -Eq 'build-arch|\.pkg\.tar' "$build" "$release"; then
  printf 'Arch binaries must not be built by GitHub Actions\n' >&2
  exit 1
fi
grep -Eq "'v\\*-wip'" "$release"
grep -Eq 'contents: write' "$release"
grep -Eq 'needs: build' "$release"
grep -Eq 'collect-release\.sh' "$release"
grep -Eq 'SHA256SUMS' "$release"
grep -Eq 'docs/release-notes-v0\.1\.0-wip\.md' "$release"
grep -Fq 'gh release view' "$release"
grep -Fq 'gh release upload' "$release"
grep -Fq -- '--clobber' "$release"

for script in \
  "$root/.github/scripts/build-deb.sh" \
  "$root/.github/scripts/build-rpm.sh"; do
  if grep -Eq 'git .*archive' "$script"; then
    printf '%s must archive the checked-out tree without requiring .git\n' "$script" >&2
    exit 1
  fi
  grep -Eq 'tar .*--exclude=.git' "$script" || {
    printf '%s must exclude Git metadata from source archives\n' "$script" >&2
    exit 1
  }
done

grep -Fq "name 'libfprint-fpc1022-[0-9]*.x86_64.rpm'" \
  "$root/.github/scripts/build-rpm.sh" || {
  printf 'RPM builder must select the main package, not debug packages\n' >&2
  exit 1
}

printf 'GitHub workflow contract checks passed\n'
