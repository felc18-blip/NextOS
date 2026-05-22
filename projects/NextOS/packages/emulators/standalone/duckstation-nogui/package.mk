# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="duckstation-nogui"
PKG_VERSION="edaa0f833beb1a4308dd78466a39744715ffadb1"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/duckstation-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain SDL2 nasm:host ${OPENGLES} libevdev curl wayland wayland-protocols libxkbcommon"
PKG_BUILD_FLAGS="+speed"
PKG_SHORTDESC="Fast PlayStation 1 emulator (NoGUI frontend, KMSDRM)"
PKG_TOOLCHAIN="cmake"

EXTRA_OPTS+=" -DUSE_DRMKMS=ON -DUSE_FBDEV=OFF -DUSE_MALI=OFF -DUSE_WAYLAND=ON -DUSE_EGL=ON"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                           -DANDROID=OFF \
                           -DENABLE_DISCORD_PRESENCE=OFF \
                           -DUSE_X11=OFF \
                           -DBUILD_LIBRETRO_CORE=OFF \
                           -DBUILD_GO2_FRONTEND=OFF \
                           -DBUILD_QT_FRONTEND=OFF \
                           -DBUILD_NOGUI_FRONTEND=ON \
                           -DCMAKE_BUILD_TYPE=Release \
                           -DBUILD_SHARED_LIBS=OFF \
                           -DUSE_SDL2=ON \
                           -DENABLE_CHEEVOS=ON \
                           -DHAVE_EGL=ON \
                           ${EXTRA_OPTS}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/bin/duckstation-nogui ${INSTALL}/usr/bin/

  # Immutable config tree (resources/database/inputprofiles/shaders/settings.ini)
  mkdir -p ${INSTALL}/usr/config/duckstation
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/duckstation/

  # ES Scripts launcher entry — replaces the duckstation-sa (Qt) module
  mkdir -p ${INSTALL}/usr/config/modules
  cp -f ${PKG_DIR}/sources/"Start Duckstation.sh" ${INSTALL}/usr/config/modules/
  chmod 0755 ${INSTALL}/usr/config/modules/"Start Duckstation.sh"
}
