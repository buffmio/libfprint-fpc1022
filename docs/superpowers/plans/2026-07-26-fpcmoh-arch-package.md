# FPCMOH Arch Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, install, test, and document a reversible Arch package providing the experimental libfprint driver for USB device `10a5:9200`.

**Architecture:** A pinned PKGBUILD builds libfprint MR !570 as a pacman-owned replacement for `libfprint`. Shell-based static checks validate package metadata before a clean build; fprintd enrollment and verification gate any later PAM configuration.

**Tech Stack:** Arch `makepkg`/pacman, Meson, Ninja, libfprint, fprintd, OpenCV 5, OpenSSL

## Global Constraints

- Use libfprint MR !570 commit `ba10c9398fe4542ff6403549884d0c8687182845`.
- The package must provide and conflict with `libfprint`.
- Do not modify PAM until enrollment and verification both succeed.
- Installation requiring sudo remains an explicit user-run step.
- Rollback must use pacman to reinstall the official `libfprint`.

---

### Task 1: Reproducible Arch package

**Files:**
- Create: `packaging/PKGBUILD`
- Create: `packaging/test-pkgbuild.sh`

**Interfaces:**
- Consumes: the current libfprint source checkout at the pinned MR commit
- Produces: `libfprint-fpcmoh-git-1.94.10.r2.gba10c93-1-x86_64.pkg.tar.zst`

- [ ] **Step 1: Write the failing metadata test**

Create `packaging/test-pkgbuild.sh` with assertions that source `packaging/PKGBUILD`, require the exact `_commit`, check `provides=('libfprint=1.94.10')`, `conflicts=('libfprint')`, dependencies on `opencv`, `openssl`, and `libgusb`, and verify the Meson driver list includes `fpcmoh`.

- [ ] **Step 2: Run the test and verify it fails**

Run: `bash packaging/test-pkgbuild.sh`

Expected: FAIL because `packaging/PKGBUILD` does not exist.

- [ ] **Step 3: Implement the PKGBUILD**

Create `packaging/PKGBUILD` using:

```bash
pkgname=libfprint-fpcmoh-git
pkgver=1.94.10.r2.gba10c93
pkgrel=1
pkgdesc='libfprint with experimental FPC1022/Disum 10a5:9200 support'
arch=('x86_64')
url='https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/570'
license=('LGPL-2.1-or-later')
depends=('glib2' 'glibc' 'libgcc' 'libgudev' 'libgusb' 'opencv'
         'openssl' 'pixman')
makedepends=('git' 'glib2-devel' 'gobject-introspection' 'gtk-doc' 'meson'
             'python-cairo' 'python-gobject' 'systemd')
checkdepends=('cairo' 'umockdev')
provides=('libfprint=1.94.10')
conflicts=('libfprint')
_commit='ba10c9398fe4542ff6403549884d0c8687182845'
source=("git+https://gitlab.freedesktop.org/libfprint/libfprint.git#commit=${_commit}")
sha256sums=('SKIP')
```

Use `arch-meson` with `-D drivers=all`, Ninja for compilation/tests, and
`DESTDIR="$pkgdir" meson install -C build` for packaging.

- [ ] **Step 4: Run static package checks**

Run: `bash packaging/test-pkgbuild.sh && bash -n packaging/PKGBUILD`

Expected: both commands exit 0.

- [ ] **Step 5: Commit**

```bash
git add packaging/PKGBUILD packaging/test-pkgbuild.sh
git commit -m "packaging: add pinned Arch package for fpcmoh"
```

### Task 2: Build and inspect the package

**Files:**
- Modify only generated, ignored build artifacts under `packaging/`

**Interfaces:**
- Consumes: `packaging/PKGBUILD`
- Produces: a locally built pacman package whose files match libfprint's expected layout

- [ ] **Step 1: Install build dependencies interactively**

Run from `packaging/`: `makepkg -s`

Expected: pacman asks the user for their sudo password and installs missing dependencies.

- [ ] **Step 2: Run the upstream test suite**

Run: `meson test -C src/libfprint/build --print-errorlogs`

Expected: all enabled tests pass. Any hardware-only skipped tests are recorded.

- [ ] **Step 3: Build the package**

Run: `makepkg --noextract`

Expected: one `libfprint-fpcmoh-git-*.pkg.tar.zst` is produced.

- [ ] **Step 4: Inspect the package**

Run:

```bash
pacman -Qip libfprint-fpcmoh-git-*.pkg.tar.zst
pacman -Qlp libfprint-fpcmoh-git-*.pkg.tar.zst |
  grep -E 'libfprint-2\.so|60-autosuspend-libfprint|70-libfprint'
```

Expected: package metadata declares the replacement and the library, hwdb, and udev rule files are present.

### Task 3: Install and verify the physical sensor

**Files:**
- Create: `packaging/ROLLBACK.md`

**Interfaces:**
- Consumes: built package and USB device `10a5:9200`
- Produces: a verified fprintd enrollment, or a clean rollback without PAM changes

- [ ] **Step 1: Document rollback before installation**

Document these recovery commands in `packaging/ROLLBACK.md`:

```bash
sudo pacman -S libfprint
sudo systemctl restart fprintd.service
```

Also record that PAM must not be enabled unless verification completes.

- [ ] **Step 2: Install the driver and fprintd**

Run:

```bash
sudo pacman -U ./libfprint-fpcmoh-git-*.pkg.tar.zst
sudo pacman -S fprintd usbutils
sudo systemd-hwdb update
sudo udevadm trigger
```

Expected: pacman replaces `libfprint`; `fprintd` and `lsusb` become available.

- [ ] **Step 3: Verify discovery**

Run:

```bash
lsusb -d 10a5:9200
fprintd-list "$USER"
```

Expected: USB device is shown and fprintd does not return “No devices available”.

- [ ] **Step 4: Enroll and verify**

Run:

```bash
fprintd-enroll
fprintd-verify
```

Expected: enrollment completes and repeated scans report `verify-match`.

- [ ] **Step 5: Collect diagnostics on failure**

Run:

```bash
journalctl -u fprintd -b --no-pager -n 200
G_MESSAGES_DEBUG=all fprintd-enroll
```

Expected: preserve the exact failing operation; do not change PAM.

- [ ] **Step 6: Commit rollback documentation**

```bash
git add packaging/ROLLBACK.md
git commit -m "docs: add fpcmoh rollback procedure"
```

### Task 4: Optional authentication integration

**Files:**
- System PAM files selected by the user's desktop/login stack

**Interfaces:**
- Consumes: successful repeated `fprintd-verify` results
- Produces: fingerprint authentication for only the user-approved PAM services

- [ ] **Step 1: Identify the active display manager and requested services**

Run: `systemctl status display-manager.service --no-pager`

Expected: the active login stack is known before any PAM edit.

- [ ] **Step 2: Back up and change only approved PAM services**

Use Arch's `pam_fprintd.so` guidance for the identified login stack. Keep password authentication available and do not add fingerprint authentication to unattended privilege paths.

- [ ] **Step 3: Test before ending the current session**

Open a second TTY or terminal and verify both password and fingerprint authentication.

Expected: password fallback works and the fingerprint succeeds; otherwise immediately restore the backed-up PAM files.
