#!/usr/bin/env bash
set -euo pipefail

output_subdir="${1:?usage: build-cachyos-package.sh <output-subdir>}"

mkdir -p /build/linux-cachyos "/out/${output_subdir}"
cp -a /src/. /build/linux-cachyos/
cd /build/linux-cachyos/linux-cachyos
chown -R builder:builder /build /out

su builder -c "
  updpkgsums
  makepkg -o
  cp /build/linux-cachyos/linux-cachyos/config-*-cachyos config
  updpkgsums
  makepkg -s --noconfirm --skippgpcheck
  cp -v *.pkg.tar.zst /out/${output_subdir}/
"
