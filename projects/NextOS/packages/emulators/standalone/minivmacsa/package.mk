# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="minivmacsa"
PKG_VERSION="37.03"
PKG_LICENSE="GPLv2"
PKG_SITE="https://www.gryphel.com/c/minivmac/"
PKG_URL="https://www.gryphel.com/d/minivmac/minivmac-${PKG_VERSION}/minivmac-${PKG_VERSION}.src.tgz"
PKG_DEPENDS_TARGET="toolchain SDL2"
PKG_LONGDESC="Virtual Macintosh Plus"
PKG_TOOLCHAIN="make"

# Amlogic-no roda KMSDRM (sem X11). Mini vMac usa X11 (-t lx64) por padrão, o que
# gera binário linkando -lX11 e quebra (strip: arquitetura irreconhecível). Trocado
# pra API SDL2 (-api sdl2), que roda no KMSDRM. SDL2 cross-compile via sysroot.
pre_make_target() {
  cd ${PKG_BUILD}
  ${TOOLCHAIN}/bin/host-gcc setup/tool.c -o setup_t
  ./setup_t -t lx64 -api sd2 -fullscreen 1 > setup.sh
  . setup.sh
  sed -i "s|gcc|${TARGET_PREFIX}gcc|" ${PKG_BUILD}/Makefile
  # Mini vMac SDL2 Makefile usa sdl2-config do host; forçar flags do sysroot alvo
  sed -i "s|sdl2-config|${SYSROOT_PREFIX}/usr/bin/sdl2-config|g" ${PKG_BUILD}/Makefile 2>/dev/null || true
  # O Makefile chama 'strip' do HOST no binário aarch64 -> "Unable to recognise
  # the architecture". Usar o strip do toolchain alvo.
  sed -i "s|strip --strip-unneeded|${TARGET_PREFIX}strip --strip-unneeded|g" ${PKG_BUILD}/Makefile
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/minivmac ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/*
}
