# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team CoreELEC (https://coreelec.org)

PKG_NAME="ap6xxx-aml"
PKG_VERSION="b2541e247f88e84873041cad9d2605aa4202d352"
PKG_SHA256=""
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_URL="https://github.com/CoreELEC/ap6xxx-aml/archive/${PKG_VERSION}.tar.gz"
PKG_SITE="https://github.com/CoreELEC/ap6xxx-aml"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="ap6xxx: Linux drivers for AP6xxx WLAN chips used in some devices based on Amlogic SoCs"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

pre_make_target() {
  # NextOS 2026-05-10: kernel 5.15.196 backportou cfg80211_port_authorized com 5 args.
  # Driver default só usa 5 args em kernel >= 6.2.0; nosso 5.15.196 também precisa.
  # Replace 3-arg call por 5-arg (NULL, 0 são td_bitmap e td_bitmap_len).
  WL=${PKG_BUILD}/bcmdhd.101.10.591.x/wl_cfg80211.c
  if [ -f "$WL" ] && grep -q "cfg80211_port_authorized(ndev, (const u8 \*)curbssid, GFP_KERNEL)" "$WL"; then
    sed -i 's|cfg80211_port_authorized(ndev, (const u8 \*)curbssid, GFP_KERNEL);|cfg80211_port_authorized(ndev, (const u8 *)curbssid, NULL, 0, GFP_KERNEL); /* NextOS-PORTAUTH-fix */|g' "$WL"
  fi

  # NextOS 2026-05-13 (V7): kernel 5.15.196 backportou cfg80211_ch_switch_notify
  # com 4 args (chandef, link_id, punct_bitmap). Driver tem condicionais por
  # versao mas todas usam ANDROID_VERSION (que nao temos). O CFG80211_BKPORT_MLO
  # (que ativamos via KCFLAGS) seleciona a 3-arg version mas nosso kernel
  # 5.15.196 EXIGE 4. Sed inline pra forcar 4-arg em todos call sites.
  VIF=${PKG_BUILD}/bcmdhd.101.10.591.x/wl_cfgvif.c
  if [ -f "$VIF" ] && grep -q "cfg80211_ch_switch_notify(dev, &chandef, 0);" "$VIF"; then
    sed -i 's|cfg80211_ch_switch_notify(dev, &chandef, 0);|cfg80211_ch_switch_notify(dev, \&chandef, 0, 0); /* NextOS-CHSW-fix-4arg */|g' "$VIF"
  fi
  true
}

make_target() {
  # NextOS 2026-05-13 (V7): kernel 5.15.196 backportou ieee80211_link_sta refactor
  # do mainline 6.x: wireless_dev passou a ter union u.{client,ap,mesh,ibss} com
  # ssid/ssid_len/preset_chandef/current_bss movidos. cfg80211_roam_info e
  # cfg80211_connect_resp_params tambem ganharam .links[0].{bssid,bss,channel}.
  # O driver bcmdhd.101.10.591.x JA TEM as condicionais via macros
  # CFG80211_BKPORT_MLO e ANDROID13_KERNEL515_BKPORT, mas elas SO ativam se
  # ANDROID_VERSION >= 13. Como nosso build nao e Android, forcamos via KCFLAGS.
  KFLAGS_MLO="-DCFG80211_BKPORT_MLO -DANDROID13_KERNEL515_BKPORT"

  echo
  echo "building ap6275s and others"
  kernel_make -C  ${PKG_BUILD}/bcmdhd.101.10.591.x \
       M=${PKG_BUILD}/bcmdhd.101.10.591.x \
       PWD=${PKG_BUILD}/bcmdhd.101.10.591.x \
       KERNEL_SRC=$(kernel_path) \
       KCFLAGS="${KFLAGS_MLO}" \
       CONFIG_BCMDHD_DISABLE_WOWLAN=y \
       CONFIG_BCMDHD_SDIO=y \
       bcmdhd_sdio

  echo "building ap6275p"
  kernel_make -C  ${PKG_BUILD}/bcmdhd.101.10.591.x \
       M=${PKG_BUILD}/bcmdhd.101.10.591.x \
       PWD=${PKG_BUILD}/bcmdhd.101.10.591.x \
       KERNEL_SRC=$(kernel_path) \
       KCFLAGS="${KFLAGS_MLO}" \
       CONFIG_BCMDHD_DISABLE_WOWLAN=y \
       CONFIG_BCMDHD_PCIE=y \
       bcmdhd_pcie
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
  cp ${PKG_BUILD}/*/*.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
