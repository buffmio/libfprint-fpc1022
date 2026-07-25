# Arch Linux FPC1022 (`10a5:9200`) support design

## Goal

Enable fingerprint enrollment and verification on this Arch Linux machine's
FPC1022/Disum USB sensor (`10a5:9200`) using libfprint merge request !570.

## Constraints

- The driver is work in progress and is not part of a released libfprint.
- Installation must remain visible to pacman and easy to reverse.
- PAM configuration will only be changed after direct enrollment and
  verification succeed.
- The user must enter their own sudo password for package installation.

## Approach

Create an Arch package named `libfprint-fpcmoh-git`. It will build the reviewed
MR !570 commit and declare that it provides and conflicts with `libfprint`.
The package will be built through `makepkg`, rather than installed directly
with Meson, so pacman owns every installed file.

Install `fprintd` alongside the custom package. Validate the driver first with
device discovery, then fingerprint enrollment, and finally fingerprint
verification. Only after those checks pass may fingerprint PAM authentication
be enabled.

## Components and flow

1. A pinned `PKGBUILD` obtains the libfprint MR source and builds the fpcmoh
   driver with its OpenCV and OpenSSL dependencies.
2. Upstream build tests run before packaging.
3. pacman replaces the official `libfprint` package with the custom package.
4. `fprintd` discovers the sensor through the packaged libfprint library.
5. `fprintd-enroll` and `fprintd-verify` establish whether the experimental
   driver works on this physical unit.

## Failure handling and rollback

Build or test failures stop installation. A failure during enrollment or
verification prevents PAM changes. Rollback consists of reinstalling the
official `libfprint` package, which removes the conflicting custom package.
Any fingerprint PAM configuration made after successful verification must be
reverted before removing a working fingerprint setup.

## Success criteria

- `fprintd` lists the `10a5:9200` sensor without a "No devices available"
  error.
- The user can enroll a finger.
- `fprintd-verify` verifies the enrolled finger repeatedly.
- The system retains a documented pacman-based rollback path.
