# libfprint-fpc1022 v0.1.0-wip

This is an experimental, unofficial libfprint build based on upstream
merge request !570. It has been tested only with the FPC Sensor Controller
whose USB ID is `10a5:9200`.

The attached DEB and RPM packages replace the distribution's libfprint
library. They do not bundle `fprintd` and do not change PAM, SDDM, GDM, or
desktop authentication settings.

Arch Linux users should install
[`libfprint-fpc1022`](https://aur.archlinux.org/packages/libfprint-fpc1022)
from AUR; no Arch binary is attached to this Release.

Check every download against `SHA256SUMS`. Installation and rollback commands
are documented in the repository README.
