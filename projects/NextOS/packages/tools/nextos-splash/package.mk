# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025 NextOS (https://github.com/felc18-blip/NextOS)
# 2026-05-17 NextOS fork: Amlogic-nxtos usa felc18-blip/nextos-splash
# (logo NextOS embutido renderizado em /dev/fb0 via libm).
# 2026-05-22: estendido a Amlogic-no — mesmo binário rola em kernel BSP 5.15
# com CONFIG_DRM_FBDEV_EMULATION=y. Demais devices seguem upstream rocknix-splash.

PKG_NAME="nextos-splash"
PKG_LICENSE="GPL"
PKG_DEPENDS_INIT="toolchain"

if [ "${DEVICE}" = "Amlogic-nxtos" ] || [ "${DEVICE}" = "Amlogic-no" ]; then
  PKG_VERSION="8c750f7b7c7fc4ebd28031105de50bdf36380bfb"
  PKG_SITE="https://github.com/felc18-blip/nextos-splash"
  PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
  PKG_LONGDESC="NextOS splash screen application (logo NextOS embutido em /dev/fb0)"
else
  PKG_VERSION="3527c70c21d4552c4049990ca6057cc223cf8d33"
  PKG_SITE="https://github.com/felc18-blip/NextOS"
  PKG_URL="https://github.com/felc18-blip/${PKG_NAME}/archive/${PKG_VERSION}.tar.gz"
  PKG_LONGDESC="NextOS splash screen application"
fi

post_unpack() {
  if [ "${DEVICE}" = "Amlogic-nxtos" ] || [ "${DEVICE}" = "Amlogic-no" ]; then
    # nextos-splash já tem TARGET=nextos-splash; manter compat com refs em
    # initramfs/busybox init (sem rebrand desses).
    sed -i 's|TARGET=nextos-splash|TARGET=nextos-splash|' ${PKG_BUILD}/Makefile
  else
    # Fix binary name: rocknix-splash -> nextos-splash
    sed -i 's|TARGET=rocknix-splash|TARGET=nextos-splash|' ${PKG_BUILD}/Makefile
  fi
}
