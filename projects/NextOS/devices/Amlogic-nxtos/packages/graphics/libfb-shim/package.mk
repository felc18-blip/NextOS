# SPDX-License-Identifier: GPL-2.0-or-later
# LD_PRELOAD shim per-device Amlogic-nxtos: intercepta
# glFramebufferRenderbuffer(GL_DEPTH_STENCIL_ATTACHMENT) (GLES3+) e splita
# em DEPTH + STENCIL separados (GLES2 Lima Mali-450 aceita).
# Necessario pra flycast/flycast2021 (64-bit) e morpheuscast_xtreme_32b
# (32-bit) que GL_INVALID_ENUM-crasham sem isso.

PKG_NAME="libfb-shim"
PKG_VERSION="1.0"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Mali-450 LD_PRELOAD shim: split GL_DEPTH_STENCIL_ATTACHMENT into 2 calls"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
  cp ${PKG_DIR}/sources/libfb-shim.c ${PKG_BUILD}/
}

make_target() {
  ${TARGET_PREFIX}gcc -shared -fPIC -O2 -o libfb-shim.so libfb-shim.c -ldl
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  cp libfb-shim.so ${INSTALL}/usr/lib/libfb-shim.so
}
