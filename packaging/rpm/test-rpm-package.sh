#!/usr/bin/env bash
set -euo pipefail

spec=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/libfprint-fpc1022.spec

grep -Eq '^Name:\s+libfprint-fpc1022$' "$spec"
grep -Eq '^Version:\s+0\.1\.0$' "$spec"
grep -Eq '^Provides:\s+libfprint ' "$spec"
grep -Eq '^Obsoletes:\s+libfprint ' "$spec"
grep -Eq '^Conflicts:\s+libfprint ' "$spec"
grep -Eq 'pkgconfig\(opencv4\)' "$spec"
grep -Eq 'pkgconfig\(openssl\)' "$spec"
grep -Eq '%meson_test' "$spec"
grep -Eq '^ExclusiveArch:\s+x86_64$' "$spec"
grep -Fq '%{_prefix}/lib/udev/hwdb.d/60-autosuspend-libfprint-2.hwdb' "$spec"

if grep -En '/etc/pam\.d|fprintd\.service|sddm' "$spec"; then
  printf 'RPM must not modify authentication configuration\n' >&2
  exit 1
fi

printf 'RPM package contract checks passed\n'
