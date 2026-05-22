# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
#
# Pacote per-device Amlogic-no (Valhall S905X5/X5M/S928X).
# Força os symlinks libEGL/libGLESv1_CM/libGLESv2 (em /usr/lib) a apontarem
# para libMali.so (Valhall blob CoreELEC), sobrescrevendo o que o libglvnd
# instala. Roda APÓS libglvnd e opengl-meson via PKG_DEPENDS_TARGET. O merge
# final do system/ usa a ordem de dependência, então o INSTALL deste pacote
# ganha.
#
# /usr/lib32 é tratado pelo override device de compat/lib32 (rsync acontece
# durante o install do lib32).

PKG_NAME="mali-egl-symlinks"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain libglvnd opengl-meson"
PKG_LONGDESC="Amlogic-no: force libEGL/libGLES* symlinks to libMali blob"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib

  # libMali.so existe via opengl-meson como symlink pra /var/lib/libMali.so
  # (overlay runtime). Em build-time o target não resolve — usar -L em vez de -e.
  ln -sf /var/lib/libMali.so ${INSTALL}/usr/lib/libMali.so

  for stem in libEGL libGLESv2 libGLESv1_CM; do
    for suffix in .so .so.1 .so.2 .so.1.0.0 .so.1.1.0 .so.2.0.0 .so.1.2.0; do
      ln -sf libMali.so "${INSTALL}/usr/lib/${stem}${suffix}"
    done
  done
}
