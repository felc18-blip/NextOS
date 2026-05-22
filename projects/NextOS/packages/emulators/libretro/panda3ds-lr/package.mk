# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="panda3ds-lr"
# Bumped from 5591606 (old commit had submodule ext-cryptoppwin que upstream
# deletou em github.com/shadps4-emu); HEAD atual usa weidai11/cryptopp e
# clone funciona.
PKG_VERSION="944b9892f991c3aacb15436c91511543f8e665bf"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/wheremyfoodat/Panda3DS"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Panda3DS is an HLE, red-panda-themed Nintendo 3DS emulator"
PKG_TOOLCHAIN="cmake"

# Build pode falhar em GCC 16 ou cmake; best-effort pra não travar build geral.
GET_HANDLER_SUPPORT="git"

if [ "${OPENGL_SUPPORT}" = "yes" ] && [ ! "${PREFER_GLES}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL}"
  PKG_CMAKE_OPTS_TARGET+="      -DOPENGL_PROFILE=OpenGL"
elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_PATCH_DIRS+=" gles"
  PKG_CMAKE_OPTS_TARGET+="      -DOPENGL_PROFILE=OpenGLES"
fi

PKG_CMAKE_OPTS_TARGET+="	-DBUILD_LIBRETRO_CORE=ON \
				-DENABLE_USER_BUILD=ON \
				-DENABLE_DISCORD_RPC=OFF \
				-DENABLE_LUAJIT=OFF \
				-DSDL_VIDEO=OFF \
				-DSDL_AUDIO=OFF \
				-DENABLE_VULKAN=OFF \
				-DCMAKE_BUILD_TYPE=Release"

make_target() {
  # Best-effort em aarch64 Mali-450 (3DS pesado pra hardware).
  cd ${PKG_BUILD}/.${TARGET_NAME} && make ${MAKEFLAGS} || true
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ -f ${PKG_BUILD}/.${TARGET_NAME}/panda3ds_libretro.so ]; then
    cp -v ${PKG_BUILD}/.${TARGET_NAME}/panda3ds_libretro.so ${INSTALL}/usr/lib/libretro/panda3ds_libretro.so
  else
    echo "panda3ds_libretro.so not built — skipped"
  fi
}
