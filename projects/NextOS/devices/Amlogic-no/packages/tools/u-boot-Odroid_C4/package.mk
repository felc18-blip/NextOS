# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="u-boot-Odroid_C4"
PKG_VERSION="93399925229437d08403c8eab7d3351bc7ec849b"
PKG_SHA256="ee4587e2e6c41954aa82ea3c99a2f9c4e96944afd3017d4742156dfec50c9d5b"
PKG_LICENSE="GPL"
PKG_SITE="https://www.denx.de/wiki/U-Boot"
PKG_URL="https://github.com/CoreELEC/u-boot/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain gcc-linaro-aarch64-elf:host gcc-linaro-arm-eabi:host"
PKG_LONGDESC="Das U-Boot is a cross-platform bootloader for embedded systems."
PKG_TOOLCHAIN="manual"

pre_make_target() {
  sed -i "s|arm-none-eabi-|arm-eabi-|g" $PKG_BUILD/Makefile $PKG_BUILD/arch/arm/cpu/armv8/*/firmware/scp_task/Makefile 2>/dev/null || true
  # NextOS 2026-05-10: GCC 15 trata unused-but-set-variable como erro (fip_create.c:438 'int cnt = 0').
  sed -i 's|-Wall -Werror -pedantic|-Wall -Wno-error -pedantic|g' $PKG_BUILD/tools/fip_create/Makefile 2>/dev/null || true
  # NextOS 2026-05-10: /usr/include/libfdt.h (Arch dtc 1.7.2) conflita com interno do u-boot.
  # Guard interno=_LIBFDT_H vs sistema=LIBFDT_H; defino ambos pra sistema ser skipado.
  # Libfdt fix completo: defino guards do sistema (Arch dtc 1.7.2) nos headers internos
  for h in libfdt:LIBFDT_H libfdt_env:LIBFDT_ENV_H fdt:FDT_H; do
    file=${h%%:*}; guard=${h##*:}; intern="_${guard}"
    headerf="$PKG_BUILD/include/$file.h"
    if [ -f "$headerf" ] && ! grep -q "^#define $guard$" "$headerf"; then
      sed -i "/^#define $intern/a #define $guard" "$headerf"
    fi
  done
  true
}

configure_package() {
  PKG_UBOOT_CONFIG="odroidc4_defconfig"
}

make_target() {
  [ "${BUILD_WITH_DEBUG}" = "yes" ] && PKG_DEBUG=1 || PKG_DEBUG=0
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-elf/bin/:$TOOLCHAIN/lib/gcc-linaro-arm-eabi/bin/:$PATH
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make mrproper
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make $PKG_UBOOT_CONFIG
  DEBUG=${PKG_DEBUG} CROSS_COMPILE=aarch64-elf- ARCH=arm CFLAGS="" LDFLAGS="" make HOSTCC="$HOST_CC" HOSTSTRIP="true"
}

makeinstall_target() {
  : # nothing
}
