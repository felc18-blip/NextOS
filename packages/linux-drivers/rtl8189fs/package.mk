# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present NextOS-Elite-Edition (felc18-blip)

PKG_NAME="rtl8189fs"
PKG_VERSION="d685a6f7200dac6ddf2a4b1b96b848b92f34f9dd"
PKG_SHA256="438054f1974d9c1d51018c038aaa242e53aace99427e0f3ee79baf364b9a29a0"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/jwrdegoede/rtl8189ES_linux"
PKG_URL="https://github.com/jwrdegoede/rtl8189ES_linux/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="Realtek RTL8189FTV/FS SDIO Wireless LAN driver (out-of-tree)"
PKG_TOOLCHAIN="manual"
PKG_IS_KERNEL_PKG="yes"
PKG_DEPENDS_TARGET="toolchain linux"

pre_make_target() {
  unset LDFLAGS
  sed -i 's/-DCONFIG_CONCURRENT_MODE//g' Makefile

  # Kernel 7.1+ flexible arrays removidos in-kernel.
  if [ -f core/rtw_br_ext.c ]; then
    sed -i \
      -e 's|tag->tag_data|((unsigned char *)(tag + 1))|g' \
      -e 's|pOldTag->tag_data|((unsigned char *)(pOldTag + 1))|g' \
      -e 's|ph->tag|((struct pppoe_tag *)(ph + 1))|g' \
      core/rtw_br_ext.c
  fi

  # Kernel 7.1+: cfg80211_ops callbacks que aceitavam `struct net_device *ndev`
  # passam a aceitar `struct wireless_dev *wdev`. Patch automatico das 30+
  # funcoes afetadas via Python: trocar signature + injetar ndev=wdev->netdev.
  if [ -f os_dep/linux/ioctl_cfg80211.c ]; then
    python3 - <<'PYEOF'
import re
path = "os_dep/linux/ioctl_cfg80211.c"
with open(path) as f: s = f.read()

# Funcoes cfg80211_ops callbacks que mudaram em 7.1:
# (lista derivada de include/net/cfg80211.h cross-ref com rtw_cfg80211_ops)
# Lista AUTORITATIVA derivada de include/net/cfg80211.h em kernel 7.1-rc3.
# Apenas callbacks que MUDARAM pra `struct wireless_dev *wdev`:
WDEV_CALLBACKS = [
    "cfg80211_rtw_add_key", "cfg80211_rtw_get_key", "cfg80211_rtw_del_key",
    "cfg80211_rtw_set_default_mgmt_key",
    "cfg80211_rtw_add_station", "cfg80211_rtw_del_station",
    "cfg80211_rtw_change_station", "cfg80211_rtw_get_station",
    "cfg80211_rtw_dump_station",
    "cfg80211_rtw_set_txpower", "cfg80211_rtw_get_txpower",
    "cfg80211_rtw_mgmt_tx",
    "cfg80211_rtw_remain_on_channel", "cfg80211_rtw_cancel_remain_on_channel",
    "cfg80211_rtw_del_virtual_intf",
]

def patch_signature(s, fn):
    # match `(static\s)?int<sp>FN(struct wiphy *wiphy,[..]struct net_device *ndev`
    # `static` é opcional (set_default_mgmt_key declarada sem static).
    pat = re.compile(
        r"((?:static\s+)?int\s+" + fn + r"\s*\(struct wiphy \*wiphy,\s*)struct net_device \*ndev",
        re.MULTILINE | re.DOTALL
    )
    s2, n = pat.subn(r"\1struct wireless_dev *wdev", s)
    return s2, n

def inject_body(s, fn):
    # inject "struct net_device *ndev = wdev->netdev;" logo após `{`
    pat = re.compile(
        r"((?:static\s+)?int\s+" + fn + r"\b[^{]*?\{\n)",
        re.MULTILINE | re.DOTALL
    )
    inject = r"\1\tstruct net_device *ndev = wdev ? wdev->netdev : NULL;\n\tif (!ndev) return -EINVAL;\n"
    s2, n = pat.subn(inject, s, count=1)
    return s2, n

total_sig = 0
total_body = 0
for fn in WDEV_CALLBACKS:
    s, n1 = patch_signature(s, fn)
    if n1:
        total_sig += n1
        s, n2 = inject_body(s, fn)
        if n2: total_body += n2

print(f"[rtl8189fs cfg80211 patch] signatures={total_sig} bodies={total_body}")

# Kernel 7.1+ helpers cfg80211_new_sta() e cfg80211_del_sta() aceitam wdev:
# substituir caller "cfg80211_new_sta(<ndev>" → "cfg80211_new_sta(<ndev->ieee80211_ptr>"
# Mesmo pra cfg80211_del_sta. Heuristica simples:
s = re.sub(r"cfg80211_new_sta\(([^,]+),", r"cfg80211_new_sta(\1->ieee80211_ptr,", s)
s = re.sub(r"cfg80211_del_sta\(([^,]+),", r"cfg80211_del_sta(\1->ieee80211_ptr,", s)

with open(path, "w") as f: f.write(s)
print(f"ioctl_cfg80211.c patched OK")
PYEOF
  fi
}

make_target() {
  kernel_make ARCH=${TARGET_KERNEL_ARCH} \
              CROSS_COMPILE=${TARGET_PREFIX} \
              KSRC=$(kernel_path) \
              modules
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
  cp 8189fs.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
