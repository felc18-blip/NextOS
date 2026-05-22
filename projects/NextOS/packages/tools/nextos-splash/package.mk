# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 NextOS (https://github.com/felc18-blip/NextOS)
# 2026-05-17 NextOS fork: Amlogic-nxtos usa felc18-blip/nextos-splash
# (substitui logo "ARCH R" por "NextOS" no framebuffer KMSDRM). Demais
# devices NextOS seguem com o splash upstream felc18-blip/nextos-splash.

PKG_NAME="nextos-splash"
PKG_LICENSE="GPL"
PKG_DEPENDS_INIT="toolchain"

if [ "${DEVICE}" = "Amlogic-nxtos" ]; then
  PKG_VERSION="8c750f7b7c7fc4ebd28031105de50bdf36380bfb"
  PKG_SITE="https://github.com/felc18-blip/nextos-splash"
  PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
  PKG_LONGDESC="NextOS splash screen application (KMSDRM mainline, libdrm)"
else
  PKG_VERSION="3527c70c21d4552c4049990ca6057cc223cf8d33"
  PKG_SITE="https://github.com/felc18-blip/NextOS"
  PKG_URL="https://github.com/felc18-blip/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
  PKG_LONGDESC="NextOS splash screen application"
fi

post_unpack() {
  if [ "${DEVICE}" = "Amlogic-nxtos" ]; then
    # nextos-splash já tem TARGET=nextos-splash. Renomear pra nextos-splash
    # mantém compat com refs em initramfs/busybox init (sem rebrand desses).
    sed -i 's|TARGET=nextos-splash|TARGET=nextos-splash|' ${PKG_BUILD}/Makefile
  else
    # Fix binary name: rocknix-splash -> nextos-splash
    sed -i 's|TARGET=rocknix-splash|TARGET=nextos-splash|' ${PKG_BUILD}/Makefile
  fi
}
