# FPC1022 Source and Multi-Distribution Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish the complete experimental FPC1022 libfprint source and reproducible Arch, Debian/Ubuntu, and Fedora packages in GitHub Release `v0.1.0-wip`.

**Architecture:** The existing `mr-570` source branch becomes the GitHub default branch. Distribution-native packaging lives under `packaging/`, shared shell contract tests validate package identity and supported hardware, and GitHub Actions builds each target in its own container before a single release job publishes checksummed artifacts.

**Tech Stack:** C/C++, Meson/Ninja, libfprint, Bash, makepkg, debhelper/dpkg-buildpackage, RPM/rpmbuild, GitHub Actions, GitHub CLI.

## Global Constraints

- Project package/repository name is `libfprint-fpc1022`.
- First release tag is `v0.1.0-wip`; package version is `0.1.0`.
- Supported hardware is USB ID `10a5:9200`; no other hardware is claimed as tested.
- Targets are Arch Linux, Ubuntu 24.04, Ubuntu 26.04, Debian 13, Fedora 42, and Fedora 43.
- Only x86_64/amd64 packages are released.
- Packages replace the distribution `libfprint` package but do not bundle `fprintd`.
- PAM, SDDM, GDM, and KDE configuration is never modified.
- The source remains LGPL-2.1-or-later and preserves upstream history and attribution.
- AUR remains a separate remote and is not automatically pushed by CI.

---

## File Map

- `README.md`: project status, supported hardware, packages, installation, verification, rollback, attribution.
- `packaging/version.env`: single release/package version contract consumed by tests and workflows.
- `packaging/test-release-contract.sh`: static cross-format validation.
- `packaging/test-installed-tree.sh`: validates staged files and prevents accidental `fprintd`/PAM content.
- `packaging/arch/PKGBUILD`: repository-source Arch package.
- `packaging/arch/test-pkgbuild.sh`: Arch package contract.
- `packaging/debian/debian/*`: Debian/Ubuntu source packaging metadata.
- `packaging/rpm/libfprint-fpc1022.spec`: Fedora package metadata and build recipe.
- `.github/scripts/build-arch.sh`: clean Arch container build entry point.
- `.github/scripts/build-deb.sh`: clean Debian/Ubuntu container build entry point.
- `.github/scripts/build-rpm.sh`: clean Fedora container build entry point.
- `.github/scripts/collect-release.sh`: normalizes artifact names and writes SHA-256 sums.
- `.github/workflows/build.yml`: branch/PR build matrix and artifact upload.
- `.github/workflows/release.yml`: tag build matrix and atomic Release publication.

### Task 1: Establish the release contract

**Files:**
- Create: `packaging/version.env`
- Create: `packaging/test-release-contract.sh`
- Modify: `.gitignore`

**Interfaces:**
- Produces: shell variables `PROJECT_VERSION=0.1.0`, `RELEASE_TAG=v0.1.0-wip`, `UPSTREAM_ABI_VERSION=1.94.10`, and `SUPPORTED_USB_ID=10a5:9200`.
- Consumed by: all package contract tests, build scripts, and release workflows.

- [ ] **Step 1: Write the failing release contract test**

Create `packaging/test-release-contract.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$root/packaging/version.env"

[[ $PROJECT_VERSION == 0.1.0 ]]
[[ $RELEASE_TAG == v0.1.0-wip ]]
[[ $UPSTREAM_ABI_VERSION == 1.94.10 ]]
[[ $SUPPORTED_USB_ID == 10a5:9200 ]]
rg -q '0x10A5, \\.pid = 0x9200' "$root/libfprint/drivers/fpcmoh/fpcmoh.c"
! rg -n '/etc/pam\\.d|fprintd\\.service|sddm' \
  "$root/packaging/arch" "$root/packaging/debian" "$root/packaging/rpm"
```

- [ ] **Step 2: Run the test and verify the missing contract fails**

Run: `bash packaging/test-release-contract.sh`

Expected: FAIL because `packaging/version.env` and the three distribution directories do not exist.

- [ ] **Step 3: Add the version contract and generated-file ignores**

Create `packaging/version.env`:

