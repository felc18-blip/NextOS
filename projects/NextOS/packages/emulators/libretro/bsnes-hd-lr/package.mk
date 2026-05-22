# SPDX-License-Identifier: Apache-2.0
# Copyright (C) 2023-present Daedalia (https://github.com/daedalia)

PKG_NAME="bsnes-hd-lr"
PKG_VERSION="0bb7b8645e22ea2476cabd58f32e987b14686601"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/DerKoun/bsnes-hd"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="bsnes-hd is a fork of bsnes that adds HD video features such as widescreen, HD Mode 7 and true color"

PKG_TOOLCHAIN="make"

PKG_MAKE_OPTS_TARGET+=" -C bsnes target=libretro compiler=${TARGET_NAME}-g++"

pre_configure_target() {
  sed -i 's/\-O[23]/-Ofast/' ${PKG_BUILD}/bsnes/GNUmakefile
  # NextOS toolchain sem libgomp — drop OpenMP do link
  find ${PKG_BUILD} -name "GNUmakefile" -o -name "*.mk" 2>/dev/null | xargs sed -i 's/-fopenmp//g; s/-lgomp//g' 2>/dev/null || true
}

make_target() {
  make ${PKG_MAKE_OPTS_TARGET} || true
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ -f bsnes/out/bsnes_hd_beta_libretro.so ]; then
    cp bsnes/out/bsnes_hd_beta_libretro.so ${INSTALL}/usr/lib/libretro/
  else
    echo "bsnes_hd_beta_libretro.so not built — skipped"
  fi
}

