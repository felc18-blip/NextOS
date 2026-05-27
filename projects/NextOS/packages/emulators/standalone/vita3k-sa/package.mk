# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="vita3k-sa"
PKG_VERSION="f02851437d8bce2ebf54cd6d4922cd4b0faba654"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/Vita3K/Vita3K"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_image zlib libogg libvorbis gtk3 openssl ffmpeg"
PKG_LONGDESC="vita3k"
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS+="${DEVICE}"

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

 pre_configure_target() {
  mkdir -p ${PKG_BUILD}/external
  # O submodule external/sdl pinava o commit f9593a17 que o Vita3K/sdl removeu
  # (force-push) -> get pula ele (vazio). Mas o check_submodules_present do
  # CMake exige external/sdl nao-vazio. Clona o HEAD atual do Vita3K/sdl.
  rm -rf ${PKG_BUILD}/external/sdl
  cd ${PKG_BUILD}/external && git clone --depth 1 https://github.com/Vita3K/sdl.git sdl
  rm -rf ${PKG_BUILD}/external/nativefiledialog-cmake
  cd ${PKG_BUILD}/external && git clone https://github.com/Vita3K/nativefiledialog-cmake
  rm -rf ${PKG_BUILD}/external/ffmpeg
  cd ${PKG_BUILD}/external && git clone https://github.com/Vita3K/ffmpeg-core.git ffmpeg
  # O HEAD do ffmpeg-core nao tem release/prebuilt (o CMake baixa prebuilt por
  # commit-SHA). Checkout numa tag COM prebuilt arm64 valido (e30b7d7).
  ( cd ${PKG_BUILD}/external/ffmpeg && git checkout e30b7d7 )
  # O file(DOWNLOAD) do CMake falha no configure (o libcurl embutido do CMake
  # nao valida o redirect TLS do github -> release-assets.githubusercontent.com,
  # STATUS!=0). Pre-baixamos o zip com o curl do sistema pro local exato que o
  # CMakeLists espera: ${CMAKE_BINARY_DIR}/external/ffmpeg.zip. O vita3k re-roota
  # o binary dir pra ${PKG_BUILD}/external (CMakeCache fica la), entao o alvo e
  # ${PKG_BUILD}/external/external/ffmpeg.zip -> o if(NOT EXISTS) pula o download.
  mkdir -p ${PKG_BUILD}/external/external
  curl -fsSL -o ${PKG_BUILD}/external/external/ffmpeg.zip \
    "https://github.com/Vita3K/ffmpeg-core/releases/download/e30b7d7/ffmpeg-linux-arm64.zip"

  # A base do vita3k (e varios submodules: yaml-cpp, mem/atomic.h, etc.) usa
  # uint16_t/uint32_t assumindo include transitivo de <cstdint>, que o GCC novo
  # nao fornece mais -> erro 'uint16_t was not declared' espalhado por dezenas
  # de arquivos. Fix global: force-include cstdint em todo C++ (e stdint.h no C)
  # via flag do compilador, resolvendo todos de uma vez.
  export CXXFLAGS="${CXXFLAGS} -include cstdint"
  export CFLAGS="${CFLAGS} -include stdint.h"

  case ${TARGET_ARCH} in
    aarch64)
      CMAKE_EXTRA_OPTS="-DXXHASH_BUILD_XXHSUM=ON \
                        -DXXH_X86DISPATCH_ALLOW_AVX=OFF"
    ;;
    *)
      CMAKE_EXTRA_OPTS="-DXXH_X86DISPATCH_ALLOW_AVX=ON"
    ;;
  esac

  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                  -DBUILD_SHARED_LIBS=OFF \
                  -DUSE_DISCORD_RICH_PRESENCE=OFF \
                  -DUSE_VITA3K_UPDATE=OFF \
                  ${CMAKE_EXTRA_OPTS}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/config/vita3k
  cp -rf ${PKG_BUILD}/external/bin/Vita3K ${INSTALL}/usr/bin/
  cp -rf ${PKG_BUILD}/external/bin/* ${INSTALL}/usr/config/vita3k/
  rm -rf ${INSTALL}/usr/config/vita3k/Vita3K
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/*

  mkdir -p ${INSTALL}/usr/config/vita3k/launcher
  cp ${PKG_DIR}/scripts/start_vita3k.sh ${INSTALL}/usr/config/vita3k/launcher/_Start\ Vita3K.sh
  cp ${PKG_DIR}/scripts/scan_vita3k.sh ${INSTALL}/usr/config/vita3k/launcher/_Scan\ Vita\ Games.sh
  chmod 0755 ${INSTALL}/usr/config/vita3k/launcher/*sh

  cp ${PKG_DIR}/sources/vita-gamelist.txt ${INSTALL}/usr/config/vita3k
}
