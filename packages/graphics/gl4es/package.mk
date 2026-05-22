# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2026-present NextOS Arch-R
#
# gl4es: OpenGL 2.1/1.5 → GLES 2.0/1.1 translation library. Required for ports
# and emulators that link against libGL (desktop) since Mali-450 (Utgard) is
# GLES2-only and Mesa lima doesn't provide libGL.so.
#
# Path isolation strategy (no conflict with Mesa lima):
#   /usr/lib/gl4es/libGL.so.1       — gl4es real
#   /usr/lib/libEGL_gl4es.so.1      — alternative EGL wrapper (opt-in LD_PRELOAD)
# Apps that need it use LD_LIBRARY_PATH=/usr/lib/gl4es or per-binary wrapper.
# Default system continues using Mesa lima (libGLESv2 nativo via libEGL.so.1).

PKG_NAME="gl4es"
PKG_VERSION="9e8037b0c344127993e7d66a17ff42228b0bb806"
PKG_SHA256="d118b691929dac75cdffb1f57e938944c9c419c5f75ecae2ec8b57e82673f04f"
PKG_GIT_CLONE_BRANCH="master"
PKG_SITE="https://github.com/ptitSeb/gl4es"
PKG_LICENSE="GPL"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_LONGDESC="gl4es: OpenGL 2.1/1.5 to GLES 2.0/1.1 translation (Mali-450 GLES2-only hw)"
PKG_TOOLCHAIN="cmake-make"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DNOX11=1 -DODROID=1 -DGBM=OFF -DEGL_WRAPPER=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
}

makeinstall_target() {
  # Isolated path — apps opt-in via LD_LIBRARY_PATH=/usr/lib/gl4es
  mkdir -p ${INSTALL}/usr/lib/gl4es
  cp ${PKG_BUILD}/lib/libGL.so.1 ${INSTALL}/usr/lib/gl4es/libGL.so.1
  ln -sf libGL.so.1 ${INSTALL}/usr/lib/gl4es/libGL.so

  # Alternative EGL wrapper for ports that need fixed-pipeline emulation. Not
  # in the default lib search path; LD_PRELOAD opt-in only.
  if [ -f ${PKG_BUILD}/lib/libEGL.so.1 ]; then
    cp ${PKG_BUILD}/lib/libEGL.so.1 ${INSTALL}/usr/lib/libEGL_gl4es.so.1
  fi
}
