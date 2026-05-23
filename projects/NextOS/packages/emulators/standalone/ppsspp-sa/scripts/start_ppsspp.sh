#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
set_kill set "-9 ppsspp"

SOURCE_DIR="/usr/config/ppsspp"
CONF_DIR="/storage/.config/ppsspp"
PPSSPP_INI="PSP/SYSTEM/ppsspp.ini"

# Check if conf dir exists
if [ ! -d "${CONF_DIR}" ]
then
  cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi

# Check if savestate dir exists
if [ ! -d "/storage/roms/savestates/psp/ppsspp-sa" ]; then
  mkdir -p "/storage/roms/savestates/psp/ppsspp-sa"
fi

#Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
ASKIP=$(get_setting auto_frame_skip "${PLATFORM}" "${GAME}")
FPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
IRES=$(get_setting internal_resolution "${PLATFORM}" "${GAME}")
GRENDERER=$(get_setting graphics_backend "${PLATFORM}" "${GAME}")
SKIPB=$(get_setting skip_buffer_effects "${PLATFORM}" "${GAME}")
VSYNC=$(get_setting vsync "${PLATFORM}" "${GAME}")
CLOCK_SPEED=$(get_setting clock_speed "${PLATFORM}" "${GAME}")

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  ### All..
  unset EMUPERF
fi

  #Auto Frame Skip — default ON when no explicit setting. RK3326 cannot
  #sustain 60fps in heavier PSP titles; without auto-skip the user sees
  #15fps stutter instead of a smooth 25-30. Users that prefer no skipping
  #can flip the per-platform / per-game setting to "0".
	if [ "${ASKIP}" = "0" ]; then
		sed -i '/^AutoFrameSkip =/c\AutoFrameSkip = False' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/AutoFrameSkip =/c\AutoFrameSkip = True' ${CONF_DIR}/${PPSSPP_INI}
        fi

  #Graphics Backend
        if [ "${GRENDERER}" = "opengl" ]; then
                sed -i '/^GraphicsBackend =/c\GraphicsBackend = 0 (OPENGL)' ${CONF_DIR}/${PPSSPP_INI}
        elif [ "${GRENDERER}" = "vulkan" ]; then
                sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' ${CONF_DIR}/${PPSSPP_INI}
        else
		sed -i '/^GraphicsBackend =/c\GraphicsBackend = @GRENDERER@' ${CONF_DIR}/${PPSSPP_INI}
	fi

  #Internal Resolution
	if [ "${IRES}" = "2" ]; then
		sed -i '/^InternalResolution/c\InternalResolution = 2' ${CONF_DIR}/${PPSSPP_INI}
	elif [ "${IRES}" = "3" ]; then
		sed -i '/^InternalResolution/c\InternalResolution = 3' ${CONF_DIR}/${PPSSPP_INI}
	elif [ "${IRES}" = "4" ]; then
                sed -i '/^InternalResolution/c\InternalResolution = 4' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/^InternalResolution/c\InternalResolution = 1' ${CONF_DIR}/${PPSSPP_INI}
        fi

  #Show FPS
	if [ "${FPS}" = "1" ]; then
		sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 2' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 0' ${CONF_DIR}/${PPSSPP_INI}
	fi

  #Skip Buffer Effects
	if [ "${SKIPB}" = "1" ]; then
		sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = True' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = False' ${CONF_DIR}/${PPSSPP_INI}
	fi

  #VSYNC
	if [ "${VSYNC}" = "1" ]; then
		sed -i '/^VSyncInterval =/c\VSyncInterval = True' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/^VSyncInterval =/c\VSyncInterval = False' ${CONF_DIR}/${PPSSPP_INI}
	fi

  #Clock Speed
	if [ "${CLOCK_SPEED}" = "222" ]; then
		sed -i '/^CPUSpeed =/c\CPUSpeed = 222' ${CONF_DIR}/${PPSSPP_INI}
	elif [ "${CLOCK_SPEED}" = "333" ]; then
		sed -i '/^CPUSpeed =/c\CPUSpeed = 333' ${CONF_DIR}/${PPSSPP_INI}
	else
		sed -i '/^CPUSpeed =/c\CPUSpeed = 0' ${CONF_DIR}/${PPSSPP_INI}
	fi

#Retroachievements
/usr/bin/cheevos_ppsspp.sh

ARG=${1//[\\]/}

# Debugging info:
  echo "GAME set to: ${GAME}"
  echo "PLATFORM set to: ${PLATFORM}"
  echo "CONF DIR: ${CONF_DIR}/${PPSSPP_INI}"
  echo "CPU CORES set to: ${EMUPERF}"
  echo "AUTO FRAME SKIP set to: ${ASKIP}"
  echo "GRAPHICS RENDERER set to: ${GRENDERER}"
  echo "INTERNAL RESOLUTION set to: ${IRES}"
  echo "FPS set to: ${FPS}"
  echo "SKIP BUFFER EFFECTS set to: ${SKIPB}"
  echo "VSYNC set to: ${VSYNC}"
  echo "Launching /usr/bin/ppsspp ${ARG}"

# Mesa Lima (Mali-450) only — sem PAN_MESA_DEBUG/MESA_NO_ERROR/MESA_GLTHREAD.
# PAN_* sao do driver Panfrost (Bifrost+) e quebram a init de EGL no Lima
# (renderer reporta "OpenGL ES version 0.0" e o emulador crasha SIGSEGV
# pouco depois do gamepad inicializar).

# Amlogic-nxtos (Mali-450 + Wayland): PPSSPP trava no shutdown ao usuario
# clicar Exit pelo menu. main loop sai (g_QuitRequested=true) → chama
# EmuThreadJoin() → emu thread fica em futex_wait eterno (deadlock no Mesa
# Lima quando libera GPU context com Wayland surface). Processo nunca
# termina, ES fica travado esperando script retornar.
# Fix: spawn ppsspp em bg + watchdog que mede voluntary_ctxt_switches
# agregado das threads filhas. Em gameplay/menu PPSSPP normal: ~500/s.
# Em deadlock: TODAS threads em futex_wait, delta = 0. Se 6s consecutivos
# sem delta + dentro do shutdown (apos PPSSPP main retornar break), SIGKILL.
if echo "${HW_DEVICE}" | grep -q "Amlogic-nxtos"; then
  ${EMUPERF} ppsspp --pause-menu-exit "${ARG}" &
  PPID_=$!
  (
    stuck=0
    last=-1
    while kill -0 "${PPID_}" 2>/dev/null; do
      sleep 1
      [ ! -d "/proc/${PPID_}/task" ] && break
      cur=$(awk '/voluntary_ctxt_switches/{s+=$2} END{print s+0}' /proc/"${PPID_}"/task/*/status 2>/dev/null)
      if [ "${cur}" = "${last}" ]; then
        stuck=$((stuck + 1))
        if [ "${stuck}" -ge 6 ]; then
          echo "[start_ppsspp] shutdown deadlock detectado (ctxt_switches estagnado ${stuck}s), SIGKILL pid=${PPID_}" >&2
          kill -9 "${PPID_}" 2>/dev/null
          break
        fi
      else
        stuck=0
      fi
      last="${cur}"
    done
  ) &
  WPID=$!
  wait "${PPID_}"
  RET=$?
  kill "${WPID}" 2>/dev/null
  exit "${RET}"
fi

${EMUPERF} ppsspp --pause-menu-exit "${ARG}"