```bash
PROJECT_VERSION=0.1.0
RELEASE_TAG=v0.1.0-wip
UPSTREAM_ABI_VERSION=1.94.10
SUPPORTED_USB_ID=10a5:9200
```

Append to `.gitignore`:

```gitignore
artifacts/
packaging/arch/pkg/
packaging/arch/src/
packaging/arch/*.pkg.tar.*
packaging/debian/debian/.debhelper/
packaging/debian/debian/files
packaging/debian/debian/libfprint-fpc1022/
packaging/rpm/RPMS/
packaging/rpm/SRPMS/
```

Create the empty packaging directories before rerunning the test.

- [ ] **Step 4: Run the contract test**

Run: `bash packaging/test-release-contract.sh`

Expected: PASS with exit status 0.

- [ ] **Step 5: Commit**

```bash
git add .gitignore packaging/version.env packaging/test-release-contract.sh \
  packaging/arch packaging/debian packaging/rpm
git commit -m "test: define fpc1022 release contract"
```

### Task 2: Convert the Arch package to build the tagged source tree

**Files:**
- Create: `packaging/arch/PKGBUILD`
- Create: `packaging/arch/test-pkgbuild.sh`
- Create: `packaging/arch/makepkg-ascii.conf`
- Remove: `packaging/PKGBUILD`
- Remove: `packaging/test-pkgbuild.sh`
- Remove: `packaging/makepkg-ascii.conf`

**Interfaces:**
- Consumes: the repository worktree and `packaging/version.env`.
- Produces: `libfprint-fpc1022-0.1.0-1-x86_64.pkg.tar.zst`.

- [ ] **Step 1: Write the failing Arch package test**

Base `packaging/arch/test-pkgbuild.sh` on the existing contract test, replacing the pinned remote commit assertions with:

```bash
[[ $pkgname == libfprint-fpc1022 ]]
[[ $pkgver == 0.1.0 ]]
[[ ${source[0]} == libfprint-fpc1022::git+file://* ]]
[[ ${source[0]} == *'#commit='* ]]
[[ " ${provides[*]} " == *' libfprint=1.94.10 '* ]]
[[ " ${provides[*]} " == *' libfprint-2.so '* ]]
[[ " ${conflicts[*]} " == *' libfprint '* ]]
[[ " ${depends[*]} " == *' opencv '* ]]
```

Also assert that `package()` does not install any path containing `pam.d`, `fprintd.service`, or `sddm`.

- [ ] **Step 2: Verify the new test fails against the old layout**

Run: `bash packaging/arch/test-pkgbuild.sh`

Expected: FAIL because `packaging/arch/PKGBUILD` is missing.

- [ ] **Step 3: Move and adapt the Arch packaging**

Use `git mv` for the three existing files. Set:

```bash
pkgname=libfprint-fpc1022
pkgver=0.1.0
pkgrel=1
_repo_root=${FPC1022_SOURCE_ROOT:-$(realpath ../..)}
_source_commit=${FPC1022_SOURCE_COMMIT:-$(git -C "$_repo_root" rev-parse HEAD)}
source=("libfprint-fpc1022::git+file://${_repo_root}#commit=${_source_commit}")
sha256sums=('SKIP')
```

Keep the already validated dependencies and Meson options. Make `prepare()` check out the exact source `HEAD` provided by CI, then build from `$srcdir/libfprint-fpc1022`. Keep the deterministic test split: all local suites except `libfprint:data`, followed by `udev-hwdb`.

- [ ] **Step 4: Run Arch static tests**

Run:

```bash
bash packaging/arch/test-pkgbuild.sh
bash packaging/test-release-contract.sh
```

Expected: both PASS.

- [ ] **Step 5: Build and inspect the Arch package**

Run from an Arch environment:

```bash
(
  cd packaging/arch
  makepkg --config makepkg-ascii.conf --syncdeps --cleanbuild --noconfirm
  namcap PKGBUILD ./*.pkg.tar.zst
)
```

Expected: build and tests pass; namcap reports no missing direct runtime dependency.

- [ ] **Step 6: Commit**

```bash
git add -A packaging
git commit -m "build: package tagged source for Arch Linux"
```

### Task 3: Add Debian and Ubuntu packaging

