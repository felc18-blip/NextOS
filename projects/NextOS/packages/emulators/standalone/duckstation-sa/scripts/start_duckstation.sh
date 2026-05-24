#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
set_kill set "-9 AppRun.wrapped"

# Filesystem vars
IMMUTABLE_CONF_DIR="/usr/config/duckstation"
IMMUTABLE_CONF_FILE="${IMMUTABLE_CONF_DIR}/settings.ini"
APPIMAGE_CONF_DIR="/storage/.local/share/duckstation"
CONF_DIR="/storage/.config/duckstation"
CONF_FILE="${CONF_DIR}/settings.ini"
SAVESTATES_DIR="/storage/roms/savestates/psx"
MEMCARDS_DIR="/storage/roms/psx/duckstation/memcards"

#Init config dir if required
[ ! -d "${CONF_DIR}" ] && cp -r "${IMMUTABLE_CONF_DIR}" /storage/.config

#Init config file if required
[ ! -f "${CONF_FILE}" ] && cp ${IMMUTABLE_CONF_FILE} ${CONF_FILE}

#Link config dir to where appimage can find it
mkdir -p /storage/.local/share
rm -rf "${APPIMAGE_CONF_DIR}"
ln -sfv "${CONF_DIR}" "${APPIMAGE_CONF_DIR}"

#Link savestates to roms/savestates
[ ! -d "${SAVESTATES_DIR}" ] && mkdir -p "${SAVESTATES_DIR}"
[ -d "${CONF_DIR}/savestates" ] && rm -rf "${CONF_DIR}/savestates"
ln -sfv "${SAVESTATES_DIR}" "${CONF_DIR}/savestates"

# Link memcards to roms
if [ ! -d "${MEMCARDS_DIR}" ]; then
    mkdir -p ${MEMCARDS_DIR}

    # Migrate any existing memcards
    if [ -d "${CONF_DIR}/memcards" ]; then
        cp -rf ${CONF_DIR}/memcards/* ${MEMCARDS_DIR}
    fi
fi

[ -d "${CONF_DIR}/memcards" ] && rm -rf ${CONF_DIR}/memcards
ln -sfv ${MEMCARDS_DIR} ${CONF_DIR}/memcards

#Link gamecontrollerdb.txt
ln -sf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt "${CONF_DIR}/gamecontrollerdb.txt"

#Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
ASPECT=$(get_setting aspect_ratio "${PLATFORM}" "${GAME}")
FPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
IRES=$(get_setting internal_resolution "${PLATFORM}" "${GAME}")
RENDERER=$(get_setting graphics_backend "${PLATFORM}" "${GAME}")
VSYNC=$(get_setting vsync "${PLATFORM}" "${GAME}")

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

  #Aspect Ratio
  if [ "$ASPECT" = "1" ]; then
    sed -i '/^AspectRatio/c\AspectRatio = 16:9' ${CONF_FILE}
  elif [ "$ASPECT" = "2" ]; then
    sed -i '/^AspectRatio/c\AspectRatio = Stretch To Fill' ${CONF_FILE}
  else
    #Default to 4:3 aspect ratio
    sed -i '/^AspectRatio/c\AspectRatio = 4:3' ${CONF_FILE}
  fi

  #Show FPS
  if [ "$FPS" = "true" ]; then
    sed -i '/^ShowFPS/c\ShowFPS = true' ${CONF_FILE}
  else
    #Default to not show FPS
    sed -i '/^ShowFPS/c\ShowFPS = false' ${CONF_FILE}
  fi

  #Internal Resolution
  if [ "$IRES" = "2" ]; then
    sed -i '/^ResolutionScale =/c\ResolutionScale = 2' ${CONF_FILE}
  elif [ "$IRES" = "3" ]; then
    sed -i '/^ResolutionScale =/c\ResolutionScale = 3' ${CONF_FILE}
  elif [ "$IRES" = "4" ]; then
    sed -i '/^ResolutionScale =/c\ResolutionScale = 4' ${CONF_FILE}
  elif [ "$IRES" = "5" ]; then
    sed -i '/^ResolutionScale =/c\ResolutionScale = 5' ${CONF_FILE}
  else
    #Default to native resolution
    sed -i '/^ResolutionScale =/c\ResolutionScale = 1' ${CONF_FILE}
  fi

  #Video Backend
	if [ "$RENDERER" = "opengl" ]; then
    sed -i '/^Renderer =/c\Renderer = OpenGL' ${CONF_FILE}
  elif [ "$RENDERER" = "vulkan" ]; then
    sed -i '/^Renderer =/c\Renderer = Vulkan' ${CONF_FILE}
  else
    #Default to software renderer
    sed -i '/^Renderer =/c\Renderer = Software' ${CONF_FILE}
  fi

  #VSYNC
  if [ "$VSYNC" = "off" ]; then
    sed -i '/^VSync =/c\VSync = false' ${CONF_FILE}
  else
    #Default to vsync on
    sed -i '/^VSync =/c\VSync = true' ${CONF_FILE}
  fi

#Retroachievements
# Disabled, not working. Seems like Duckstation changed the token encruption...
# /usr/bin/cheevos_duckstation.sh
sed -i '/\[Cheevos\]/,/^\s*$/s/Enabled =.*/Enabled = false/' ${CONF_FILE}


# Mesa Lima (Mali-450) — sem PAN_MESA_DEBUG/MESA_NO_ERROR (driver Panfrost
# quebra EGL init no Lima e duckstation crasha SIGSEGV no SDL boot).

# NextOS Amlogic-nxtos: SDL precisa explicitamente video=wayland +
# audio=pulseaudio. Sem isso SDL2 tenta KMSDRM/X11/ALSA e bate com sway
# compositor / PipeWire → SDL_Init falha silente, duckstation crasha
# no boot sem chegar a abrir janela. Mesmo padrao yabasanshiro/mednafen/
# bigpemu/biginstinct standalone em Mali-450.
if echo "${HW_DEVICE}" | grep -q "Amlogic-nxtos"; then
  export SDL_VIDEODRIVER=wayland
  export SDL_AUDIODRIVER=pulseaudio
fi

#Run Duckstation (NoGUI build, SDL2+EGL+Wayland)
# stderr agora vai pra exec.log (não /dev/null) pra debug de crash.
${EMUPERF} duckstation-nogui -fullscreen -bigpicture -nogui -- "${1}" > /dev/null 2>>/var/log/exec.log
