#!/usr/bin/env bash
set -euo pipefail

case ${DISTRO_ID:-} in
  ubuntu-24.04|ubuntu-26.04|debian-13) ;;
  *) printf 'Unsupported DISTRO_ID: %s\n' "${DISTRO_ID:-unset}" >&2; exit 2 ;;
esac

root=$(pwd -P)
[[ -f $root/meson.build ]]
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  build-essential debhelper dpkg-dev git gobject-introspection ripgrep \
  libcairo2-dev libglib2.0-dev libgudev-1.0-dev libgusb-dev libopencv-dev \
  libpixman-1-dev libssl-dev libudev-dev meson ninja-build pkgconf \
  python3 python3-cairo python3-gi udev umockdev

git config --global --add safe.directory "$root"
"$root/packaging/debian/test-debian-package.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/source"
git -C "$root" archive HEAD | tar -x -C "$work/source"
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
