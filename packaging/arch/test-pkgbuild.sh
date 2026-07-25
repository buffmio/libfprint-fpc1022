#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
# shellcheck disable=SC1091
source ./PKGBUILD

# shellcheck disable=SC2154
[[ $pkgname == libfprint-fpc1022 ]]
# shellcheck disable=SC2154
[[ $pkgver == 1.94.10.r2.gba10c93 ]]
[[ ${_commit:-} == ba10c9398fe4542ff6403549884d0c8687182845 ]]
# shellcheck disable=SC2154
[[ " ${provides[*]} " == *' libfprint=1.94.10 '* ]]
[[ " ${provides[*]} " == *' libfprint-2.so '* ]]
# shellcheck disable=SC2154
[[ " ${conflicts[*]} " == *' libfprint '* ]]
# shellcheck disable=SC2154
[[ " ${depends[*]} " == *' opencv '* ]]
[[ " ${depends[*]} " == *' libstdc++ '* ]]
# shellcheck disable=SC2154
[[ " ${optdepends[*]} " == *' fprintd:'* ]]

declare -F build >/dev/null
declare -F check >/dev/null
declare -F package >/dev/null

printf 'Arch/AUR PKGBUILD contract checks passed\n'