**Files:**
- Create: `packaging/debian/debian/changelog`
- Create: `packaging/debian/debian/control`
- Create: `packaging/debian/debian/copyright`
- Create: `packaging/debian/debian/rules`
- Create: `packaging/debian/debian/source/format`
- Create: `packaging/debian/debian/libfprint-fpc1022.install`
- Create: `packaging/debian/test-debian-package.sh`

**Interfaces:**
- Consumes: a source copy with `packaging/debian/debian` copied to top-level `debian`.
- Produces: `libfprint-fpc1022_0.1.0-1_<distribution>_amd64.deb`.

- [ ] **Step 1: Write the failing Debian metadata test**

Create `packaging/debian/test-debian-package.sh` to source `version.env` and assert:

```bash
rg -q '^Source: libfprint-fpc1022$' packaging/debian/debian/control
rg -q '^Package: libfprint-fpc1022$' packaging/debian/debian/control
rg -q '^Provides: libfprint-2-2' packaging/debian/debian/control
rg -q '^Conflicts: libfprint-2-2' packaging/debian/debian/control
rg -q '^Replaces: libfprint-2-2' packaging/debian/debian/control
rg -q 'libopencv-dev' packaging/debian/debian/control
rg -q 'libssl-dev' packaging/debian/debian/control
rg -q '^3\\.0 \\(native\\)$' packaging/debian/debian/source/format
test -x packaging/debian/debian/rules
```

- [ ] **Step 2: Run the Debian test and verify it fails**

Run: `bash packaging/debian/test-debian-package.sh`

Expected: FAIL because the Debian metadata is missing.

- [ ] **Step 3: Add Debian-native metadata**

Set `debian/changelog` version to `libfprint-fpc1022 (0.1.0-1) unstable; urgency=medium`. Define build dependencies for Meson, Ninja, GLib, GUsb, GUdev, pixman, OpenSSL, OpenCV, introspection, Cairo, umockdev, and gtk-doc. Define the binary package as:

```debcontrol
Package: libfprint-fpc1022
Architecture: amd64
Depends: ${shlibs:Depends}, ${misc:Depends}
Provides: libfprint-2-2
Conflicts: libfprint-2-2
Replaces: libfprint-2-2
Description: experimental libfprint build for FPC1022 10a5:9200
```

Use `dh` with Meson and the same deterministic test exclusions as Arch. Install the library, GObject metadata, udev rules/hwdb, and metainfo paths produced by Meson; do not install fprintd or PAM files.

- [ ] **Step 4: Run Debian static tests**

Run:

```bash
bash packaging/debian/test-debian-package.sh
bash packaging/test-release-contract.sh
```

Expected: both PASS.

- [ ] **Step 5: Build and inspect one Debian package locally or in a matching container**

Run:

```bash
cp -a packaging/debian/debian ./debian
dpkg-buildpackage -us -uc -b
dpkg-deb --info ../libfprint-fpc1022_0.1.0-1_amd64.deb
dpkg-deb --contents ../libfprint-fpc1022_0.1.0-1_amd64.deb
rm -rf ./debian
```

Expected: the package builds, declares the replacement relationship, contains `libfprint-2.so.2`, and contains no PAM or fprintd service file.

- [ ] **Step 6: Commit**

```bash
git add packaging/debian
git commit -m "build: add Debian and Ubuntu packages"
```

### Task 4: Add Fedora RPM packaging

**Files:**
- Create: `packaging/rpm/libfprint-fpc1022.spec`
- Create: `packaging/rpm/test-rpm-package.sh`

**Interfaces:**
- Consumes: a `libfprint-fpc1022-0.1.0.tar.gz` source archive.
- Produces: `libfprint-fpc1022-0.1.0-1.<fedora>.x86_64.rpm`.

- [ ] **Step 1: Write the failing RPM metadata test**

Create `packaging/rpm/test-rpm-package.sh` with assertions for:

```bash
rg -q '^Name: *libfprint-fpc1022$' packaging/rpm/libfprint-fpc1022.spec
rg -q '^Version: *0\\.1\\.0$' packaging/rpm/libfprint-fpc1022.spec
rg -q '^Provides: *libfprint' packaging/rpm/libfprint-fpc1022.spec
rg -q '^Conflicts: *libfprint' packaging/rpm/libfprint-fpc1022.spec
rg -q 'pkgconfig\\(opencv4\\)' packaging/rpm/libfprint-fpc1022.spec
rg -q 'pkgconfig\\(openssl\\)' packaging/rpm/libfprint-fpc1022.spec
rg -q '%meson_test' packaging/rpm/libfprint-fpc1022.spec
```

