#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
# NextOS Amlogic-no: PPSSPP backend Vulkan via bridge DRM/KMS + GBM-import.
# Coexiste com o ppsspp-sa GLES (binario separado /usr/bin/ppsspp-vulkan, mesma config).

. /etc/profile
set_kill set "-9 ppsspp-vulkan"

SOURCE_DIR="/usr/config/ppsspp"
CONF_DIR="/storage/.config/ppsspp"
PPSSPP_INI="PSP/SYSTEM/ppsspp.ini"

if [ ! -d "${CONF_DIR}" ]; then
  cp -rf ${SOURCE_DIR} ${CONF_DIR}
fi
if [ ! -d "/storage/roms/savestates/psp/ppsspp-sa-vulkan" ]; then
  mkdir -p "/storage/roms/savestates/psp/ppsspp-sa-vulkan"
fi

# Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
ASKIP=$(get_setting auto_frame_skip "${PLATFORM}" "${GAME}")
FPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
IRES=$(get_setting internal_resolution "${PLATFORM}" "${GAME}")
SKIPB=$(get_setting skip_buffer_effects "${PLATFORM}" "${GAME}")
VSYNC=$(get_setting vsync "${PLATFORM}" "${GAME}")
CLOCK_SPEED=$(get_setting clock_speed "${PLATFORM}" "${GAME}")

CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
if [ "${CORES}" = "little" ]; then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
  EMUPERF="${FAST_CORES}"
else
  unset EMUPERF
fi

# Auto Frame Skip
if [ "${ASKIP}" = "0" ]; then
  sed -i '/^AutoFrameSkip =/c\AutoFrameSkip = False' ${CONF_DIR}/${PPSSPP_INI}
else
  sed -i '/AutoFrameSkip =/c\AutoFrameSkip = True' ${CONF_DIR}/${PPSSPP_INI}
fi

# Backend: este pacote e SEMPRE Vulkan (o binario forca, mas deixamos consistente na ini)
sed -i '/^GraphicsBackend =/c\GraphicsBackend = 3 (VULKAN)' ${CONF_DIR}/${PPSSPP_INI}

# Internal Resolution
case "${IRES}" in
  2) sed -i '/^InternalResolution/c\InternalResolution = 2' ${CONF_DIR}/${PPSSPP_INI} ;;
  3) sed -i '/^InternalResolution/c\InternalResolution = 3' ${CONF_DIR}/${PPSSPP_INI} ;;
  4) sed -i '/^InternalResolution/c\InternalResolution = 4' ${CONF_DIR}/${PPSSPP_INI} ;;
  *) sed -i '/^InternalResolution/c\InternalResolution = 1' ${CONF_DIR}/${PPSSPP_INI} ;;
esac

# Show FPS
if [ "${FPS}" = "1" ]; then
  sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 2' ${CONF_DIR}/${PPSSPP_INI}
else
  sed -i '/^iShowStatusFlags =/c\iShowStatusFlags = 0' ${CONF_DIR}/${PPSSPP_INI}
fi

# Skip Buffer Effects
if [ "${SKIPB}" = "1" ]; then
  sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = True' ${CONF_DIR}/${PPSSPP_INI}
else
  sed -i '/^SkipBufferEffects =/c\SkipBufferEffects = False' ${CONF_DIR}/${PPSSPP_INI}
fi

# VSYNC
if [ "${VSYNC}" = "1" ]; then
  sed -i '/^VSyncInterval =/c\VSyncInterval = True' ${CONF_DIR}/${PPSSPP_INI}
else
  sed -i '/^VSyncInterval =/c\VSyncInterval = False' ${CONF_DIR}/${PPSSPP_INI}
fi

# Clock Speed
case "${CLOCK_SPEED}" in
  222) sed -i '/^CPUSpeed =/c\CPUSpeed = 222' ${CONF_DIR}/${PPSSPP_INI} ;;
  333) sed -i '/^CPUSpeed =/c\CPUSpeed = 333' ${CONF_DIR}/${PPSSPP_INI} ;;
  *)   sed -i '/^CPUSpeed =/c\CPUSpeed = 0' ${CONF_DIR}/${PPSSPP_INI} ;;
esac

[ -x /usr/bin/cheevos_ppsspp.sh ] && /usr/bin/cheevos_ppsspp.sh

ARG=${1//[\\]/}
echo "Launching /usr/bin/ppsspp-vulkan ${ARG}"

# Amlogic-no (S905X5M, blob Mali Valhall + KMSDRM): a ponte Vulkan apresenta via page-flip
# por frame -> o emu thread soluca a alimentacao de audio -> XRUN do sink HDMI -> som some.
# Cura (igual ppsspp-sa GLES / dolphin doc 14): buffer grande no pipewire (~170ms) + ExtraAudioBuffering.
if [ "${HW_DEVICE}" = "Amlogic-no" ]; then
  export PIPEWIRE_LATENCY=8192/48000
  sed -i '/^ExtraAudioBuffering =/c\ExtraAudioBuffering = True' "${CONF_DIR}/${PPSSPP_INI}"
fi

# Watchdog de shutdown (mesmo do GLES): no Exit o ppsspp pode deadlockar liberando o GPU
# context (threads em futex_wait) -> processo nunca termina -> ES preso. Mede tempo de CPU
# (utime+stime); <=3 jiffies/s por 6s = deadlock -> SIGKILL (kernel fecha o DRM, ES reassume).
if [ "${HW_DEVICE}" = "Amlogic-no" ]; then
  ${EMUPERF} ppsspp-vulkan --pause-menu-exit "${ARG}" &
  PPID_=$!
  (
    stuck=0; last=-1
    while kill -0 "${PPID_}" 2>/dev/null; do
      sleep 1
      [ ! -r "/proc/${PPID_}/stat" ] && break
      st=$(cat /proc/"${PPID_}"/stat 2>/dev/null); st="${st#*) }"
      cur=$(echo "${st}" | awk '{print $12+$13}'); cur="${cur:-0}"
      if [ "${last}" != "-1" ]; then
        d=$(( cur - last )); [ "${d}" -lt 0 ] && d=0
        if [ "${d}" -le 3 ]; then
          stuck=$((stuck + 1))
          if [ "${stuck}" -ge 6 ]; then
            echo "[start_ppssppvulkan] shutdown deadlock (cpu parada ${stuck}s), SIGKILL pid=${PPID_}" >&2
            kill -9 "${PPID_}" 2>/dev/null; break
          fi
        else
          stuck=0
        fi
      fi
      last="${cur}"
    done
  ) &
  WPID=$!
  wait "${PPID_}"; RET=$?
  kill "${WPID}" 2>/dev/null
  exit "${RET}"
fi

${EMUPERF} ppsspp-vulkan --pause-menu-exit "${ARG}"
