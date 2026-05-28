#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
set_kill set "-9 flycast"

#load gptokeyb support files
control-gen_init.sh
source /storage/.config/gptokeyb/control.ini
get_controls

# Conf files vars
SOURCE_DIR="/usr/config/flycast"
CONF_DIR="/storage/.config/flycast"
FLYCAST_INI="emu.cfg"

#Check if flycast exists in .config
if [ ! -d "/storage/.config/flycast" ]; then
  cp -r "${SOURCE_DIR}" "${CONF_DIR}"
fi

#Move save file storage/roms
if [ -d "${CONF_DIR}/data" ]; then
  mv "${CONF_DIR}/data" "/storage/roms/dreamcast/"
fi

#Make flycast bios folder
if [ ! -d "/storage/roms/bios/dc" ]; then
  mkdir -p "/storage/roms/bios/dc"
fi

#Link  .config/flycast to .local
ln -sf "/storage/roms/bios/dc" "/storage/roms/dreamcast/data"


#Make sure flycast gptk config exists
if [ ! -f "${CONF_DIR}/flycast.gptk" ]; then
  cp -r "/usr/config/flycast/flycast.gptk" "${CONF_DIR}/flycast.gptk"
fi

#Make sure flycast gptk SDL_Keyboard.cfg exists
if [ ! -f "${CONF_DIR}/mappings/SDL_Keyboard.cfg" ]; then
  cp -r "/usr/config/flycast/mappings/SDL_Keyboard.cfg" "${CONF_DIR}/mappings/SDL_Keyboard.cfg"
fi

#Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
ASPECT=$(get_setting aspect_ratio "${PLATFORM}" "${GAME}")
ASKIP=$(get_setting auto_frame_skip "${PLATFORM}" "${GAME}")
FPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
IRES=$(get_setting internal_resolution "${PLATFORM}" "${GAME}")
GRENDERER=$(get_setting graphics_backend "${PLATFORM}" "${GAME}")
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

  #AspectRatio
        if [ "$ASPECT" = "w" ]; then
                sed -i '/^rend.WideScreen =/c\rend.WideScreen = yes' "${CONF_DIR}/${FLYCAST_INI}"
                sed -i '/^rend.SuperWideScreen =/c\rend.SuperWideScreen = no' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$ASPECT" = "sw" ]; then
                sed -i '/^rend.WideScreen =/c\rend.WideScreen = yes' "${CONF_DIR}/${FLYCAST_INI}"
                sed -i '/^rend.SuperWideScreen =/c\rend.SuperWideScreen = yes' "${CONF_DIR}/${FLYCAST_INI}"
	else
		sed -i '/^rend.WideScreen =/c\rend.WideScreen = no' "${CONF_DIR}/${FLYCAST_INI}"
		sed -i '/^rend.SuperWideScreen =/c\rend.SuperWideScreen = no' "${CONF_DIR}/${FLYCAST_INI}"
        fi

  #AutoFrameSkip
        if [ "$ASKIP" = "normal" ]; then
                sed -i '/^pvr.AutoSkipFrame =/c\pvr.AutoSkipFrame = 1' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$ASKIP" = "max" ]; then
                sed -i '/^pvr.AutoSkipFrame =/c\pvr.AutoSkipFrame = 2' "${CONF_DIR}/${FLYCAST_INI}"
	else
		sed -i '/^pvr.AutoSkipFrame =/c\pvr.AutoSkipFrame = 0' "${CONF_DIR}/${FLYCAST_INI}"
        fi

  #Internal Resolution
        if [ "$IRES" = "0" ]; then
                sed -i '/rend.Resolution =/c\rend.Resolution = 240' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$IRES" = "2" ]; then
                sed -i '/rend.Resolution =/c\rend.Resolution = 720' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$IRES" = "3" ]; then
                sed -i '/rend.Resolution =/c\rend.Resolution = 960' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$IRES" = "4" ]; then
                sed -i '/rend.Resolution =/c\rend.Resolution = 1200' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$IRES" = "5" ]; then
                sed -i '/rend.Resolution =/c\rend.Resolution = 1440' "${CONF_DIR}/${FLYCAST_INI}"
        else
                sed -i '/rend.Resolution =/c\rend.Resolution = 480' "${CONF_DIR}/${FLYCAST_INI}"
        fi

  #Graphics Renderer
        if [ "$GRENDERER" = "opengl" ]; then
                sed -i '/^pvr.rend =/c\pvr.rend = 0' "${CONF_DIR}/${FLYCAST_INI}"
        elif [ "$GRENDERER" = "vulkan" ]; then
                sed -i '/^pvr.rend =/c\pvr.rend = 4' "${CONF_DIR}/${FLYCAST_INI}"
        else
		sed -i '/^pvr.rend =/c\pvr.rend = @GRENDERER@' "${CONF_DIR}/${FLYCAST_INI}"
	fi

  #ShowFPS
        if [ "$FPS" = "1" ]; then
                sed -i '/^rend.ShowFPS =/c\rend.ShowFPS = yes' "${CONF_DIR}/${FLYCAST_INI}"
	else
		sed -i '/^rend.ShowFPS =/c\rend.ShowFPS = no' "${CONF_DIR}/${FLYCAST_INI}"
        fi

  #Vsync
        if [ "$VSYNC" = "1" ];then
                sed -i '/^rend.vsync =/c\rend.vsync = yes' "${CONF_DIR}/${FLYCAST_INI}"
	else
		sed -i '/^rend.vsync =/c\rend.vsync = no' "${CONF_DIR}/${FLYCAST_INI}"
        fi

#Retroachievements
/usr/bin/cheevos_flycast.sh

# Debugging info:
  echo "GAME set to: ${GAME}"
  echo "PLATFORM set to: ${PLATFORM}"
  echo "CONF DIR: ${CONF_DIR}/${FLYCAST_INI}"
  echo "CPU CORES set to: ${EMUPERF}"
  echo "ASPECT RATIO set to: ${ASPECT}"
  echo "AUTO FRAME SKIP set to: ${ASKIP}"
  echo "INTERNAL RESOLUTION set to: ${IRES}"
  echo "GRAPHICS RENDERER set to: ${GRENDERER}"
  echo "FPS set to: ${FPS}"
  echo "VSYNC set to: ${VSYNC}"
  echo "Launching /usr/bin/flycast ${1}"

# Mesa Lima (Mali-450 Utgard) on Amlogic-nxtos. NUNCA exportar PAN_MESA_DEBUG
# nem MESA_NO_ERROR aqui — esses sao especificos do driver Panfrost (Bifrost+)
# e quebram a inicializacao de EGL context no Lima (OpenGL ES version reporta
# 0.0 e o emulador crasha SIGSEGV ~2s depois do "Game ID is" / SDL gamepad reset).
# Mesa GLTHREAD nao ajuda Lima single-threaded.

# Video driver depende do device:
# - Amlogic-no (X5M Valhall G310 KMSDRM-direto): SDL2 = kmsdrm. Launch via
#   nextos_kmsdrm_launch helper que isola flycast num service systemd-run
#   (para essway pra liberar refs do blob libMali no card0).
#   LD_PRELOAD: flycast NAO linka libwayland-client/server/libGLESv2 direto
#   (resolve runtime via dlopen). Sem essas refs no load, o blob libMali
#   inicializa EGL parcialmente — page-flip pro HDMI nunca acontece (tela
#   preta apesar do glBlitFramebuffer test passar). AC GC linka explicito
#   por isso roda OK. LD_PRELOAD forca o load no inicio = blob feliz.
# - Outros (Amlogic-nxtos sway, etc): wayland legado.
if [ "${HW_DEVICE}" = "Amlogic-no" ]; then
    export SDL_VIDEODRIVER=kmsdrm
    export SDL_KMSDRM_VSYNC_DEFAULT=1
    export LD_PRELOAD="/usr/lib/libwayland-client.so.0 /usr/lib/libwayland-server.so.0 /usr/lib/libGLESv2.so.2"
    exec /usr/bin/nextos_kmsdrm_launch.sh /usr/bin/flycast "${1}"
fi

export SDL_VIDEODRIVER=wayland

#Run flycast emulator — spawn gptokeyb com delay de 3s. Subindo antes do flycast
#a politica de input do SDL2 (gamecontroller hot-plug) entra em race com o joystick
#virtual do gptokeyb e o flycast crasha no SDL init.
( sleep 3 && $GPTOKEYB "flycast" -c "${CONF_DIR}/flycast.gptk" ) &
${EMUPERF} /usr/bin/flycast "${1}"
_gptokeyb_pid="$(pidof gptokeyb 2>/dev/null)"
[ -n "${_gptokeyb_pid}" ] && kill -9 ${_gptokeyb_pid}
