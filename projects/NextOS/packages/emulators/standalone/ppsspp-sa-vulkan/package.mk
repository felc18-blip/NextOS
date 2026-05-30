# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="ppsspp-sa-vulkan"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="afbc66a318b86432642b532c575241f3716642ef" # v1.20.2
CHEAT_DB_VERSION="7c9fe1ae71155626cea767aed53f968de9f4051f" # Update cheat.db (17/01/2026)
PKG_LICENSE="GPLv2"
# NextOS Amlogic-no Vulkan variant: forces the Vulkan backend and presents via a direct
# DRM/KMS + GBM-import bridge (the Mali Valhall blob's Vulkan WSI swapchain is a stub).
# Coexists with the GLES ppsspp-sa - installs as /usr/bin/ppsspp-vulkan.
PKG_DEPENDS_TARGET="toolchain libzip SDL2 zlib zip libdrm mesa"
PKG_LONGDESC="PPSSPP Vulkan (NextOS Amlogic-no DRM/KMS present)"
GET_HANDLER_SUPPORT="git"

### Note:
### This package includes the NotoSansJP-Regular.ttf font.  This font is licensed under
### SIL Open Font License, Version 1.1.  The license can be found in the licenses
### directory in the root of this project, OFL.txt.
###

PKG_PATCH_DIRS+="${DEVICE}"

PKG_CMAKE_OPTS_TARGET=" -DUSE_SYSTEM_FFMPEG=OFF \
                        -DCMAKE_BUILD_TYPE=Release \
                        -DCMAKE_SYSTEM_NAME=Linux \
                        -DBUILD_SHARED_LIBS=OFF \
                        -DUSE_SYSTEM_LIBPNG=OFF \
                        -DANDROID=OFF \
                        -DWIN32=OFF \
                        -DAPPLE=OFF \
                        -DCMAKE_CROSSCOMPILING=ON \
                        -DUSING_QT_UI=OFF \
                        -DUNITTEST=OFF \
                        -DSIMULATOR=OFF \
                        -DHEADLESS=OFF \
                        -DUSE_DISCORD=OFF"

# NextOS Amlogic-no: ALWAYS Vulkan + direct DRM/KMS present bridge (no GLES, no WSI surface).
PKG_CMAKE_OPTS_TARGET+=" -DVULKAN=ON \
                         -DUSE_VULKAN_DISPLAY_KHR=ON \
                         -DNEXTOS_DRM_PRESENT=ON \
                         -DUSING_GLES2=OFF \
                         -DUSING_FBDEV=OFF \
                         -DUSING_EGL=OFF \
                         -DUSING_X11_VULKAN=OFF \
                         -DUSE_WAYLAND_WSI=OFF \
                         -DEGL_NO_X11=1 \
                         -DMESA_EGL_NO_X11_HEADERS=1"
GRENDERER="3 (VULKAN)"

pre_configure_target() {
  sed -i 's/\-O[23]//g' ${PKG_BUILD}/CMakeLists.txt
  sed -i "s|include_directories(/usr/include/drm)|include_directories(${SYSROOT_PREFIX}/usr/include/drm)|" ${PKG_BUILD}/CMakeLists.txt
}

pre_make_target() {
  export CPPFLAGS="${CPPFLAGS} -Wno-error"
  export CFLAGS="${CFLAGS} -Wno-error"

  # fix cross compiling
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  # NextOS Vulkan variant: binario ppsspp-vulkan + launch script proprio (start_ppssppvulkan.sh,
  # chamado pelo runemu via ${CORE%-*} com CORE=ppssppvulkan). Reusa a config/assets do ppsspp-sa GLES.
  mkdir -p ${INSTALL}/usr/bin
  cp PPSSPPSDL ${INSTALL}/usr/bin/ppsspp-vulkan
  cp ${PKG_DIR}/scripts/start_ppssppvulkan.sh ${INSTALL}/usr/bin/start_ppssppvulkan.sh
  chmod 0755 ${INSTALL}/usr/bin/ppsspp-vulkan ${INSTALL}/usr/bin/start_ppssppvulkan.sh
}

post_install() {
  :
}
