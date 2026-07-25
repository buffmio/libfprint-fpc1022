#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
readme="$root/README.md"

for text in \
  '10a5:9200' 'v0.1.0-wip' 'Arch Linux' 'Ubuntu 24.04' \
  'Ubuntu 26.04' 'Debian 13' 'Fedora 42' 'Fedora 43' \
  'fprintd-enroll' 'fprintd-verify' 'experimental' 'MR !570' 'LGPL-2.1'; do
  rg -Fq "$text" "$readme"
done

rg -q 'aur\.archlinux\.org/packages/libfprint-fpc1022' "$readme"
rg -q 'pacman .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'apt .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'dnf .*libfprint' "$root/packaging/ROLLBACK.md"
rg -q 'gitlab\.freedesktop\.org/libfprint/libfprint' "$root/docs/ATTRIBUTION.md"
rg -q 'merge_requests/570' "$root/docs/ATTRIBUTION.md"

printf 'Documentation contract checks passed\n'