- [ ] **Step 2: Run the RPM test and verify it fails**

Run: `bash packaging/rpm/test-rpm-package.sh`

Expected: FAIL because the spec is missing.

- [ ] **Step 3: Add the RPM spec**

Define `Name`, `Version`, `Release: 1%{?dist}`, `License: LGPL-2.1-or-later`, source archive name, exact `BuildRequires`, runtime requirements discovered by RPM, and:

```spec
Provides: libfprint = 1.94.10
Obsoletes: libfprint < 1.94.11
Conflicts: libfprint
ExclusiveArch: x86_64
```

Use `%meson -Ddrivers=all -Ddoc=true -Dinstalled-tests=false`, `%meson_build`, deterministic `%meson_test` commands, `%meson_install`, and an explicit `%files` list. Exclude PAM and fprintd service paths.

- [ ] **Step 4: Run RPM static tests**

Run:

```bash
bash packaging/rpm/test-rpm-package.sh
bash packaging/test-release-contract.sh
```

Expected: both PASS.

- [ ] **Step 5: Build and inspect one RPM in Fedora**

Run:

```bash
git archive --format=tar.gz --prefix=libfprint-fpc1022-0.1.0/ \
  -o ~/rpmbuild/SOURCES/libfprint-fpc1022-0.1.0.tar.gz HEAD
rpmbuild -ba packaging/rpm/libfprint-fpc1022.spec
rpm -qpi ~/rpmbuild/RPMS/x86_64/libfprint-fpc1022-*.rpm
rpm -qlp ~/rpmbuild/RPMS/x86_64/libfprint-fpc1022-*.rpm
```

Expected: RPM builds and contains the libfprint library/metadata without PAM or fprintd service files.

- [ ] **Step 6: Commit**

```bash
git add packaging/rpm
git commit -m "build: add Fedora RPM package"
```

### Task 5: Add reusable container build entry points

**Files:**
- Create: `.github/scripts/build-arch.sh`
- Create: `.github/scripts/build-deb.sh`
- Create: `.github/scripts/build-rpm.sh`
- Create: `.github/scripts/collect-release.sh`
- Create: `packaging/test-installed-tree.sh`

**Interfaces:**
- Consumes: `DISTRO_ID`, repository at `/workspace`, and `artifacts/$DISTRO_ID`.
- Produces: distribution-native packages plus `artifacts/SHA256SUMS`.

- [ ] **Step 1: Write failing shell interface tests**

Create `packaging/test-installed-tree.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
tree=${1:?usage: test-installed-tree.sh DIR}
find "$tree" -type f | grep -q 'libfprint-2\\.so\\.2'
! find "$tree" -type f | grep -E '/pam\\.d/|fprintd\\.service|/sddm'
```

Extend `test-release-contract.sh` to require all four scripts, executable bits, `set -euo pipefail`, and use of `DISTRO_ID`.

- [ ] **Step 2: Run the contract test and verify it fails**

Run: `bash packaging/test-release-contract.sh`

Expected: FAIL because the build entry points are missing.

- [ ] **Step 3: Implement the three build scripts**

Each script must:

1. reject an unset/unknown `DISTRO_ID`;
2. install an exact target-specific dependency list;
3. run that packaging format’s static contract test;
4. build the native package;
5. extract it into a temporary directory and call `packaging/test-installed-tree.sh`;
6. copy only final packages to `artifacts/$DISTRO_ID`.

`build-deb.sh` accepts `ubuntu-24.04`, `ubuntu-26.04`, or `debian-13`; it appends the distro suffix to artifact filenames without changing Debian package metadata. `build-rpm.sh` accepts `fedora-42` or `fedora-43`. `build-arch.sh` accepts only `arch`.

- [ ] **Step 4: Implement artifact collection**

`collect-release.sh artifacts release` must copy packages into `release/`, reject duplicate basenames, require exactly one Arch package, three DEBs, and two RPMs, and create deterministic checksums:

