# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023-present Team CoreELEC (https://coreelec.org)

PKG_NAME="RTW88"
PKG_VERSION="52072d874840f28c247b27f5d799f2c5c88a7e61"
PKG_SHA256=""
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/lwfinger/rtw88"
PKG_URL="https://github.com/lwfinger/rtw88/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="Latest Realtek WiFi 5 Codes on Linux"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

pre_make_target() {
  # NextOS 2026-05-12 (V6): kernel 5.15.196 backportou ieee80211_sta refactor
  # do mainline 6.x onde varios membros migraram pra struct ieee80211_link_sta
  # acessivel via sta->deflink.* (parte do per-link STA support MLO Wi-Fi 7).
  # struct ieee80211_link_sta no kernel 5.15.196 contem:
  #   supp_rates, ht_cap, vht_cap, he_cap, he_6ghz_capa, eht_cap,
  #   rx_nss, bandwidth, txpwr
  # RTW88 v5.4-rc usa old API direto em sta->. Rename inline em .c/.h.
  # Operacao idempotente: sed só pega `sta->X` exato, nao `sta->deflink.X`.
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
  kernel_make -C ${PKG_BUILD} \
    M=${PKG_BUILD} \
    KSRC=$(kernel_path)
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
    find ${PKG_BUILD}/ -name \*.ko -not -path '*/\.*' -exec cp {} ${INSTALL}/$(get_full_module_dir)/${PKG_NAME} \;
}
