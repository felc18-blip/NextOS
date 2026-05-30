# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="qt6"
# 2026-05-29 NextOS: bump 6.6.1 -> 6.11.0 pra casar com o Qt das AppImages de
# duckstation (stenzek/UnofficialOS, ambas Qt 6.11.0). Em 6.6 o eglfs_kms nao
# dava janela no Amlogic-no (KMSDRM sem compositor); 6.11.0 traz o
# libQt6EglFSDeviceIntegration/eglfs_kms que as AppImages esperam (private API
# Qt_6_11). Mesmas flags de antes (nada removido). Destrava tb a classe Qt (PS2).
PKG_VERSION_MAJOR="6.11"
PKG_VERSION="${PKG_VERSION_MAJOR}.0"
PKG_SHA256="acf3b3db04c9e5d0820e8324b097320388954c297cee83d2bd698789234f68a4"
PKG_LICENSE="GPL"
PKG_SITE="https://download.qt.io"
PKG_URL="${PKG_SITE}/archive/qt/${PKG_VERSION_MAJOR}/${PKG_VERSION}/single/qt-everywhere-src-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain qt6:host openssl libjpeg-turbo libpng pcre2 sqlite zlib freetype SDL2 gstreamer gst-plugins-base gst-plugins-good gst-libav"
PKG_DEPENDS_HOST="gcc:host llvm:host mesa:host"
PKG_LONGDESC="A cross-platform application and UI framework"

# Apply project-specific patches
PKG_PATCH_DIRS="${PROJECT}"

