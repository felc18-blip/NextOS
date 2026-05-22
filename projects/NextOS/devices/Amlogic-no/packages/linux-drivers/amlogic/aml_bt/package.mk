# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2025-present Team CoreELEC (https://coreelec.org)
# Backported pro NextOS-Elite-Edition Amlogic-no V11 (2026-05-14) — adiciona
# kernel modules BT Amlogic (sdio_driver_bt + w2) e aml_hciattach userspace.
# Resolve ausência de aml/sdio_bt.ko, aml/vlsicomm.ko, aml/w2_bt.ko que estava
# no CE22 oficial mas faltava no nosso V10.

PKG_NAME="aml_bt"
PKG_VERSION="4673a7293cf78fed7cc5c0f7d0378a513dd0e70d"
PKG_SHA256="93857de5ddb3b1f704afa95c028d593203f9c0a0ec2c3c3f9a5225e94b797040"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/CoreELEC/aml_bt"
PKG_URL="https://github.com/CoreELEC/aml_bt/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux w1-aml w2-aml"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="Amlogic bt Linux driver"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

make_target() {
  echo
  echo "build aml_hciattach"
  make -C aml_bt/aml_hciattach

  echo
  echo "build sdio_driver_bt"
  kernel_make -C ${PKG_BUILD}/aml_bt/sdio_driver_bt \
    M=${PKG_BUILD}/aml_bt/sdio_driver_bt \
    KERNEL_SRC=$(kernel_path) \
    EXTRA_SYMBOLS_PATH=$(get_build_dir w1-aml)/project_w1/vmac/Module.symvers

  echo
  echo "build w2"
  kernel_make -C ${PKG_BUILD}/aml_bt/w2 \
    M=${PKG_BUILD}/aml_bt/w2 \
    KERNEL_SRC=$(kernel_path) \
    EXTRA_SYMBOLS_USB_PATH=$(get_build_dir w2-aml)/aml_drv/Module.symvers
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/sbin
    install -m 0755 ${PKG_BUILD}/aml_bt/aml_hciattach/aml_hciattach ${INSTALL}/usr/sbin/aml_hciattach

  mkdir -p ${INSTALL}/$(get_full_module_dir)/aml
    find ${PKG_BUILD}/aml_bt/ -name \*.ko -not -path '*/\.*' -exec cp {} ${INSTALL}/$(get_full_module_dir)/aml \;

  mkdir -p ${INSTALL}/$(get_full_firmware_dir)/aml
    cp ${PKG_BUILD}/aml_bt/aml_hciattach/aml_bt.conf ${INSTALL}/$(get_full_firmware_dir)/aml
    cp ${PKG_BUILD}/aml_bt/firmware/w1_bt_fw_*.bin ${INSTALL}/$(get_full_firmware_dir)/aml
    cp ${PKG_BUILD}/aml_bt/firmware/w2_bt_fw_*.bin ${INSTALL}/$(get_full_firmware_dir)/aml
}
