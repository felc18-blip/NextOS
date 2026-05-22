# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mame2003-xtreme-lr"
PKG_VERSION="47deb07f49224ec5b0bbc56392b639d728183629"
PKG_SHA256="185b7e857e836b3987737ff9077d0709444491a0f138cfbbe1f50a6ad5d719b7"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/KMFDManic/mame2003-xtreme"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Updated 2018 version of MAME (0.78) for libretro, with added game support, and optimized for performance and speed on the Mini Classics. "
PKG_TOOLCHAIN="make"

pre_configure_target() {
  cd ${PKG_BUILD}
  export SYSROOT_PREFIX=${SYSROOT_PREFIX}

  case ${PROJECT} in
    Amlogic-ng)
        PKG_MAKE_OPTS_TARGET+=" platform=AMLG12B"
      ;;
    Amlogic)
        PKG_MAKE_OPTS_TARGET+=" platform=AMLGX"
      ;;
  esac
  PKG_MAKE_OPTS_TARGET+=" ARCH=\"\" CC=\"${CC}\" NATIVE_CC=\"${CC}\" LD=\"${CC}\""

  # GCC 15: legacy C source (mame2003-xtreme upstream pré-2020) usa
  # implicit declarations + incompatible pointer types em libretro.c.
  # Downgrade pra warning pra compilar e gerar .so (mesmo que core pode
  # ter bug em runtime). Felipe pediu "adicionar mesmo que não funcione".
  export CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion"
 }

make_target() {
  # Best-effort em GCC 16 — legacy source 2018 quebra com warnings-as-errors.
  make ${PKG_MAKE_OPTS_TARGET} || true
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ -f mame2003_libretro.so ]; then
    cp mame2003_libretro.so ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.so
    [ -f km_mame2003_xtreme_libretro.info ] && cp km_mame2003_xtreme_libretro.info ${INSTALL}/usr/lib/libretro/km_mame2003_xtreme_libretro.info
  else
    echo "mame2003_xtreme not built — skipped"
  fi
}
