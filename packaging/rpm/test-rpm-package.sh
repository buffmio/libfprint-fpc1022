#!/usr/bin/env bash
set -euo pipefail

spec=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/libfprint-fpc1022.spec
policy=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/fprintd-libfprint.te

grep -Eq '^Name:\s+libfprint-fpc1022$' "$spec"
grep -Eq '^Version:\s+0\.1\.0$' "$spec"
grep -Eq '^Provides:\s+libfprint ' "$spec"
grep -Eq '^Obsoletes:\s+libfprint ' "$spec"
grep -Eq '^Conflicts:\s+libfprint ' "$spec"
grep -Eq 'pkgconfig\(opencv4\)' "$spec"
grep -Eq 'pkgconfig\(openssl\)' "$spec"
grep -Eq '%meson_test' "$spec"
grep -Eq '^ExclusiveArch:\s+x86_64$' "$spec"
grep -Fq '%{_prefix}/lib/udev/hwdb.d/60-autosuspend-libfprint-2.hwdb' "$spec"
grep -Fq 'fprintd-libfprint.pp' "$spec"
grep -Fq 'fprintd-libfprint.te' "$spec"
grep -Fq 'BuildRequires:  selinux-policy-devel' "$spec"
grep -Fq 'Requires(preun):  policycoreutils' "$spec"
grep -Fq 'cp %{SOURCE1} fprintd-libfprint.te' "$spec"
grep -Fq 'make -f %{_datadir}/selinux/devel/Makefile fprintd-libfprint.pp' "$spec"
grep -Fq 'install -Dpm 0644 fprintd-libfprint.pp %{buildroot}%{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp' "$spec"
grep -Fq '%{_sbindir}/semodule -i %{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp' "$spec"
grep -Fq '%{_sbindir}/semodule -r fprintd-libfprint' "$spec"
grep -Fq '%{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp' "$spec"
grep -Eq '^module fprintd-libfprint 1\.0;' "$policy"
grep -Fq 'type fprintd_t;' "$policy"
grep -Fq 'type sysctl_vm_t;' "$policy"
grep -Fq 'class file { getattr open read };' "$policy"
grep -Fq 'allow fprintd_t sysctl_vm_t:file { getattr open read };' "$policy"
if grep -Eq 'write|create|add_name|remove_name|unlink|manage' "$policy"; then
  printf 'SELinux policy must not grant write or management access\n' >&2
  exit 1
fi

if grep -En '/etc/pam\.d|fprintd\.service|sddm' "$spec"; then
  printf 'RPM must not modify authentication configuration\n' >&2
  exit 1
fi

printf 'RPM package contract checks passed\n'
