# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

# 2026-05-28 bump CoreELEC 9709661b — dtc 1.7.2 -> 1.8.0 + meson build.
# Permite remover override Amlogic-no (que estava em 1.8.0 com workaround
# GCC 16 -Wno-error=discarded-qualifiers; upstream 1.8.0+meson não tem o
# problema do fdtput.c que motivou o workaround).
PKG_NAME="dtc"
PKG_VERSION="1.8.0"
PKG_SHA256="b298e24ce4824bd2e2af60cf6a3d2815e555b3e44c431eadad0b52798c83a833"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://git.kernel.org/pub/scm/utils/dtc/dtc.git/"
PKG_URL="https://www.kernel.org/pub/software/utils/dtc/dtc-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="make:host meson:host flex:host ninja:host zlib:host"
PKG_DEPENDS_TARGET="make:host meson:host gcc:host ninja:host zlib"
PKG_LONGDESC="The Device Tree Compiler"

PKG_MESON_OPTS_TARGET="-Ddefault_library=static -Dtests=false"
PKG_MESON_OPTS_HOST="-Dtests=false"

post_make_host() {
  safe_remove ${PKG_BUILD}/.${HOST_NAME}/libfdt/libfdt.so.*.p
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/bin
    cp -P ${PKG_BUILD}/.${HOST_NAME}/dtc ${TOOLCHAIN}/bin
  mkdir -p ${TOOLCHAIN}/lib
    cp -P ${PKG_BUILD}/.${HOST_NAME}/libfdt/libfdt.so* ${TOOLCHAIN}/lib
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/dtc ${INSTALL}/usr/bin
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtput ${INSTALL}/usr/bin/
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtget ${INSTALL}/usr/bin
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/fdtdump ${INSTALL}/usr/bin/
  mkdir -p ${INSTALL}/usr/{include,lib}
    cp -P ${PKG_BUILD}/.${TARGET_NAME}/libfdt/libfdt.a ${SYSROOT_PREFIX}/usr/lib
    cp -P ${PKG_BUILD}/libfdt/*.h ${SYSROOT_PREFIX}/usr/include
}
