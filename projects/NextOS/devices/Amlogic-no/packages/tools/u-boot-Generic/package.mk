# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 NextOS (https://github.com/felc18-blip/NextOS)
#
# Dummy u-boot stub para Generic subdevice do Amlogic-no.
# A imagem Generic NÃO grava u-boot embedded no SD (TV box X4/X5/X928X
# usa u-boot interno da eMMC, aml_autoscript carrega kernel/dtb). O global
# u-boot/package.mk adiciona `u-boot-${SUBDEVICE}` em PKG_DEPENDS_TARGET
# pra cada subdevice — pra Generic, esse pacote é só stub vazio satisfazendo
# a dep. subdevice_config.sh case "Generic" não seta DEVICE_UBOOT, então
# bootloader/mkimage skipa o `dd u-boot to SD` passo automaticamente.

PKG_NAME="u-boot-Generic"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Stub u-boot for Generic subdevice (no embedded bootloader)"
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  :
}
