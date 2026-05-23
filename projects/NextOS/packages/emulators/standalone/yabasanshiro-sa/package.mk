# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present 351ELEC
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="yabasanshiro-sa"
PKG_LICENSE="GPLv2"
# Fork felc18-blip/yabasanshiro-1.5-nextos branch nextos-mali450-gles2 (forked
# from sydarn/yabause @ pi4-update) com patch nanogui pra Mali-450 GLES2:
# fallback gracioso quando NanoVG init falha (Mesa Lima nao tem stencil+AA
# que NanoVG quer). Overlay menu desabilita, jogo segue renderizando via
# VIDCore (Saturn VDP1/VDP2).
PKG_SITE="https://github.com/felc18-blip/yabasanshiro-1.5-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="ee2ba850a827e0c19a90b8c3f14a5d0b205cb8da"
PKG_GIT_CLONE_BRANCH="nextos-mali450-gles2"
PKG_ARCH="aarch64"
PKG_DEPENDS_TARGET="toolchain SDL2 boost openal-soft zlib"
PKG_LONGDESC="Yabause is a Sega Saturn emulator and took over as Yaba Sanshiro"
PKG_TOOLCHAIN="cmake-make"
GET_HANDLER_SUPPORT="git"
PKG_BUILD_FLAGS="+speed"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]
then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
fi

post_unpack() {
  # use host versions
  sed -i "s|COMMAND m68kmake|COMMAND ${PKG_BUILD}/m68kmake_host|" ${PKG_BUILD}/yabause/src/musashi/CMakeLists.txt
  sed -i "s|COMMAND ./bin2c|COMMAND ${PKG_BUILD}/bin2c_host|" ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/CMakeLists.txt
  find ${PKG_BUILD} -type f -name "CMakeLists.txt" -exec sed -i 's/^\s*cmake_minimum_required.*$/cmake_minimum_required(VERSION 3.5)/' {} +
}

pre_make_target() {
  # runs on host so make them manually if package is not crosscompile friendly
  ${HOST_CC} ${PKG_BUILD}/yabause/src/retro_arena/nanogui-sdl/resources/bin2c.c -o ${PKG_BUILD}/bin2c_host
  ${HOST_CC} ${PKG_BUILD}/yabause/src/musashi/m68kmake.c -o ${PKG_BUILD}/m68kmake_host
}

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="${PKG_BUILD}/yabause "

  if [ ! "${OPENGL}" = "no" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_EGL=ON -DUSE_OPENGL=ON"
  fi

  if [ "${OPENGLES_SUPPORT}" = yes ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DUSE_EGL=ON -DUSE_OPENGL=OFF"
  fi

  case ${ARCH} in
    aarch64)
      PKG_CMAKE_OPTS_TARGET+=" -DYAB_WANT_ARM7=ON \
                               -DYAB_WANT_DYNAREC_DEVMIYAX=ON \
                               -DYAB_PORTS=retro_arena"

      PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_PROJECT_INCLUDE=${PKG_BUILD}/yabause/src/retro_arena/n2.cmake"
    ;;
  esac

  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_SYSTEM_PROCESSOR=x86_64"

  PKG_CMAKE_OPTS_TARGET+=" -DOPENGL_INCLUDE_DIR=${SYSROOT_PREFIX}/usr/include \
                           -DOPENGL_opengl_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
                           -DOPENGL_glx_LIBRARY=${SYSROOT_PREFIX}/usr/lib \
                           -DLIBPNG_LIB_DIR=${SYSROOT_PREFIX}/usr/lib \
                           -Dpng_STATIC_LIBRARIES=${SYSROOT_PREFIX}/usr/lib/libpng16.so \
                           -DCMAKE_BUILD_TYPE=Release \
                           -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"

  # NextOS Amlogic-nxtos: Mali-450 Utgard via Mesa Lima is GLES2-only — no
  # GLES3 / no texelFetch / no VAO / no compute. VIDOGL renderer hard-codes
  # GLSL ES 3.00. MALI_GLES2_ONLY flag in our fork routes init to VIDSoft
  # (CPU render) + patches the SetupGL display blit shader down to GLSL ES
  # 1.00 + skips VAO setup. Picks up via the fork's nextos-mali450-gles2
  # branch (see PKG_VERSION above).
  if [ "${DEVICE}" = "Amlogic-nxtos" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_C_FLAGS=-DMALI_GLES2_ONLY=1 \
                             -DCMAKE_CXX_FLAGS=-DMALI_GLES2_ONLY=1"
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -a ${PKG_BUILD}/src/retro_arena/yabasanshiro ${INSTALL}/usr/bin/yabasanshiro
  cp -a ${PKG_DIR}/scripts/start_yabasanshiro.sh ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/start_yabasanshiro.sh
  mkdir -p ${INSTALL}/usr/config/yabasanshiro
  cp ${PKG_DIR}/config/config ${INSTALL}/usr/config/yabasanshiro/.config
  cp -r ${PKG_DIR}/config/devices ${INSTALL}/usr/config/yabasanshiro/
}
