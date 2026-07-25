#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/packaging/version.env"

[[ $PROJECT_VERSION == 0.1.0 ]]
[[ $RELEASE_TAG == v0.1.0-wip ]]
[[ $UPSTREAM_ABI_VERSION == 1.94.10 ]]
[[ $SUPPORTED_USB_ID == 10a5:9200 ]]
rg -q '0x10A5.*0x9200' "$root/libfprint/drivers/fpcmoh/fpcmoh.c"

for path in "$root/packaging/arch" "$root/packaging/debian" "$root/packaging/rpm"; do
  [[ -d $path ]]
done

if rg -n '/etc/pam\.d|fprintd\.service|sddm' \
  "$root/packaging/arch" "$root/packaging/debian" "$root/packaging/rpm"; then
  printf 'Packaging must not modify PAM, fprintd, or SDDM configuration\n' >&2
  exit 1
fi