```bash
(
  cd release
  find . -maxdepth 1 -type f ! -name SHA256SUMS -printf '%f\n' |
    LC_ALL=C sort |
    xargs sha256sum > SHA256SUMS
)
```

- [ ] **Step 5: Run static and negative tests**

Run:

```bash
bash packaging/test-release-contract.sh
tmp=$(mktemp -d)
! bash packaging/test-installed-tree.sh "$tmp"
rm -rf "$tmp"
shellcheck .github/scripts/*.sh packaging/*.sh packaging/*/*.sh
```

Expected: contract and shellcheck PASS; the empty staged-tree test fails as intended.

- [ ] **Step 6: Commit**

```bash
git add .github/scripts packaging
git commit -m "build: add reproducible package entry points"
```

### Task 6: Add branch and pull-request CI

**Files:**
- Create: `.github/workflows/build.yml`
- Create: `packaging/test-workflows.sh`

**Interfaces:**
- Consumes: build scripts from Task 5.
- Produces: six named CI artifacts with seven-day retention.

- [ ] **Step 1: Write the failing workflow contract test**

Create `packaging/test-workflows.sh` to parse text with `rg` and require:

```bash
rg -q 'ubuntu-24\\.04' .github/workflows/build.yml
rg -q 'ubuntu-26\\.04' .github/workflows/build.yml
rg -q 'debian-13' .github/workflows/build.yml
rg -q 'fedora-42' .github/workflows/build.yml
rg -q 'fedora-43' .github/workflows/build.yml
rg -q 'arch' .github/workflows/build.yml
rg -q 'retention-days: 7' .github/workflows/build.yml
! rg -q 'gh release|softprops/action-gh-release' .github/workflows/build.yml
```

- [ ] **Step 2: Run the workflow test and verify it fails**

Run: `bash packaging/test-workflows.sh`

Expected: FAIL because `build.yml` is missing.

- [ ] **Step 3: Implement `build.yml`**

Trigger on `push` to the default branch, `pull_request`, and `workflow_dispatch`. Use one matrix job with six entries. Each entry specifies its container image and one of the build scripts. Mount the checked-out workspace normally, run as a non-root builder where required by `makepkg`, and upload `artifacts/${{ matrix.id }}` with `actions/upload-artifact`.

Pin third-party GitHub Actions to full commit SHAs; add a comment with the corresponding release version.

- [ ] **Step 4: Validate the workflow**

Run:

```bash
bash packaging/test-workflows.sh
actionlint .github/workflows/build.yml
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/build.yml packaging/test-workflows.sh
git commit -m "ci: build packages for supported distributions"
```

### Task 7: Add atomic tag-driven GitHub Releases

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `docs/release-notes-v0.1.0-wip.md`
- Modify: `packaging/test-workflows.sh`

**Interfaces:**
- Consumes: six package artifact sets from matrix jobs.
- Produces: GitHub Release `v0.1.0-wip` only after all builds succeed.

- [ ] **Step 1: Extend the failing workflow test**

Require:

```bash
rg -q \"v\\*-wip\" .github/workflows/release.yml
rg -q '^ *permissions:' .github/workflows/release.yml
rg -q '^ *contents: write' .github/workflows/release.yml
rg -q 'needs:.*build' .github/workflows/release.yml
rg -q 'collect-release\\.sh' .github/workflows/release.yml
rg -q 'SHA256SUMS' .github/workflows/release.yml
rg -q 'docs/release-notes-v0\\.1\\.0-wip\\.md' .github/workflows/release.yml
```

- [ ] **Step 2: Verify the release test fails**

Run: `bash packaging/test-workflows.sh`

Expected: FAIL because `release.yml` is missing.

- [ ] **Step 3: Implement the release workflow**

Use the same six-entry build matrix as `build.yml`. A separate `release` job has `needs: build`, downloads all artifacts, runs `collect-release.sh`, verifies the tag equals the `RELEASE_TAG` in `version.env`, and executes:

```bash
gh release create "$RELEASE_TAG" release/* \
  --repo "$GITHUB_REPOSITORY" \
  --title "libfprint-fpc1022 $RELEASE_TAG" \
  --notes-file docs/release-notes-v0.1.0-wip.md \
  --verify-tag
```

