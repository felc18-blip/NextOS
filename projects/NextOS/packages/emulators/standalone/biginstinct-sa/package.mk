# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS

PKG_NAME="biginstinct-sa"
PKG_VERSION="v101"
PKG_ARCH="any"
PKG_LICENSE="Proprietary"
PKG_SITE="https://www.richwhitehouse.com/ki/"
PKG_DEPENDS_TARGET="toolchain SDL2 nextos-hotkey"
PKG_LONGDESC="BigInstinct - Killer Instinct 1/2 arcade emulator (Rich Whitehouse)."
PKG_TOOLCHAIN="manual"

case ${TARGET_ARCH} in
  x86_64)
    PKG_URL="${PKG_SITE}/builds/BigInstinct_Linux64_${PKG_VERSION}.tar.gz"
    PKG_SOURCE_NAME="biginstinct-x86_64-${PKG_VERSION}.tar.gz"
  ;;
  aarch64)
    PKG_URL="${PKG_SITE}/builds/BigInstinct_LinuxARM64_${PKG_VERSION}.tar.gz"
    PKG_SOURCE_NAME="biginstinct-aarch64-${PKG_VERSION}.tar.gz"
  ;;
esac

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin/biginstinct
  cp -rf ${PKG_BUILD}/* ${INSTALL}/usr/bin/biginstinct/

  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 755 ${INSTALL}/usr/bin/start_biginstinct.sh

  # Per-device userdata (AutoAssign=1 default — mesmo padrao bigpemu-sa)
  if [ -d "${PKG_DIR}/config/${DEVICE}" ]; then
    mkdir -p ${INSTALL}/usr/config/biginstinct/userdata
    cp -rf ${PKG_DIR}/config/${DEVICE}/BigInstinctConfig.bigpcfg* ${INSTALL}/usr/config/biginstinct/userdata/
  fi

  # Amlogic-nxtos: symlink gamecontrollerdb pro path que biginstinct procura.
  # Sem isso (mesma codebase bigpemu) controle "aparece mas nao funciona" pq
  # SDL_GameController nao acha mapping pro USB Gamepad.
  if [ "${DEVICE}" = "Amlogic-nxtos" ]; then
    ln -sf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt ${INSTALL}/usr/bin/biginstinct/gamecontrollerdb.txt
  fi
}
