#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present ArchR (https://github.com/archr-linux/Arch-R)
# 2026-05-17 Arch-R Amlogic-nxtos: fork felc18-blip/melonDS-nextos Qt6 +
# Wayland + QT_PLUGIN_PATH override (plugins em /usr/plugins não-padrão).

. /etc/profile

set_kill set "-9 melonDS"

sway_fullscreen "melonDS" &

# QT platform - use wayland on Wayland compositors, xcb otherwise
if [ -n "${WAYLAND_DISPLAY}" ]; then
    export QT_QPA_PLATFORM=wayland
else
    export QT_QPA_PLATFORM=xcb
fi

# Qt6 do Arch-R instala plugins em /usr/plugins (não /usr/lib/qt6/plugins).
# Sem essa env var, melonDS sai com "no Qt platform plugin".
export QT_PLUGIN_PATH=/usr/plugins

# Fork felc18-blip/melonDS-nextos hardcoda /storage/.config/emuelec/configs/melonds/.
# Symlink em primeira execução (idempotente).
EMUELEC_CFG="/storage/.config/emuelec/configs/melonds"
SYS_CFG="/usr/config/melonDS"
mkdir -p "${EMUELEC_CFG}"
if [ -d "${SYS_CFG}" ] && [ ! -f "${EMUELEC_CFG}/melonDS.ini" ]; then
    cp -f "${SYS_CFG}"/* "${EMUELEC_CFG}/" 2>/dev/null
fi

/usr/bin/melonDS "${@}"