Set job-level `GH_TOKEN: ${{ github.token }}` and minimal `contents: write` permission. Do not create a draft or partial release before the matrix succeeds.

- [ ] **Step 4: Write exact release notes**

State that the build is experimental, based on libfprint MR !570, tested only with `10a5:9200`, replaces official libfprint, leaves `fprintd` and PAM configuration to the distribution, and includes per-distribution artifact names plus rollback links.

- [ ] **Step 5: Validate**

Run:

```bash
bash packaging/test-workflows.sh
actionlint .github/workflows/release.yml
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/release.yml docs/release-notes-v0.1.0-wip.md \
  packaging/test-workflows.sh
git commit -m "ci: publish atomic multi-distro releases"
```

### Task 8: Replace the upstream README with project release documentation

**Files:**
- Modify: `README.md`
- Modify: `packaging/ROLLBACK.md`
- Create: `docs/ATTRIBUTION.md`
- Create: `packaging/test-docs.sh`

**Interfaces:**
- Consumes: final package names and commands from Tasks 2–7.
- Produces: end-user installation, verification, rollback, licensing, and attribution documentation.

- [ ] **Step 1: Write the failing documentation contract**

Create `packaging/test-docs.sh` requiring README references to:

```text
10a5:9200
v0.1.0-wip
Arch Linux
Ubuntu 24.04
Ubuntu 26.04
Debian 13
Fedora 42
Fedora 43
fprintd-enroll
fprintd-verify
experimental
MR !570
LGPL-2.1
```

Also require rollback commands for `pacman`, `apt`, and `dnf`, and links to upstream libfprint and the original merge request.

- [ ] **Step 2: Run the docs test and verify it fails**

Run: `bash packaging/test-docs.sh`

Expected: FAIL because the upstream README does not describe this fork.

- [ ] **Step 3: Write project-focused documentation**

README sections:

1. experimental status and exact supported USB ID;
2. source provenance and scope;
3. Release artifact table by distribution;
4. installation commands using native package managers;
5. `lsusb`, `fprintd-enroll`, and two-run `fprintd-verify` validation;
6. desktop/PAM caveats;
7. rollback;
8. build-from-source;
9. LGPL-2.1 and upstream attribution.

Move detailed attribution to `docs/ATTRIBUTION.md`, naming libfprint, MR !570, and Sergey Subbotin. Extend `ROLLBACK.md` with apt and dnf commands.

- [ ] **Step 4: Run documentation and link checks**

Run:

```bash
bash packaging/test-docs.sh
markdownlint README.md docs/ATTRIBUTION.md packaging/ROLLBACK.md
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md docs/ATTRIBUTION.md packaging/ROLLBACK.md packaging/test-docs.sh
git commit -m "docs: document fpc1022 packages and rollback"
```

### Task 9: Perform local release-candidate verification

**Files:**
- Modify only files whose tests reveal defects.

**Interfaces:**
- Consumes: all packaging, scripts, workflows, and documentation.
- Produces: a verified commit suitable for pushing and tagging.

- [ ] **Step 1: Run every static test**

Run:

```bash
bash packaging/test-release-contract.sh
bash packaging/arch/test-pkgbuild.sh
bash packaging/debian/test-debian-package.sh
bash packaging/rpm/test-rpm-package.sh
bash packaging/test-workflows.sh
bash packaging/test-docs.sh
shellcheck .github/scripts/*.sh packaging/*.sh packaging/*/*.sh
actionlint .github/workflows/*.yml
git diff --check
```

Expected: all PASS and no output from `git diff --check`.

- [ ] **Step 2: Run the native source test suite**

Run:

```bash
meson setup --wipe build-release \
  -Ddrivers=all -Ddoc=true -Dinstalled-tests=false
meson compile -C build-release
meson test -C build-release --print-errorlogs --no-suite libfprint:data
meson test -C build-release --print-errorlogs udev-hwdb
```

Expected: compilation passes, all deterministic local tests pass, and udev-hwdb passes.

- [ ] **Step 3: Build all six package targets**

Run each `.github/scripts/build-*.sh` in the exact container images declared by `build.yml`, then:

