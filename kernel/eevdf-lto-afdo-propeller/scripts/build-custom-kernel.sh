#!/usr/bin/env bash
set -euo pipefail

mkdir -p /build/linux-cachyos
cp -a /src/. /build/linux-cachyos/
cd /build/linux-cachyos/linux-cachyos
chown -R builder:builder /out /build

su builder -c "
  updpkgsums
  makepkg -o
  mv config-*-eevdf-lto-afdo-propeller config
  patch config < /patches/config.patch
  updpkgsums
  makepkg -s --noconfirm --skippgpcheck
  cp -v *.pkg.tar.zst /out/
"
