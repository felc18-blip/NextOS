# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 NextOS (https://github.com/felc18-blip)

PKG_NAME="nextos-keyring"
PKG_VERSION="20240419"
PKG_LICENSE="GPL"
PKG_SITE="https://archlinuxarm.org"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain gnupg"
PKG_LONGDESC="NextOS keyring: Arch Linux ARM GPG keys for pacman package verification."
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  # Install Arch Linux ARM keyring for pacman-key --populate
  mkdir -p ${INSTALL}/usr/share/pacman/keyrings
  cp ${PKG_DIR}/keys/archlinuxarm.gpg ${INSTALL}/usr/share/pacman/keyrings/
  cp ${PKG_DIR}/keys/archlinuxarm-trusted ${INSTALL}/usr/share/pacman/keyrings/
  cp ${PKG_DIR}/keys/archlinuxarm-revoked ${INSTALL}/usr/share/pacman/keyrings/
}
