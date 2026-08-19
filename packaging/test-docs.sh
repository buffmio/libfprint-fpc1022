#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readme="$root/README.md"
release_notes="$root/docs/release-notes-v0.1.0-wip.md"

for text in \
  '10a5:9200' 'v0.1.0-wip' 'Arch Linux' \
  'latest stable image' 'ubuntu:latest' 'debian:stable' 'fedora:latest' \
  'fprintd-enroll' 'fprintd-verify' 'experimental' 'MR !570' 'LGPL-2.1'; do
  grep -Fiq "$text" "$readme"
done

if grep -En 'Ubuntu 24\.04|Ubuntu 26\.04|Debian 13|Fedora 42|Fedora 43|Fedora 44' "$readme"; then
  printf 'README must not list pinned distro releases\n' >&2
  exit 1
fi

grep -Eq 'aur\.archlinux\.org/packages/libfprint-fpc1022' "$readme"
grep -Eq 'pacman .*libfprint' "$root/packaging/ROLLBACK.md"
grep -Eq 'apt .*libfprint' "$root/packaging/ROLLBACK.md"
grep -Eq 'dnf .*libfprint' "$root/packaging/ROLLBACK.md"
grep -Eq 'gitlab\.freedesktop\.org/libfprint/libfprint' "$root/docs/ATTRIBUTION.md"
grep -Eq 'merge_requests/570' "$root/docs/ATTRIBUTION.md"
grep -Pzoq 'installation\s+options for Arch Linux, Debian, Ubuntu, and Fedora' "$readme"
grep -Pzoq 'packages for Debian, Ubuntu, and Fedora' "$release_notes"
grep -Fq 'from AUR' "$release_notes"

printf 'Documentation contract checks passed\n'
