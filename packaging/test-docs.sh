#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readme="$root/README.md"
release_notes="$root/docs/release-notes-v0.1.0-wip.md"

for text in \
  '10a5:9200' 'v0.1.0-wip' 'Arch Linux' \
  'latest stable image' 'ubuntu:latest' 'debian:stable' 'fedora:latest' \
  'fprintd-enroll' 'fprintd-verify' 'experimental' 'MR !570' 'LGPL-2.1'; do
  rg -Fiq "$text" "$readme"
done

if rg -n 'Ubuntu 24\.04|Ubuntu 26\.04|Debian 13|Fedora 42|Fedora 43|Fedora 44' "$readme"; then
  printf 'README must not list pinned distro releases\n' >&2
  exit 1
fi

rg -q 'aur\.archlinux\.org/packages/libfprint-fpc1022' "$readme"
rg -q 'pacman .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'apt .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'dnf .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'gitlab\.freedesktop\.org/libfprint/libfprint' "$root/docs/ATTRIBUTION.md"
rg -q 'merge_requests/570' "$root/docs/ATTRIBUTION.md"
rg -Uq 'installation\s+options for Arch Linux, Debian, Ubuntu, and Fedora' "$readme"
rg -Uq 'packages for Debian, Ubuntu, and Fedora' "$release_notes"
rg -Fq 'from AUR' "$release_notes"

printf 'Documentation contract checks passed\n'
