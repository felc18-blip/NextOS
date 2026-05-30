# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present Team CoreELEC (https://coreelec.org)

PKG_NAME="aic8800-sdio"
PKG_VERSION="2bf2dc64bedaf3f0fcbcc206125afa5da8b3835b"
PKG_SHA256=""
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/radxa-pkg/aic8800"
PKG_URL="https://github.com/radxa-pkg/aic8800/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="AIC8800 SDIO WiFi and Bluetooth drivers"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

make_target() {
  # The btlpm Makefile adds -DANDROID_PLATFORM under CONFIG_PLATFORM_AMLOGIC=y,
  # which enables bluesleep_init() (Android-only BT low-power). bluesleep_probe()
  # looks up a 'bt_hostwake' GPIO that doesn't exist in our device tree, fails with
  # -EINVAL, and rolls back the whole aic8800_btlpm module init. Without btlpm the
  # BT subsystem is never powered (rfkill->aicbsp_set_subsys(AIC_BLUETOOTH,1) never
  # runs), so hci0 on /dev/ttyS1 never answers (HCI command tx timeout, BD addr
  # 00:00:00:00:00:00). We're not Android — drop the define so btlpm loads and the
  # rfkill power path brings BT up. rfkill.c compiles unconditionally.
  sed -i '/ifeq ($(CONFIG_PLATFORM_AMLOGIC), y)/,/endif/{/-DANDROID_PLATFORM/d}' \
    ${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800/aic8800_btlpm/Makefile

  # Force the combo "h" firmware for the AIC8800D80. Our chip reports non-h
  # (is_chip_id_h=0 in aic_bsp_driver.c) at rev U02/U03, so the driver would load
  # the wifi-only fmacfw_8800d80_u02.bin and the BT-over-UART core never starts
  # (hci0 silent / BD addr 00:00). The "h" combo firmware (fmacfw_8800d80_h_u02.bin)
  # exposes BT HCI on /dev/ttyS1 — confirmed working: hci0 UP RUNNING, scans devices,
  # WiFi unaffected. This is what the Android factory image effectively uses.
  sed -i 's/aicbsp_firmware_list = fw_8800d80_u02;/aicbsp_firmware_list = fw_8800d80_h_u02;/' \
    ${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800/aic8800_bsp/aic_bsp_driver.c

  kernel_make -C ${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800 \
    M=${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800 \
    PWD=${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800 \
    KDIR=$(kernel_path) \
    CONFIG_PLATFORM_AMLOGIC=y \
    CONFIG_PLATFORM_UBUNTU=n \
    CONFIG_AIC_FW_PATH=/lib/firmware/aic8800D80 \
    modules
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
  cp ${PKG_BUILD}/src/SDIO/driver_fw/driver/aic8800/*/*.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}

  # The chip on Amlogic-no (S905X5M) is an AIC8800D80 (chip rev U02). The driver
  # is built with CONFIG_AIC_FW_PATH=/lib/firmware/aic8800D80 and requests the
  # D80-specific firmware (fw_patch_table_8800d80_u02.bin, etc.). Previously this
  # copied fw/aic8800/* (generic AIC8800 names) into the aic8800D80 dir, so the
  # firmware load failed ("aicbt_patch_table_alloc fail" / "set power on fail").
  # Copy the D80 firmware set; keep the generic set too for any non-D80 AIC8800.
  mkdir -p ${INSTALL}/$(get_full_firmware_dir)/aic8800D80
  cp ${PKG_BUILD}/src/SDIO/driver_fw/fw/aic8800D80/* ${INSTALL}/$(get_full_firmware_dir)/aic8800D80
  cp ${PKG_BUILD}/src/SDIO/driver_fw/fw/aic8800/* ${INSTALL}/$(get_full_firmware_dir)/aic8800D80
}

post_install() {
  # Nothing powers the WiFi chip at boot on Amlogic-no: the legacy wifi_dummy
  # module (which called extern_wifi_set_enable()+sdio_reinit()) was disabled,
  # and the SDIO/udev autoload only fires AFTER the chip is enumerated. Without
  # a power-on the SDIO bus never sees the chip, so wlan0 never appears. This
  # oneshot service powers the chip on early (triggering sdio_reinit) and loads
  # the driver, after which iwd manages wlan0 normally.
  enable_service aic8800-wifi-power.service

  # Bluetooth attach. The stock aic8800-sdio.service runs `hciattach ... any` (H4,
  # no flow control, no nosleep) which does NOT bring up the AIC8800D80 BT. This
  # service loads aic8800_btlpm, unblocks rfkill and runs hciattach with
  # `flow nosleep` after the WiFi driver has loaded the BT firmware (combo "h").
  # Confirmed: hci0 comes up with a valid address and bluetoothd scans/pairs.
  enable_service aic8800-bt-attach.service
}
