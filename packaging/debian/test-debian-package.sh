#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
debian="$root/packaging/debian/debian"

rg -q '^Source: libfprint-fpc1022$' "$debian/control"
rg -q '^Package: libfprint-fpc1022$' "$debian/control"
rg -q '^Provides: libfprint-2-2' "$debian/control"
rg -q '^Conflicts: libfprint-2-2' "$debian/control"
rg -q '^Replaces: libfprint-2-2' "$debian/control"
rg -q 'libopencv-dev' "$debian/control"
rg -q 'libssl-dev' "$debian/control"
rg -q '^3\.0 \(native\)$' "$debian/source/format"
test -x "$debian/rules"

if rg -n -g '!test-*.sh' '/etc/pam\.d|fprintd\.service|sddm' "$debian"; then
  printf 'Debian package must not modify authentication configuration\n' >&2
  exit 1
fi

printf 'Debian package contract checks passed\n'
