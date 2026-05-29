# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present kkoshelev (https://github.com/kkoshelev)
# Copyright (C) 2022-present fewtarius (https://github.com/fewtarius)

PKG_NAME="tailscale"
PKG_VERSION="1.98.3"
PKG_SITE="https://tailscale.com/"
PKG_DEPENDS_TARGET="toolchain wireguard-tools"
PKG_LONGDESC="Zero config VPN. Installs on any device in minutes, manages firewall rules for you, and works from anywhere."
PKG_TOOLCHAIN="manual"

case ${TARGET_ARCH} in
  aarch64)
    TS_ARCH="_arm64"
    # 2026-05-28 SHA atualizado pra 1.98.3 conforme CoreELEC coreelec-22
    PKG_SHA256="d26ce4a1a259621fc76d16c7baf3f3a4252f356dfa9d9769484782f766ca1b7f"
  ;;
  x86_64)
    TS_ARCH="_amd64"
    PKG_SHA256="a53002b0052317179d3fcace99dcd94c87b634dbb453da06b7374a4420c8160a"
  ;;
esac

PKG_URL="https://pkgs.tailscale.com/stable/tailscale_${PKG_VERSION}${TS_ARCH}.tgz"

pre_unpack() {
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf $SOURCES/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tgz -C ${PKG_BUILD} tailscale_${PKG_VERSION}${TS_ARCH}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/sbin/
    cp ${PKG_BUILD}/tailscale ${INSTALL}/usr/sbin/
    cp ${PKG_BUILD}/tailscaled ${INSTALL}/usr/sbin/

  mkdir -p ${INSTALL}/usr/config
    cp -R ${PKG_DIR}/config/tailscaled.defaults ${INSTALL}/usr/config
}

