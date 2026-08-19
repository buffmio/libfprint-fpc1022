#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
debian="$root/packaging/debian/debian"

grep -Eq '^Source: libfprint-fpc1022$' "$debian/control"
grep -Eq '^Package: libfprint-fpc1022$' "$debian/control"
grep -Eq '^Provides: libfprint-2-2' "$debian/control"
grep -Eq '^Conflicts: libfprint-2-2' "$debian/control"
grep -Eq '^Replaces: libfprint-2-2' "$debian/control"
grep -Eq 'libopencv-dev' "$debian/control"
grep -Eq 'libssl-dev' "$debian/control"
grep -Eq '^3\.0 \(native\)$' "$debian/source/format"
test -x "$debian/rules"

if grep -REn --exclude='test-*.sh' '/etc/pam\.d|fprintd\.service|sddm' "$debian"; then
  printf 'Debian package must not modify authentication configuration\n' >&2
  exit 1
fi

printf 'Debian package contract checks passed\n'
