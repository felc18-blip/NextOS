#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

. /run/sway/sway-daemon.conf
SWAY_LOG_FILE=/var/log/sway.log

if [ ! -z "$(lsmod | grep 'nvidia')" ]; then
  export WLR_NO_HARDWARE_CURSORS=1
  SWAY_GPU_ARGS="--unsupported-gpu"
fi

# NextOS Amlogic-no (S905X5/X5M, s7d/s6/s5 — vendor kernel meson 5.15 + libMali
# Valhall): o atomic do meson rejeita o commit (EINVAL) -> backend LEGADO; o
# meson nao tem cursor plane (drmModeSetCursor ENXIO) -> cursor por software; e
# libmali deve alocar LINEAR (sem AFBC) no plane primario. Sem isso o sway nao
# modeseta o blob g310. (Combinado com o fork rockchip-wlroots -rk, que importa
# os buffers wayland do cliente Mali, e o patch de cursor non-fatal no -rk.)
if grep -qE "s7d|s6|s5" /proc/device-tree/compatible 2>/dev/null; then
  export WLR_DRM_NO_ATOMIC=1
  export WLR_NO_HARDWARE_CURSORS=1
  export MALI_WAYLAND_AFBC=0
fi

if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
    dbus-daemon --session --address=unix:path=$XDG_RUNTIME_DIR/bus &
fi

# start sway, even if no input devices are connected
export WLR_LIBINPUT_NO_DEVICES=1

logger -t Sway "### Starting Sway with -V ${SWAY_GPU_ARGS} ${SWAY_DAEMON_ARGS}"
/usr/bin/sway -V ${SWAY_GPU_ARGS} ${SWAY_DAEMON_ARGS} > ${SWAY_LOG_FILE} 2>&1
