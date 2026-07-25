# libfprint-fpc1022

Experimental, unofficial libfprint source tree with match-on-host support for
the FPC Sensor Controller identified as USB `10a5:9200`.

> This is work-in-progress hardware support. It is not an official libfprint
> release and has been tested only on `10a5:9200`.

## Downloads

The first release is `v0.1.0-wip`.

| Distribution | Installation source |
| --- | --- |
| Arch Linux | [AUR: libfprint-fpc1022](https://aur.archlinux.org/packages/libfprint-fpc1022) |
| Ubuntu 24.04 | Release asset ending in `ubuntu-24.04_amd64.deb` |
| Ubuntu 26.04 | Release asset ending in `ubuntu-26.04_amd64.deb` |
| Debian 13 | Release asset ending in `debian-13_amd64.deb` |
| Fedora 42 | Release asset ending in `.fc42.x86_64.rpm` |
| Fedora 43 | Release asset ending in `.fc43.x86_64.rpm` |

GitHub does not publish an Arch binary because the maintained AUR package is
already available. Every DEB and RPM asset is built inside its target
distribution and is x86_64/amd64 only.

## Install

Arch Linux:

```bash
yay -S libfprint-fpc1022 fprintd
```

Debian or Ubuntu, after downloading the matching asset:

```bash
sudo apt install ./libfprint-fpc1022_*_amd64.deb fprintd
```

Fedora, after downloading the matching asset:

```bash
sudo dnf install ./libfprint-fpc1022-*.x86_64.rpm fprintd
```

The package replaces the distribution libfprint library. It does not bundle
`fprintd` and does not modify PAM, SDDM, GDM, or KDE configuration.

## Verify

```bash
lsusb -d 10a5:9200
fprintd-enroll
fprintd-verify
fprintd-verify
```

Two successful checks should both report `verify-match`. Fingerprint login
still depends on the display manager and PAM configuration supplied by the
distribution. SDDM fingerprint login is intentionally not enabled here.

## Roll back

See [packaging/ROLLBACK.md](packaging/ROLLBACK.md) for native package-manager
commands that restore the official libfprint package.

## Build from source

```bash
meson setup build -Ddrivers=all -Ddoc=false -Dinstalled-tests=false
meson compile -C build
meson test -C build --print-errorlogs --no-suite libfprint:data
meson test -C build --print-errorlogs udev-hwdb
```

The umockdev tests require an ASCII-only source path on systems where
umockdev cannot convert non-ASCII filenames.

## Origin and license

This branch is based on upstream libfprint MR !570 and retains the complete
upstream history. See [docs/ATTRIBUTION.md](docs/ATTRIBUTION.md).

libfprint is licensed under LGPL-2.1-or-later. See [COPYING](COPYING).
