# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="melonds-ds-lr"
PKG_VERSION="86986bfd82fb130d4d4739d93159acd986921808"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/JesseTG/melonds-ds"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="An enhanced remake of the melonDS core for libretro that prioritizes standalone parity, reliability, and usability."
PKG_TOOLCHAIN="cmake-make"

# 2026-05-28 Amlogic-no X5M (Mali Valhall G310 blob r44p0): blob só tem GLES,
# não tem libOpenGL.so.0 desktop. ENABLE_OPENGL=ON forçava find_package(OpenGL)
# -> core linkava libOpenGL/libGLdispatch -> dlopen failed silencioso no X5M.
# Fix opção A: ENABLE_OPENGL=OFF (software render, sem upscale GL).
PKG_CMAKE_OPTS_TARGET=" -DENABLE_OPENGL=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_C_FLAGS=-fno-lto -DCMAKE_CXX_FLAGS=-fno-lto -DCMAKE_EXE_LINKER_FLAGS=-fno-lto -DCMAKE_SHARED_LINKER_FLAGS=-fno-lto"

if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL}"
  PKG_CMAKE_OPTS_TARGET+=" -DDEFAULT_OPENGL_PROFILE=OpenGL"
elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_CMAKE_OPTS_TARGET+=" -DDEFAULT_OPENGL_PROFILE=OpenGLES2"
fi

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/src/libretro/melondsds_libretro.so ${INSTALL}/usr/lib/libretro/
}
