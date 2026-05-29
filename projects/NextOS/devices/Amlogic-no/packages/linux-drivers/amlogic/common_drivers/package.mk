# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present Team CoreELEC (https://coreelec.org)

# 2026-05-28 bump CoreELEC HEAD coreelec-22 — ahead 3 commits:
#   803c1fb2 (2026-05-14) AMDV: fix DV FEL playback for T7 (não toca S7D)
#   3b1456a9 (2026-05-25) gpio_keypad: enable as standalone module (tristate)
#   97f676e6 (2026-05-26) amvecm: fix green screen after resume (toca S7/S7D
#                         mas early-return faz no-op no X5M — pull por completude)
PKG_NAME="common_drivers"
PKG_VERSION="97f676e6c9b8b6bf8811011cdec9d3afc99e1333"
PKG_SHA256=""
PKG_LICENSE="GPL-2.0+ OR MIT"
PKG_SITE="https://coreelec.org"
PKG_URL="https://github.com/CoreELEC/common_drivers/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET=""
PKG_LONGDESC="${PKG_NAME}: extra drivers for amlogic"
PKG_TOOLCHAIN="manual"

make_target() {
  :
}

makeinstall_target() {
  :
}
