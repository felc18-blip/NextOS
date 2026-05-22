# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="kronos-lr"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/yabause"
PKG_ARCH="any"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="6709c1dd0e26094f005b19c6e473c30809718b78"
PKG_GIT_CLONE_BRANCH="kronos"
PKG_DEPENDS_TARGET="toolchain boost zlib"
PKG_LONGDESC="Kronos is a Sega Saturn emulator forked from yabause."
PKG_TOOLCHAIN="make"
GET_HANDLER_SUPPORT="git"
PKG_PATCH_DIRS+="${DEVICE}"

pre_configure_target() {
  sed -i 's/\-latomic//' ${PKG_BUILD}/yabause/src/libretro/Makefile
}

make_target() {
# This was only necessary in the main repo, but may come to libretro later on
#  make -C ${PKG_BUILD}/yabause/src/libretro/ generate-files
  # kronos-lr é x86-only no upstream (Makefile força -msse/-mfpmath=sse).
  # Best-effort em aarch64 — falha silenciosa pra não travar build geral.
  make -C ${PKG_BUILD}/yabause/src/libretro/ || true
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ -f ${PKG_BUILD}/yabause/src/libretro/kronos_libretro.so ]; then
    cp -a ${PKG_BUILD}/yabause/src/libretro/kronos_libretro.so ${INSTALL}/usr/lib/libretro/kronos_libretro.so
  else
    echo "kronos_libretro.so not built (expected on non-x86) — skipped"
  fi
}
