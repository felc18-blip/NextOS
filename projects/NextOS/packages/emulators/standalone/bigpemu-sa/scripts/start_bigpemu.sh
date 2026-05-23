#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present UnofficialOS (https://github.com/RetroGFX/UnofficialOS)

. /etc/profile

set_kill set "-9 bigpemu"

#Check if bigpemu exists in .config
if [ ! -d "/storage/.config/bigpemu/userdata" ]; then
  mkdir -p "/storage/.config/bigpemu/userdata"
  cp -r "/usr/config/bigpemu/userdata" "/storage/.config/bigpemu"
fi

# Link bigpemu userdata to .config/bigemu
rm -r /storage/.bigpemu_userdata
ln -sf /storage/.config/bigpemu/userdata /storage/.bigpemu_userdata

#Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
if [ "${CORES}" = "little" ]
then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]
then
  EMUPERF="${FAST_CORES}"
else
  #All..
  unset EMUPERF
fi

# Launch bigpemu, using gl4es if present (S922X, RK3566-BSP)
if echo ${HW_DEVICE} | grep -q "S922X"; then
  unset SDL_VIDEODRIVER
  export SDL_VIDEO_GL_DRIVER=/usr/lib/egl/libGL.so.1
  export SDL_VIDEO_EGL_DRIVER=/usr/lib/egl/libEGL.so.1
  ${EMUPERF} /usr/share/bigpemu/bigpemu "${1}"
elif echo ${HW_DEVICE} | grep -q "RK3566"; then
  export LD_LIBRARY_PATH="/usr/share/bigpemu"
  LD_PRELOAD=/usr/share/bigpemu/libOpenGL.so ${EMUPERF} /usr/share/bigpemu/bigpemu "${1}"
elif echo ${HW_DEVICE} | grep -q "Amlogic-nxtos"; then
  # Mali-450 Utgard GLES2-only via Mesa Lima. bigpemu (aarch64) tenta carregar
  # desktop GL e falha "vital systems failed". Preload gl4es libGL.so.1 (que
  # traduz desktop GL → GLES2) + Wayland video driver (sem isso SDL tenta
  # KMSDRM e bate com sway compositor). Validado 2026-05-23.
  export SDL_VIDEODRIVER=wayland
  export SDL_AUDIODRIVER=pulseaudio
  cd /usr/share/bigpemu
  # gptokeyb mode 1 com kill_mode trap Select+Start — bigpemu faz SDL grab
  # exclusivo do controle, input_sense daemon nao consegue ler eventos, entao
  # set_kill "-9 bigpemu" + killall via input_sense nao dispara. gptokeyb
  # spawnado paralelo abre proprio handle SDL_JOYSTICK e mata bigpemu via SIGKILL
  # quando detecta combo Select+Start (kill_mode default do modo 1).
  if [ -x /usr/bin/gptokeyb ]; then
    pkill -9 -f "gptokeyb.*bigpemu" 2>/dev/null
    cat > /tmp/bigpemu-kill.gptk << 'GPTK'
up    = up
down  = down
left  = left
right = right
GPTK
    env -u EMUELEC /usr/bin/gptokeyb 1 bigpemu -c /tmp/bigpemu-kill.gptk &
    trap 'pkill -9 -f "gptokeyb.*bigpemu" 2>/dev/null; true' EXIT INT TERM HUP
    sleep 0.3
  fi
  LD_PRELOAD=/usr/lib/gl4es/libGL.so.1 ${EMUPERF} /usr/share/bigpemu/bigpemu "${1}"
else
  ${EMUPERF} /usr/share/bigpemu/bigpemu "${1}"
fi
