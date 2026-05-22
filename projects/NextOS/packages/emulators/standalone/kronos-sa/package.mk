# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="kronos-sa"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/FCare/Kronos"
PKG_ARCH="any"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="58352d6dc969fa90c5fa1220f38ffe577157547f"
PKG_GIT_CLONE_BRANCH="extui-align"
PKG_DEPENDS_TARGET="toolchain"
# kronos-sa upstream requer Qt5 + GL3 + Vulkan — não satisfeito em Mali-450
# aarch64. Recipe stub: instala apenas start_kronos.sh + config pra ES poder
# listar o sistema. Binário kronos não compila; placeholder.
PKG_LONGDESC="Kronos is a Sega Saturn emulator forked from yabause."
PKG_TOOLCHAIN="manual"
GET_HANDLER_SUPPORT="git"

# Skip download/configure/build — fonte upstream tem Vulkan/Qt5 hard deps.
unpack() { mkdir -p ${PKG_BUILD}; }
configure_target() { true; }
make_target() { true; }

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  echo "kronos binary not built on aarch64 (Vulkan/Qt5 required) — stub"
  cp -a ${PKG_DIR}/scripts/start_kronos.sh ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/start_kronos.sh
  mkdir -p ${INSTALL}/usr/config/kronos/qt
  cp ${PKG_DIR}/config/kronos.ini ${INSTALL}/usr/config/kronos/qt
}