# Set OpenGL or OpenGLES support for CMake
if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_HOST+=" ${OPENGL}"
  PKG_DEPENDS_TARGET+=" ${OPENGL}"
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_opengl=ON -DQT_FEATURE_opengles2=OFF"
elif [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_HOST+=" ${OPENGLES}"
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  # Habilitar AMBOS opengl + opengles2: GLES é runtime no nxtos mas
  # qtdeclarative precisa QOpenGLFramebufferObject header do desktop GL module.
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_opengles2=ON -DQT_FEATURE_opengl=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_opengl=OFF -DQT_FEATURE_opengles2=OFF"
fi

# XCB support for X11
if [ "${DISPLAYSERVER}" = "x11" ]; then
  PKG_DEPENDS_TARGET+=" xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm libxcb-cursor libxkbcommon"
fi

# Wayland support
if [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" wayland xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm libxcb-cursor libxkbcommon"
  PKG_CMAKE_OPTS_TARGET+=" -DBUILD_qtwayland=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DBUILD_qtwayland=OFF"
fi

# Vulkan support
if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_vulkan=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_vulkan=OFF"
fi


pre_configure_host() {
  export LDFLAGS="${LDFLAGS} -lgio-2.0 -lgobject-2.0 -lglib-2.0"
  echo "LDFLAGS are $LDFLAGS"

  unset HOST_CMAKE_OPTS
  PKG_CMAKE_OPTS_HOST+=" -DCMAKE_FIND_PACKAGE_TARGETS_GLOBAL=TRUE"
  PKG_CMAKE_OPTS_HOST+=" -DQT_FEATURE_clangcpp=OFF -DQT_FEATURE_lupdate=OFF"
  # Disable unneeded modules
  # NOTA 2026-05-28: qtmultimedia mantido DISABLE no HOST — host só precisa de
  # ferramentas (moc/uic/syncqt). qtmultimedia HOST quebra em GStreamer SFINAE.
  # No TARGET qtmultimedia é ENABLED (linha 120) — precisa pra melonDS + qbittorrent
  # áudio. Não confundir com Qt do sistema device que vem do TARGET.
  MODULES_TO_DISABLE=("qt3d" "qt5compat" "qtactiveqt" "qtcharts" "qtcoap" "qtconnectivity" "qtdatavis3d"
                      "qtdoc" "qtgraphs" "qtgrpc" "qthttpserver" "qtlocation" "qtlottie" "qtmqtt"
                      "qtmultimedia" "qtnetworkauth" "qtopcua" "qtpositioning" "qtquick3d" "qtquick3dphysics"
                      "qtquickeffectmaker" "qtquicktimeline" "qtremoteobjects" "qtscxml" "qtsensors" "qtserialbus"
                      "qtserialport" "qtspeech" "qttranslations" "qtvirtualkeyboard" "qtwebchannel"
                      "qtwebengine" "qtwebsockets" "qtwebview")
  for module in "${MODULES_TO_DISABLE[@]}"; do
    PKG_CMAKE_OPTS_HOST+=" -DBUILD_${module}=OFF"
  done

  # Enable required modules HOST (sem qtmultimedia — só TARGET precisa)
  # > qtbase qtshadertools qtdeclarative qtsvg qtlanguageserver qttools qtwayland
  MODULES_TO_ENABLE=("qtbase" "qtshadertools" "qtdeclarative" "qtsvg" "qtlanguageserver" "qtimageformats" "qttools" "qtwayland")
  for module in "${MODULES_TO_ENABLE[@]}"; do
    PKG_CMAKE_OPTS_HOST+=" -DBUILD_${module}=ON"
  done

  # Set Host Install path
  PKG_CMAKE_OPTS_HOST+=" -DCMAKE_INSTALL_PREFIX=${TOOLCHAIN}/usr/local/qt6 \
                         -DCMAKE_BUILD_TYPE=Release \
                         -DQT_BUILD_EXAMPLES=OFF \
                         -DQT_BUILD_TESTS=OFF \
                         -DQT_USE_CCACHE=ON \
                         -DQT_GENERATE_SBOM=OFF \
                         -DQT_FEATURE_icu=OFF \
                         -DQT_FEATURE_wayland=ON \
                         -DBUILD_WITH_PCH=OFF"
}

pre_configure_target(){
  unset TARGET_CMAKE_OPTS
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_FIND_PACKAGE_TARGETS_GLOBAL=TRUE"
  PKG_CMAKE_OPTS_TARGET+=" -DFEATURE_ffmpeg=OFF -DQT_FEATURE_ffmpeg=OFF"
  PKG_CMAKE_OPTS_TARGET+=" -DQT_FEATURE_clangcpp=OFF -DQT_FEATURE_lupdate=OFF"

  # Qt 6.8.3 + GLES2-only build quebra em qtdeclarative (qquickopenglutils.cpp
  # + qquickframebufferobject.cpp requerem QOpenGLFramebufferObject que só
  # vem com QT_FEATURE_opengl=ON desktop). Stub no .cpp deixa moc referenciando
  # símbolos undefined no link. Solução: dropar qtdeclarative inteiro do target.
  # Consumers Qt6 no nxtos (moonlight, qtbase suffit) não usam QML em runtime.

  # Disable unneeded modules
  MODULES_TO_DISABLE=("qt3d" "qt5compat" "qtactiveqt" "qtcharts" "qtcoap" "qtconnectivity" "qtdatavis3d"
                      "qtdoc" "qtgraphs" "qtgrpc" "qthttpserver" "qtimageformats"
                      "qtlocation" "qtlottie" "qtmqtt" "qtnetworkauth" "qtopcua" "qtpositioning"
                      "qtquick3d" "qtquick3dphysics" "qtquickeffectmaker" "qtquicktimeline" "qtremoteobjects"
                      "qtscxml" "qtsensors" "qtspeech" "qttranslations" "qtvirtualkeyboard"
                      "qtwebchannel" "qtwebengine" "qtwebview")
  for module in "${MODULES_TO_DISABLE[@]}"; do
    PKG_CMAKE_OPTS_TARGET+=" -DBUILD_${module}=OFF"
  done

  # qtdeclarative RE-HABILITADO: agora QT_FEATURE_opengl=ON também (acima),
  # então QOpenGLFramebufferObject existe e qquickopenglutils compila.
  # Necessário pra layer-shell-qt, qterminal e demais consumers Qml.
  MODULES_TO_ENABLE=("qtbase" "qtmultimedia" "qtshadertools" "qtdeclarative" "qtserialbus"
                     "qtserialport" "qtsvg" "qttools" "qtwebsockets" "qtlanguageserver")
  for module in "${MODULES_TO_ENABLE[@]}"; do
    PKG_CMAKE_OPTS_TARGET+=" -DBUILD_${module}=ON"
  done

  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_INSTALL_PREFIX=/usr \
                           -DCMAKE_SYSROOT=${SYSROOT_PREFIX} \
                           -DCMAKE_TOOLCHAIN_FILE=${CMAKE_CONF} \
                           -DQT_HOST_PATH=${TOOLCHAIN}/usr/local/qt6 \
                           -DCMAKE_BUILD_TYPE=Release \
                           -DQT_DEBUG_FIND_PACKAGE=ON \
                           -DBUILD_SHARED_LIBS=ON \
                           -DQT_BUILD_EXAMPLES=OFF \
                           -DQT_BUILD_TESTS=OFF \
                           -DQT_FEATURE_printer=OFF \
                           -DQT_USE_CCACHE=ON \
                           -DQT_FEATURE_xcb=ON \
                           -DQT_GENERATE_SBOM=OFF \
                           -DBUILD_WITH_PCH=OFF"
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr

  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${INSTALL}/usr/plugins
  mkdir -p ${INSTALL}/usr/qml

  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/qtbase/lib/*.so* ${INSTALL}/usr/lib/
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/qtbase/plugins/* ${INSTALL}/usr/plugins/

  # 2026-05-17 NextOS: plugins ficam em /usr/plugins (não /usr/lib/qt6/plugins
  # padrão). Sem QT_PLUGIN_PATH global, apps Qt6 saem com "no Qt platform
  # plugin". Drop env var em /etc/profile.d/ pra todos shells/launchers.
  mkdir -p ${INSTALL}/etc/profile.d
  cat > ${INSTALL}/etc/profile.d/qt6-plugins.sh <<'EOF'
# NextOS Qt6 plugin path override (qt6 package installs in /usr/plugins).
export QT_PLUGIN_PATH=/usr/plugins
EOF
  # qml dir só existe se qtdeclarative for habilitado (não é o caso no nxtos)
  if [ -d ${PKG_BUILD}/.${TARGET_NAME}/qtbase/qml ] && \
     compgen -G "${PKG_BUILD}/.${TARGET_NAME}/qtbase/qml/*" > /dev/null 2>&1; then
    cp -rf ${PKG_BUILD}/.${TARGET_NAME}/qtbase/qml/* ${INSTALL}/usr/qml/
  fi
}
