# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2014 Stephan Raue (stephan@openelec.tv)

PKG_NAME="libmad"
PKG_VERSION="be34ec9fe47577e7f3d84cc9640d2a4696d478d6"
PKG_SHA256="478d2e3ef4307b0731cc43eca917eba9689285e693a84381d83d0ef81177f05a"
PKG_LICENSE="GPL"
PKG_SITE="http://www.mars.org/home/rob/proj/mpeg/"
PKG_URL="${SOURCEFORGE_SRC}/mad/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A high-quality MPEG audio decoder."
PKG_TOOLCHAIN="autotools"

# package specific configure options
PKG_CONFIGURE_OPTS_TARGET="--enable-static --disable-shared"
if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_CONFIGURE_OPTS_TARGET+=" --enable-accuracy --enable-fpm=64bit"
fi

post_makeinstall_target() {
  mkdir -p ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  cat >${SYSROOT_PREFIX}/usr/lib/pkgconfig/mad.pc  <<"EOF"
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: mad
Description: MPEG audio decoder
Requires:
Version: 0.15.1b
Libs: -L${libdir} -lmad
Cflags: -I${includedir}
EOF
}
