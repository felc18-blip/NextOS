# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="initramfs"
PKG_VERSION=""
PKG_LICENSE="GPL"
PKG_SITE="http://www.openelec.tv"
PKG_URL=""
# Paridade com Elite no boot do Amlogic-no:
#  - bkeymaps:init     keymaps internacionais (hu/pc/se/fi/is/it/es/by…)
#                      no initramfs pra teclado USB antes do userspace.
#  - splash-image:init binário CoreELEC + /splash/progress/ frames PNG
#                      (fallback do nextos-splash quando o init não consegue
#                      KMSDRM no kernel 5.15 BSP — splash-image usa fbset
#                      direto). 32 frames de progress copiados de Elite.
PKG_DEPENDS_INIT="libc:init busybox:init util-linux:init e2fsprogs:init dosfstools:init spleen-font:init avfs:init nextos-splash:init bkeymaps:init splash-image:init"
PKG_DEPENDS_TARGET="toolchain initramfs:init"
PKG_SECTION="virtual"
PKG_LONGDESC="Metapackage for installing initramfs"

if [ "${ISCSI_SUPPORT}" = yes ]; then
  PKG_DEPENDS_INIT+=" open-iscsi:init"
fi

if [ "${INITRAMFS_PARTED_SUPPORT}" = yes ]; then
  PKG_DEPENDS_INIT+=" parted:init"
fi

for i in ${PKG_DEPENDS_INIT}; do
  PKG_NEED_UNPACK+=" $(get_pkg_directory ${i})"
done

# fakeroot needed to mknod /dev/console as root in initramfs.cpio.
if [ "${BUILD_ANDROID_BOOTIMG}" = "yes" ]; then
  PKG_DEPENDS_INIT+=" fakeroot:host"
fi

post_install() {
  # Generate initramfs.cpio for devices that use Android boot image (Amlogic-no).
  # Without this, linux:target make_target fails with "cannot statx image/initramfs.cpio".
  if [ "${BUILD_ANDROID_BOOTIMG}" = "yes" ]; then
    (
      cd ${BUILD}/initramfs

      ln -sfn /usr/lib  ${BUILD}/initramfs/lib
      ln -sfn /usr/bin  ${BUILD}/initramfs/bin
      ln -sfn /usr/sbin ${BUILD}/initramfs/sbin

      mkdir -p ${BUILD}/image
      fakeroot -- sh -c \
        "mkdir -p dev; mknod -m 600 dev/console c 5 1; find . | cpio -H newc -ov -R 0:0 > ${BUILD}/image/initramfs.cpio"
    )
  fi
}
