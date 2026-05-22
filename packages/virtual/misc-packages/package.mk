# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="misc-packages"
PKG_VERSION=""
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain ${ADDITIONAL_PACKAGES}"
PKG_SECTION="virtual"
PKG_LONGDESC="misc-packages: Metapackage for miscellaneous packages"

# NextOS: driver Realtek RTL8189FTV/FS out-of-tree pra TV box S905W (TX3 Mini etc).
# Chip wifi sdio:c07v024CdF179 não tem driver mainline 6.16+ — só out-of-tree
# fork jwrdegoede/rtl8189ES_linux. ISOLADO em Amlogic-nxtos APENAS.
if [ "${DEVICE}" = "Amlogic-nxtos" ]; then
  PKG_DEPENDS_TARGET+=" rtl8189fs"
fi
