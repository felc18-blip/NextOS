# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="gamesupport"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/NextOS"
PKG_SECTION="virtual"
PKG_LONGDESC="Game support software metapackage."

PKG_GAMESUPPORT="sixaxis nextos-hotkey jstest-sdl gamecontrollerdb sdljoytest sdltouchtest control-gen sdl2text"

case ${DEVICE} in
  SM8250|SM8550|SM8650|SDM845|S922X|RK3326|Amlogic-nxtos)
    # Amlogic-nxtos = S905W TV box. MangoHud roda só com GL hooks (Mali-450
    # Utgard sem Vulkan) — FPS/CPU OK, GPU stats limitadas. Vale incluir
    # pra benchmarking de cores RA em 1080p.
    PKG_GAMESUPPORT+=" mangohud"
  ;;
esac

# nextos-touchscreen-keyboard requires sway
[[ "${WINDOWMANAGER}" = "swaywm-env" ]] && PKG_GAMESUPPORT+=" nextos-touchscreen-keyboard"

PKG_DEPENDS_TARGET="${PKG_GAMESUPPORT}"

