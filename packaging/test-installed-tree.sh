#!/usr/bin/env bash
set -euo pipefail

tree=${1:?usage: test-installed-tree.sh DIR}
find "$tree" \( -type f -o -type l \) -print | grep -q 'libfprint-2\.so\.2'

if find "$tree" \( -type f -o -type l \) -print |
  grep -Eq '/pam\.d/|fprintd\.service|/sddm'; then
  printf 'Package contains unexpected authentication configuration\n' >&2
  exit 1
fi
