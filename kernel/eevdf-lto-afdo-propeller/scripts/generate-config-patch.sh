#!/usr/bin/env bash
set -euo pipefail

mkdir -p /build/linux-cachyos
cp -a /src/. /build/linux-cachyos/
cd /build/linux-cachyos/linux-cachyos
chown -R builder:builder /patches /build

su builder -c "
  updpkgsums
  makepkg -o
  cd /build/linux-cachyos/linux-cachyos/src/cachyos-*/
  cp /build/linux-cachyos/linux-cachyos/config-*-eevdf-lto-afdo-propeller .config
  LLVM=1 LLVM_IAS=1 make menuconfig
  diff -u --label .config --label .config /build/linux-cachyos/linux-cachyos/config-*-eevdf-lto-afdo-propeller .config > config.patch
  cp config.patch /patches/
"
