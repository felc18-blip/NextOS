# SPDX-License-Identifier: GPL-2.0-or-later
# 2026-05-17 NextOS Amlogic-nxtos: usar fork felc18-blip/melonDS-nextos (Qt5
# patches Mali-450) com Qt6 do NextOS. Fork força ScreenPanelNative + Software
# 3D, evita GL #version 140 shaders e GPU3D OpenGL renderer (Mali-450 sem
# OpenGL 3.x desktop).

PKG_NAME="melonds-sa"
PKG_VERSION="0296bed0"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/melonDS-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain SDL2 qt6 libarchive libslirp libpcap libzip zstd"
PKG_LONGDESC="Nintendo DS emulator (NextOS fork, Qt6, Mali-450 software 3D)"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="+speed"

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                           -DBUILD_QT_SDL=ON \
                           -DUSE_QT6=ON \
                           -DUSE_SYSTEM_LIBSLIRP=ON \
                           -DENABLE_JIT=ON \
                           -DENABLE_JIT_PROFILING=OFF"
  # Qt6 6.11 requer GuiPrivate component pra qpa/* private headers
  sed -i 's|find_package(Qt6 COMPONENTS Core Gui Widgets Network Multimedia OpenGL OpenGLWidgets REQUIRED)|find_package(Qt6 COMPONENTS Core Gui GuiPrivate Widgets Network Multimedia OpenGL OpenGLWidgets REQUIRED)|' \
    ${PKG_BUILD}/src/frontend/qt_sdl/CMakeLists.txt
  sed -i 's|set(QT_LINK_LIBS Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Network Qt6::Multimedia Qt6::OpenGL Qt6::OpenGLWidgets)|set(QT_LINK_LIBS Qt6::Core Qt6::Gui Qt6::GuiPrivate Qt6::Widgets Qt6::Network Qt6::Multimedia Qt6::OpenGL Qt6::OpenGLWidgets)|' \
    ${PKG_BUILD}/src/frontend/qt_sdl/CMakeLists.txt
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/melonDS ${INSTALL}/usr/bin/melonDS

  mkdir -p ${INSTALL}/usr/config/melonDS
  [ -d ${PKG_DIR}/config/${DEVICE} ] && cp -rf ${PKG_DIR}/config/${DEVICE}/* ${INSTALL}/usr/config/melonDS 2>/dev/null || true
  [ -f ${PKG_DIR}/config/melonDS.gptk ] && cp -rf ${PKG_DIR}/config/melonDS.gptk ${INSTALL}/usr/config/melonDS 2>/dev/null || true

  [ -d ${PKG_DIR}/scripts ] && cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin/ 2>/dev/null || true
  chmod +x ${INSTALL}/usr/bin/* 2>/dev/null || true
}
