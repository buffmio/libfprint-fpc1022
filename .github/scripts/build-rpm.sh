#!/usr/bin/env bash
set -euo pipefail

case ${DISTRO_ID:-} in
  fedora-42|fedora-43) ;;
  *) printf 'Unsupported DISTRO_ID: %s\n' "${DISTRO_ID:-unset}" >&2; exit 2 ;;
esac

root=$(pwd -P)
[[ -f $root/meson.build ]]
dnf install -y \
  cpio gcc gcc-c++ git meson ninja-build ripgrep rpm-build \
  cairo-devel glib2-devel gobject-introspection-devel libgudev-devel \
  libgusb-devel opencv-devel openssl-devel pixman-devel systemd-devel \
  python3-cairo python3-gobject umockdev

"$root/packaging/rpm/test-rpm-package.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
top="$work/rpmbuild"
mkdir -p "$top"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
tar -C "$root" --exclude=.git --exclude=artifacts \
  --transform='s,^,libfprint-fpc1022-0.1.0/,' \
  -czf "$top/SOURCES/libfprint-fpc1022-0.1.0.tar.gz" .
cp "$root/packaging/rpm/libfprint-fpc1022.spec" "$top/SPECS/"
rpmbuild --define "_topdir $top" -ba "$top/SPECS/libfprint-fpc1022.spec"

out="$root/artifacts/$DISTRO_ID"
mkdir -p "$out"
package=$(find "$top/RPMS/x86_64" -name 'libfprint-fpc1022-*.rpm' -print -quit)
[[ -n $package ]]
cp "$package" "$out/"
stage="$work/stage"
mkdir "$stage"
(
  cd "$stage"
  rpm2cpio "$package" | cpio -idm --quiet
)
"$root/packaging/test-installed-tree.sh" "$stage"
