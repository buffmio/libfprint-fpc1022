#!/usr/bin/env bash
set -euo pipefail

spec=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/libfprint-fpc1022.spec

rg -q '^Name:\s+libfprint-fpc1022$' "$spec"
rg -q '^Version:\s+0\.1\.0$' "$spec"
rg -q '^Provides:\s+libfprint ' "$spec"
rg -q '^Obsoletes:\s+libfprint ' "$spec"
rg -q '^Conflicts:\s+libfprint ' "$spec"
rg -q 'pkgconfig\(opencv4\)' "$spec"
rg -q 'pkgconfig\(openssl\)' "$spec"
rg -q '%meson_test' "$spec"
rg -q '^ExclusiveArch:\s+x86_64$' "$spec"

if rg -n '/etc/pam\.d|fprintd\.service|sddm' "$spec"; then
  printf 'RPM must not modify authentication configuration\n' >&2
  exit 1
fi

printf 'RPM package contract checks passed\n'
