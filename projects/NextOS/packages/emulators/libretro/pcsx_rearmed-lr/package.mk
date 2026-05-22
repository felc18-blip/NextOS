# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020 Trond Haugland (trondah@gmail.com)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="pcsx_rearmed-lr"
PKG_VERSION="228c14e10e9a8fae0ead8adf30daad2cdd8655b9"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/pcsx_rearmed"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ARM optimized PCSX fork"
PKG_TOOLCHAIN="manual"

pre_configure_target() {
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/Makefile
  export CFLAGS="${CFLAGS} -flto -fipa-pta"
  export CXXFLAGS="${CXXFLAGS} -flto -fipa-pta"
  export LDFLAGS="${LDFLAGS} -flto -fipa-pta"
}

make_target() {
  cd ${PKG_BUILD}
  make -f Makefile.libretro GIT_VERSION=${PKG_VERSION} platform=${DEVICE}
}

makeinstall_target32() {
  case ${ARCH} in
    aarch64)
      if [ "${ENABLE_32BIT}" == "true" ]
      then
        # Skip se 32-bit build não compilou esse package (e.g. Amlogic-nxtos
        # ARM pass não inclui pcsx_rearmed). Não falhar build inteira.
        local SRC=$(ls ${ROOT}/build.${DISTRO}-${DEVICE}.arm/install_pkg/${PKG_NAME}-*/usr/lib/libretro/${1}_libretro.so 2>/dev/null | head -1)
        if [ -n "${SRC}" ]; then
          cp -vP "${SRC}" ${INSTALL}/usr/lib/libretro/${1}32_libretro.so
        else
          echo "WARN: ${PKG_NAME} 32-bit não disponível em ${DEVICE}.arm — skip"
        fi
      fi
    ;;
  esac
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp pcsx_rearmed_libretro.so ${INSTALL}/usr/lib/libretro/
  case ${TARGET_ARCH} in
    aarch64)
      makeinstall_target32 pcsx_rearmed
    ;;
  esac
}
