# SPDX-License-Identifier: GPL-2.0-or-later
# 2026-05-28 (iter3 X5M Valhall): voltar pro fork felc18-blip/melonDS-nextos.
# Upstream master/1.1 tag tinha regression no JIT aarch64 que CONGELAVA o jogo
# no X5M (200%+ CPU em spinloop). Fork tem GLES 2 path compatível + JIT estável.
# Linkar contra nosso Qt 6.6.1 (que tem qtmultimedia → ÁUDIO funciona).

PKG_NAME="melonds-sa"
PKG_VERSION="0296bed0"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/melonDS-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos"
GET_HANDLER_SUPPORT="git"
PKG_DEPENDS_TARGET="toolchain SDL2 qt6 libarchive libslirp libpcap libzip zstd"
PKG_LONGDESC="Nintendo DS emulator (NextOS fork felc18-blip — JIT estável + GLES 2)"
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

  # Bug em duckstation/gl/context_egl_x11.cpp em aarch64 (1.1 tag): retorna
  # 'false' (bool) onde EGLNativeWindowType (void*) é esperado, e static_cast
  # de Window (unsigned long) pra void* não converte. Fix: trocar false→nullptr
  # e static_cast→reinterpret_cast no único arquivo afetado.
  X11=${PKG_BUILD}/src/frontend/duckstation/gl/context_egl_x11.cpp
  if [ -f "$X11" ]; then
    sed -i 's|return false;|return nullptr;|g' "$X11"
    sed -i 's|static_cast<EGLNativeWindowType>|reinterpret_cast<EGLNativeWindowType>|g' "$X11"
  fi
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
