# FPCMOH driver rollback

This experimental package replaces Arch's official `libfprint` package.

To restore the official library:

```bash
sudo pacman -S libfprint
sudo systemctl restart fprintd.service
```

Pacman will ask to remove the conflicting `libfprint-fpcmoh-git` package.
Confirm that replacement.

Do not enable fingerprint authentication in PAM unless both
`fprintd-enroll` and repeated `fprintd-verify` scans succeed. If PAM has
subsequently been configured, restore its backed-up files before removing a
working fingerprint setup.
