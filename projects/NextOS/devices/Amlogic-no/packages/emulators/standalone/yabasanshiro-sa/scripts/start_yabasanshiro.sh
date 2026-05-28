#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

# Source predefined functions and variables
. /etc/profile
set_kill set "-9 yabasanshiro"

ROM_DIR="/storage/roms/saturn/yabasanshiro"
CONFIG_DIR="/storage/.config/yabasanshiro"
SOURCE_DIR="/usr/config/yabasanshiro"
BIOS_BACKUP="/storage/roms/bios/yabasanshiro"
SAVESTATE_DIR="/storage/roms/savestates/saturn/yabasanshiro/"

if [ ! -d "${ROM_DIR}" ]
then
  mkdir -p "${ROM_DIR}"
fi

if [ ! -d "${BIOS_BACKUP}" ]
then
  mkdir -p "${BIOS_BACKUP}"
fi

if [ ! -d "${CONFIG_DIR}" ]
then
  mkdir -p "${CONFIG_DIR}"
fi

if [ ! -d "${SAVESTATE_DIR}" ]
then
  mkdir -p "${SAVESTATE_DIR}"
fi

# NextOS: sempre regenerar input.cfg do es_input.cfg atual. O upstream Arch-R
# faz so se input.cfg nao existe — mas se o usuario troca controle, input.cfg
# fica desatualizado e yabasanshiro carrega keymap antigo (botoes nao funcionam).
# Detecta deviceGUID atual vs o salvo em keymapv2.json: se diferente, apaga
# keymapv2 pra yaba recriar com mapping do controle novo.

# Handle inputplumber platforms first
if [[ "${HW_DEVICE}" =~ SM8550|SM8650 ]]; then
  GAMEPAD="'InputPlumber GameController'"
else
  # Check for js0, else fall back to joypad
  if grep -q "js0" /proc/bus/input/devices; then
    GAMEPAD="'$(grep -b4 js0 /proc/bus/input/devices | awk 'BEGIN {FS="\""}; /Name/ {printf $2}')'"
  else
    GAMEPAD="'$(grep -b4 joypad /proc/bus/input/devices | awk 'BEGIN {FS="\""}; /Name/ {printf $2}')'"
  fi
fi

GAMEPADCONFIG=$(xmlstarlet sel -t -c "//inputList/inputConfig[@deviceName=${GAMEPAD}]" -n /storage/.emulationstation/es_input.cfg)

# Sempre regenera input.cfg refletindo es_input.cfg atual
if [ ! -z "${GAMEPADCONFIG}" ]
then
  cat <<EOF >${CONFIG_DIR}/input.cfg
<?xml version="1.0"?>
<inputList>
${GAMEPADCONFIG}
</inputList>
EOF
fi

# Detecta troca de controle: pega deviceGUID atual do es_input.cfg e do
# keymapv2.json. Se diferente, apaga keymapv2 (yaba recria do input.cfg).
NEW_GUID=$(echo "${GAMEPADCONFIG}" | grep -oE 'deviceGUID="[^"]+"' | head -1 | sed 's/deviceGUID="\(.*\)"/\1/')
if [ -e "${CONFIG_DIR}/keymapv2.json" ] && [ -n "${NEW_GUID}" ]; then
  OLD_GUID=$(grep -oE '"deviceGUID": "[^"]+"' "${CONFIG_DIR}/keymapv2.json" 2>/dev/null | head -1 | sed 's/"deviceGUID": "\(.*\)"/\1/')
  if [ "${NEW_GUID}" != "${OLD_GUID}" ]; then
    echo "Yabasanshiro: controle mudou (${OLD_GUID} -> ${NEW_GUID}), regerando keymapv2"
    rm -f "${CONFIG_DIR}/keymapv2.json"
  fi
fi

# Pre-mapping conhecido (override): se /usr/config tem keymapv2_<gamepad>.json,
# usa como base (assim controles testados ja vem com mapping correto)
MAPPING_FILE="/usr/config/yabasanshiro/devices/keymapv2_$(eval echo $GAMEPAD).json"
if [ -e "${MAPPING_FILE}" ] && [ ! -e "${CONFIG_DIR}/keymapv2.json" ]; then
  cp "${MAPPING_FILE}" "${CONFIG_DIR}/keymapv2.json"
fi

BIOS=""
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
USE_BIOS=$(get_setting use_hlebios "${PLATFORM}" "${GAME}")
if [ ! "${USE_BIOS}" = 1 ]
then
  USE_BIOS=$(get_setting use_hlebios "${PLATFORM}")
fi

if [ "$USE_BIOS" = 1 ]
then
  for BIOS in saturn_bios.bin sega_101.bin mpr-17933.bin mpr-18811-mx.ic1 mpr-19367-mx.ic1 stvbios.zip
  do
    BIOS=$(find /storage/roms/bios -name ${BIOS} -print 2>/dev/null)
    if [ ! -z "${BIOS}" ]
    then
      BIOS="-b ${BIOS}"
      break
    fi
  done
fi

if [ ! -e "${CONFIG_DIR}/${GAME}.config" ]
then
  cp -f ${SOURCE_DIR}/.config "${CONFIG_DIR}/${GAME}.config"
fi

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
if [ "${CORES}" = "little" ]
then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]
then
  EMUPERF="${FAST_CORES}"
else
  ### All..
  unset EMUPERF
fi

echo "Command: yabasanshiro -r 2 -i "${1}" ${BIOS}" >>/var/log/exec.log 2>&1

# Amlogic-no (X5M Valhall G310 KMSDRM-direto): isolar via systemd-run igual
# flycast-sa. Blob libMali do ES segura refs no card0 mesmo apos SDL_Quit;
# helper para essway, roda yabasanshiro standalone num service novo,
# restaura essway no exit. yabasanshiro JA linka libwayland-client/server
# direto entao nao precisa LD_PRELOAD como o flycast.
if [ "${HW_DEVICE}" = "Amlogic-no" ]; then
    export SDL_VIDEODRIVER=kmsdrm
    export SDL_KMSDRM_VSYNC_DEFAULT=1
    exec /usr/bin/nextos_kmsdrm_launch.sh /usr/bin/yabasanshiro -r 2 -i "${1}" ${BIOS}
fi

${EMUPERF} yabasanshiro -r 2 -i "${1}" ${BIOS} >>/var/log/exec.log 2>&1 ||:
