# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 NextOS — alinhado com CoreELEC coreelec-22 + hack defensivo C++17 host

PKG_NAME="icu"
PKG_VERSION="78.3"
PKG_SHA256="3a2e7a47604ba702f345878308e6fefeca612ee895cf4a5f222e7955fabfe0c0"
PKG_LICENSE="Unicode-3.0"
PKG_SITE="https://icu.unicode.org"
PKG_URL="https://github.com/unicode-org/icu/releases/download/release-${PKG_VERSION}/icu4c-${PKG_VERSION}-sources.tgz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain icu:host"
PKG_LONGDESC="International Components for Unicode library."
PKG_TOOLCHAIN="configure"

PKG_BUILD_FLAGS="-sysroot"

# NextOS: Arch-R toolchain tem race condition no link paralelo do icu host
# (makeconv tenta linkar antes do libicuuc.so estar pronto). Força -j1.
PKG_MAKE_OPTS_HOST="-j1"

# NextOS Amlogic-no defensivo: toolchain host gcc da Arch-R defaulta pra gnu++11.
# ICU 78.3 usa C++17 (auto em param, localpointer.h:559) — sem este sed, compile
# do source dá `parameter declared 'auto'`. CoreELEC tem gcc host >= 13 que aceita
# C++17 em gnu++11 nas extensões — Arch-R não. Sed patcha configure pra forçar.
pre_configure_host() {
  sed -i -e 's/-std=gnu++11/-std=gnu++17/g' -e 's/-std=c++11/-std=c++17/g' "${PKG_BUILD}/source/configure"
}

pre_configure_target() {
  sed -i -e 's/-std=gnu++11/-std=gnu++17/g' -e 's/-std=c++11/-std=c++17/g' "${PKG_BUILD}/source/configure"
}

configure_package() {
  PKG_CONFIGURE_SCRIPT="${PKG_BUILD}/source/configure"
  PKG_CONFIGURE_OPTS_TARGET="--disable-layout \
                             --disable-layoutex \
                             --enable-renaming \
                             --disable-samples \
                             --disable-tests \
                             --disable-tools \
                             --with-cross-build=${PKG_BUILD}/.${HOST_NAME}"
}
