# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="socat"
PKG_VERSION="1.8.1.1"
PKG_SHA256="f68b602c80e94b4b7498d74ec408785536fe33534b39467977a82ab2f7f01ddb"
PKG_LICENSE="GPLv2+"
PKG_SITE="http://www.dest-unreach.org/socat/download"
PKG_URL="${PKG_SITE}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A multipurpose relay (SOcket CAT)"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET+="	--disable-libwrap \
				--disable-readline \
				--enable-termios"

pre_makeinstall_target() {
  # socat 1.8.x procura scripts auxiliares em CWD durante install
  cp -f ${PKG_BUILD}/socat-chain.sh . 2>/dev/null || true
  cp -f ${PKG_BUILD}/socat-mux.sh . 2>/dev/null || true
  cp -f ${PKG_BUILD}/socat-broker.sh . 2>/dev/null || true
}

