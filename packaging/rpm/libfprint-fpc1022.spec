Name:           libfprint-fpc1022
Version:        0.1.0
Release:        1%{?dist}
Summary:        Experimental libfprint build for FPC1022 10a5:9200
License:        LGPL-2.1-or-later
URL:            https://github.com/buffmio/libfprint-fpc1022
Source0:        %{name}-%{version}.tar.gz
Source1:        fprintd-libfprint.te
ExclusiveArch:  x86_64

BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  meson
BuildRequires:  ninja-build
BuildRequires:  selinux-policy-devel
BuildRequires:  pkgconfig(cairo)
BuildRequires:  pkgconfig(gio-unix-2.0)
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gobject-introspection-1.0)
BuildRequires:  pkgconfig(gudev-1.0)
BuildRequires:  pkgconfig(gusb)
BuildRequires:  pkgconfig(opencv4)
BuildRequires:  pkgconfig(openssl)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  pkgconfig(udev)
BuildRequires:  python3-cairo
BuildRequires:  python3-gobject
BuildRequires:  umockdev

Provides:       libfprint = 1.94.10
Provides:       libfprint-devel = 1.94.10
Obsoletes:      libfprint < 1.94.11
Obsoletes:      libfprint-devel < 1.94.11
Requires(post):  policycoreutils
Requires(preun):  policycoreutils
Conflicts:      libfprint > 1.94.10
Suggests:       fprintd

%description
This unofficial libfprint build contains the work-in-progress match-on-host
driver for the FPC Sensor Controller with USB ID 10a5:9200.

%prep
%autosetup
cp %{SOURCE1} fprintd-libfprint.te

%build
%meson \
  -Ddrivers=all \
  -Ddoc=false \
  -Dinstalled-tests=false
make -f %{_datadir}/selinux/devel/Makefile fprintd-libfprint.pp
%meson_build

%check
%meson_test --no-suite libfprint:data
%meson_test udev-hwdb

%install
%meson_install
install -Dpm 0644 fprintd-libfprint.pp %{buildroot}%{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp

%post
if [ "$1" -gt 0 ]; then
  %{_sbindir}/semodule -i %{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp || :
fi

%preun
if [ "$1" -eq 0 ]; then
  %{_sbindir}/semodule -r fprintd-libfprint || :
fi

%files
%license COPYING
%doc README.md NEWS
%{_includedir}/libfprint-2/
%{_libdir}/libfprint-2.so
%{_libdir}/libfprint-2.so.2
%{_libdir}/libfprint-2.so.2.0.0
%{_libdir}/pkgconfig/libfprint-2.pc
%{_libdir}/girepository-1.0/FPrint-2.0.typelib
%{_datadir}/gir-1.0/FPrint-2.0.gir
%{_datadir}/metainfo/org.freedesktop.libfprint.metainfo.xml
%{_udevrulesdir}/70-libfprint-2.rules
%{_prefix}/lib/udev/hwdb.d/60-autosuspend-libfprint-2.hwdb
%{_datadir}/libfprint-2/selinux/fprintd-libfprint.pp

%changelog
* Sun Jul 26 2026 buffmio <laesunny@gmail.com> - 0.1.0-1
- First experimental package for the FPC1022 10a5:9200 sensor.
