# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="tsdecrypt"
PKG_VERSION="f4876e84cf1866645f84b93f830af67193c85f69"
PKG_SHA256="084704d2b121f0fbbe5e5960bb50fbc11695b1cfcd65ebab24b1bf58cfebb38f"
PKG_LICENSE="GPL"
PKG_SITE="http://georgi.unixsol.org/programs/tsdecrypt"
PKG_URL="http://georgi.unixsol.org/programs/tsdecrypt/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libdvbcsa openssl"
PKG_LONGDESC="A tool that reads incoming mpeg transport stream over UDP/RTP and then decrypts it using libdvbcsa/ffdecsa."
PKG_BUILD_FLAGS="-sysroot"

PKG_MAKEINSTALL_OPTS_TARGET="PREFIX=/usr"

make_target() {
  make CC=${CC} LINK="${LD} -o"
}

post_make_target() {
  make strip STRIP=${STRIP}
}
