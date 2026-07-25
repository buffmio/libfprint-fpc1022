#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

[[ -f PKGBUILD ]] || fail 'PKGBUILD is missing'

# shellcheck disable=SC1091
source ./PKGBUILD

[[ ${_commit:-} == ba10c9398fe4542ff6403549884d0c8687182845 ]] ||
  fail 'source commit is not pinned to reviewed MR !570 revision'
[[ ${provides[*]:-} == *'libfprint=1.94.10'* ]] ||
  fail 'package does not provide the compatible libfprint version'
[[ ${conflicts[*]:-} == *'libfprint'* ]] ||
  fail 'package cannot replace the official libfprint package'

for dependency in opencv openssl libgusb; do
  [[ " ${depends[*]:-} " == *" ${dependency} "* ]] ||
    fail "runtime dependency is missing: ${dependency}"
done

declare -F build >/dev/null || fail 'build() is missing'
declare -F check >/dev/null || fail 'check() is missing'
declare -F package >/dev/null || fail 'package() is missing'

printf 'PKGBUILD contract checks passed\n'
