# FPC1022 driver rollback

This experimental package replaces Arch's official `libfprint` package.

To restore the official library:

```bash
sudo pacman -S libfprint
sudo systemctl restart fprintd.service
```

Pacman will ask to remove the conflicting `libfprint-fpc1022` package.
Confirm that replacement.

## Debian and Ubuntu

```bash
sudo apt remove libfprint-fpc1022
sudo apt install libfprint-2-2 fprintd
sudo systemctl restart fprintd.service
```

## Fedora

```bash
sudo dnf swap libfprint-fpc1022 libfprint
sudo systemctl restart fprintd.service
```

Do not enable fingerprint authentication in PAM unless both
`fprintd-enroll` and repeated `fprintd-verify` scans succeed. If PAM has
subsequently been configured, restore its backed-up files before removing a
working fingerprint setup.
