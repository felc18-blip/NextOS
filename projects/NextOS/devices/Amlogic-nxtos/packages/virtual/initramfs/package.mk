# SPDX-License-Identifier: GPL-2.0-or-later
# Per-device Amlogic-nxtos: remove plymouth-lite (source 404 upstream
# ROCKNIX). nextos-splash ja cobre splash boot fb0 — plymouth e redundante.

PKG_NAME="initramfs"
PKG_VERSION=""
PKG_LICENSE="GPL"
PKG_SITE="http://www.openelec.tv"
PKG_URL=""
PKG_DEPENDS_INIT="libc:init busybox:init util-linux:init e2fsprogs:init dosfstools:init spleen-font:init avfs:init nextos-splash:init bkeymaps:init"
PKG_DEPENDS_TARGET="toolchain initramfs:init"
PKG_SECTION="virtual"
PKG_LONGDESC="Metapackage for installing initramfs (Amlogic-nxtos override sem plymouth)"

if [ "${ISCSI_SUPPORT}" = yes ]; then
  PKG_DEPENDS_INIT+=" open-iscsi:init"
fi

if [ "${INITRAMFS_PARTED_SUPPORT}" = yes ]; then
  PKG_DEPENDS_INIT+=" parted:init"
fi

for i in ${PKG_DEPENDS_INIT}; do
  PKG_NEED_UNPACK+=" $(get_pkg_directory ${i})"
done

if [ "${BUILD_ANDROID_BOOTIMG}" = "yes" ]; then
  PKG_DEPENDS_INIT+=" fakeroot:host"
fi
