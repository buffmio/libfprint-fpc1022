#!/usr/bin/env bash
set -euo pipefail

source /etc/os-release
case ${DISTRO_FAMILY:-} in
  ubuntu|debian) ;;
  *) printf 'Unsupported DISTRO_FAMILY: %s\n' "${DISTRO_FAMILY:-unset}" >&2; exit 2 ;;
esac

if [[ ${ID:-} != "$DISTRO_FAMILY" ]]; then
  printf 'Container ID does not match DISTRO_FAMILY\n' >&2
  exit 2
fi
root=$(pwd -P)
DISTRO_ID="${ID}-${VERSION_ID}"
[[ -f $root/meson.build ]]
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  build-essential debhelper dpkg-dev git gobject-introspection ripgrep \
  libcairo2-dev libglib2.0-dev libgudev-1.0-dev libgusb-dev libopencv-dev \
  libpixman-1-dev libssl-dev libudev-dev meson ninja-build pkgconf \
  python3 python3-cairo python3-gi udev umockdev

"$root/packaging/debian/test-debian-package.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/source"
tar -C "$root" --exclude=.git --exclude=artifacts -cf - . |
  tar -x -C "$work/source"
cp -a "$work/source/packaging/debian/debian" "$work/source/debian"
(
  cd "$work/source"
  dpkg-buildpackage -us -uc -b
)

out="$root/artifacts/$DISTRO_ID"
mkdir -p "$out"
package=$(find "$work" -maxdepth 1 -name 'libfprint-fpc1022_*_amd64.deb' -print -quit)
[[ -n $package ]]
renamed="libfprint-fpc1022_0.1.0-1_${DISTRO_ID}_amd64.deb"
cp "$package" "$out/$renamed"
stage="$work/stage"
mkdir "$stage"
dpkg-deb -x "$out/$renamed" "$stage"
"$root/packaging/test-installed-tree.sh" "$stage"