```bash
.github/scripts/collect-release.sh artifacts release
find release -maxdepth 1 -type f -printf '%f\n' | LC_ALL=C sort
sha256sum -c release/SHA256SUMS
```

Expected: one Arch package, three distro-suffixed DEBs, two distro-suffixed RPMs, and a valid `SHA256SUMS`.

- [ ] **Step 4: Perform hardware smoke testing on Arch**

Install the locally built Arch package and run:

```bash
fprintd-list "$USER"
fprintd-verify "$USER"
fprintd-verify "$USER"
```

Expected: the existing enrollment is listed and both verification attempts return `verify-match`.

- [ ] **Step 5: Record verification evidence**

Append a dated table to `docs/release-notes-v0.1.0-wip.md` listing source test count, six package build results, SHA-256 verification, hardware ID, enrollment discovery, and two verification matches. Do not include fingerprint data or secrets.

- [ ] **Step 6: Commit any verification-driven fixes and evidence**

```bash
git add -A
git commit -m "test: verify v0.1.0-wip release candidate"
```

If no tracked file changed, do not create an empty commit.

### Task 10: Publish source, validate CI, and create `v0.1.0-wip`

**Files:**
- No source changes unless CI reveals a reproducible defect.

**Interfaces:**
- Consumes: verified release candidate commit and authenticated GitHub repository.
- Produces: complete default branch and public GitHub Release.

- [ ] **Step 1: Confirm repository identity and clean state**

Run:

```bash
git status --short --branch
git remote get-url github >/dev/null 2>&1 ||
  git remote add github git@github.com:buffmio/libfprint-fpc1022.git
git remote -v
gh repo view buffmio/libfprint-fpc1022 \
  --json nameWithOwner,visibility,defaultBranchRef
```

Expected: only the intentionally ignored nested AUR checkout remains untracked, repository is PUBLIC, and the GitHub remote targets `buffmio/libfprint-fpc1022`.

- [ ] **Step 2: Push complete source history to a temporary review branch**

Run:

```bash
git push github HEAD:refs/heads/source-release-candidate
```

Expected: push succeeds and `build.yml` starts.

- [ ] **Step 3: Wait for and inspect all six GitHub Actions jobs**

Run:

```bash
gh run list --branch source-release-candidate --limit 1
gh run watch --exit-status
```

Expected: every matrix target passes. If any target fails, inspect with `gh run view --log-failed`, fix locally, rerun Task 9, and push a new candidate commit.

- [ ] **Step 4: Replace the GitHub default source branch**

After successful candidate CI:

```bash
git fetch github master
git push github HEAD:master --force-with-lease
gh repo edit buffmio/libfprint-fpc1022 --default-branch master
```

Expected: GitHub `master` contains complete libfprint history. The force operation affects only the one-commit GitHub packaging history; the AUR remote is unchanged.

- [ ] **Step 5: Create and push the signed release tag**

Create an annotated tag after verifying it does not exist:

```bash
! git rev-parse -q --verify refs/tags/v0.1.0-wip
git tag -a v0.1.0-wip -m "libfprint-fpc1022 v0.1.0-wip"
git push github v0.1.0-wip
```

Expected: tag push triggers `release.yml`.

- [ ] **Step 6: Verify the public Release**

Run:

```bash
gh run watch --exit-status
gh release view v0.1.0-wip \
  --repo buffmio/libfprint-fpc1022 \
  --json url,tagName,isDraft,isPrerelease,assets
```

Expected: the release is public, not a draft, references the correct tag, and contains six packages plus `SHA256SUMS` and GitHub source archives.

- [ ] **Step 7: Verify downloads and checksums independently**

Run:

```bash
tmp=$(mktemp -d)
gh release download v0.1.0-wip \
  --repo buffmio/libfprint-fpc1022 --dir "$tmp"
(cd "$tmp" && sha256sum -c SHA256SUMS)
```

Expected: every published package passes checksum validation.

- [ ] **Step 8: Preserve AUR separation**

Run:

```bash
git -C aur/libfprint-fpc1022 remote -v
git -C aur/libfprint-fpc1022 status --short --branch
```

Expected: AUR `origin` still targets `aur.archlinux.org`, and no source-release force push was sent to AUR.
