#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
source ./PKGBUILD

[[ $pkgname == libfprint-fpc1022 ]]
[[ $pkgver == 1.94.10.r2.gba10c93 ]]
[[ ${_commit:-} == ba10c9398fe4542ff6403549884d0c8687182845 ]]
[[ " ${provides[*]} " == *' libfprint=1.94.10 '* ]]
[[ " ${provides[*]} " == *' libfprint-2.so '* ]]
[[ " ${conflicts[*]} " == *' libfprint '* ]]
[[ " ${depends[*]} " == *' opencv '* ]]
[[ " ${depends[*]} " == *' libstdc++ '* ]]
[[ " ${optdepends[*]} " == *' fprintd:'* ]]

declare -F build >/dev/null
declare -F check >/dev/null
declare -F package >/dev/null

printf 'Arch/AUR PKGBUILD contract checks passed\n'
