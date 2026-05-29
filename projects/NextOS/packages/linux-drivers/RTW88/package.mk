# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="RTW88"
PKG_VERSION="d2258b4de21aeabf7ef85ec0cada1f3cff9bcbe0"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/lwfinger/rtw88"
PKG_URL="https://github.com/lwfinger/rtw88/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="RTW88 downstream driver"
PKG_TOOLCHAIN="make"
PKG_IS_KERNEL_PKG="yes"

pre_make_target() {
  unset LDFLAGS

  # 2026-05-28: kernel 5.15.196 backportou ieee80211_sta refactor do
  # mainline 6.x — varios membros migraram pra struct ieee80211_link_sta
  # acessivel via sta->deflink.* (per-link STA support MLO Wi-Fi 7).
  # struct ieee80211_link_sta no kernel 5.15.196 contem:
  #   supp_rates, ht_cap, vht_cap, he_cap, he_6ghz_capa, eht_cap,
  #   rx_nss, bandwidth, txpwr
  # RTW88 main usa old API direto em sta->. Rename inline em .c/.h.
  # Operacao idempotente: sed so pega `sta->X` exato, nao `sta->deflink.X`.
  find ${PKG_BUILD} -type f \( -name '*.c' -o -name '*.h' \) -exec sed -i \
    -e 's/sta->vht_cap/sta->deflink.vht_cap/g' \
    -e 's/sta->ht_cap/sta->deflink.ht_cap/g' \
    -e 's/sta->he_cap/sta->deflink.he_cap/g' \
    -e 's/sta->he_6ghz_capa/sta->deflink.he_6ghz_capa/g' \
    -e 's/sta->eht_cap/sta->deflink.eht_cap/g' \
    -e 's/sta->supp_rates/sta->deflink.supp_rates/g' \
    -e 's/sta->bandwidth/sta->deflink.bandwidth/g' \
    -e 's/sta->rx_nss/sta->deflink.rx_nss/g' \
    -e 's/sta->txpwr/sta->deflink.txpwr/g' \
    {} \;
}

make_target() {
  make V=1 \
       ARCH=${TARGET_KERNEL_ARCH} \
       KSRC=$(kernel_path) \
       CROSS_COMPILE=${TARGET_KERNEL_PREFIX} \
       CONFIG_POWER_SAVING=y
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/kernel/drivers/net/wireless
    cp *.ko ${INSTALL}/$(get_full_module_dir)/kernel/drivers/net/wireless
}
