# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023-present JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="bdf2psf"
PKG_VERSION="1.248"
PKG_SHA256="e753c4f68d6498849dfe46072e6f0d5010ca8b67b25c990bd0c916969d5ff1ca"
PKG_LICENSE="GPLv2"
PKG_SITE="https://packages.debian.org/unstable/${PKG_NAME}"
PKG_URL="https://deb.debian.org/debian/pool/main/c/console-setup/${PKG_NAME}_${PKG_VERSION}_all.deb"
PKG_DEPENDS_HOST=""
PKG_LONGDESC="Utility to convert BDF font files to PSF format"
PKG_TOOLCHAIN="manual"

unpack() {
 mkdir -p ${PKG_BUILD}
 cd ${PKG_BUILD}
 ar x ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.deb
 tar -xf data.tar.xz
}

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/usr/{bin,share}
  cp ${PKG_BUILD}/usr/bin/${PKG_NAME} ${TOOLCHAIN}/usr/bin
  cp -rf ${PKG_BUILD}/usr/share/* ${TOOLCHAIN}/usr/share
  chmod 0755 ${TOOLCHAIN}/usr/bin/${PKG_NAME}
}
