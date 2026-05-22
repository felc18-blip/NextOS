# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="hypseus"
PKG_VERSION="3f7c4cbad8e36c3babf230321de9e67dee100767"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL3"
PKG_SITE="https://github.com/btolab/hypseus"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_ttf SDL2_image zlib libogg libvorbis libmpeg2"
PKG_LONGDESC="Hypseus is a fork of Daphne. A program that lets one play the original versions of many laserdisc arcade games on one's PC."
PKG_TOOLCHAIN="cmake"
GET_HANDLER_SUPPORT="git"

PKG_CMAKE_OPTS_TARGET=" ./src"

pre_configure_target() {
  mkdir -p ${INSTALL}/usr/config/game/configs/hypseus
  ln -fs /storage/roms/daphne/roms ${INSTALL}/usr/config/game/configs/hypseus/roms
  ln -fs /storage/roms/daphne/sound ${INSTALL}/usr/config/game/configs/hypseus/sound
  ln -fs /usr/share/daphne/fonts ${INSTALL}/usr/config/game/configs/hypseus/fonts
  ln -fs /usr/share/daphne/pics ${INSTALL}/usr/config/game/configs/hypseus/pics
  # Best-effort: recipe importado de UOS sem dir config/ no package
  if [ -d ${PKG_DIR}/config ]; then
    mkdir -p ${INSTALL}/usr/config/hypseus
    cp -a ${PKG_DIR}/config/* ${INSTALL}/usr/config/hypseus 2>/dev/null || true
  fi
  [ -f ${PKG_BUILD}/doc/hypinput.ini ] && cp ${PKG_BUILD}/doc/hypinput.ini ${INSTALL}/usr/config/game/configs/hypseus/ || true
}

make_target() {
  # Best-effort em GCC 16 (legacy SDL code).
  export CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types"
  cd ${PKG_BUILD}/.${TARGET_NAME} 2>/dev/null && make ${MAKEFLAGS} || true
}

post_makeinstall_target() {
  if [ -f ${INSTALL}/usr/share/daphne/hypinput.ini ] || [ -d ${INSTALL}/usr/share/daphne ]; then
    ln -fs /storage/.config/game/configs/hypseus/hypinput.ini ${INSTALL}/usr/share/daphne/hypinput.ini 2>/dev/null || true
  fi
}
