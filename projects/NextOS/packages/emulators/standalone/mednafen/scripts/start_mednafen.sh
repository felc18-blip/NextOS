#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
. /etc/os-release

set -x
set_kill set "-9 mednafen"

export MEDNAFEN_HOME=/storage/.config/mednafen
export MEDNAFEN_CONFIG=/usr/config/mednafen/mednafen.template

if [ ! -d "$MEDNAFEN_HOME" ]
then
  mkdir /storage/.config/mednafen
fi

if [ ! -f "$MEDNAFEN_HOME/mednafen.cfg" ]
then
    /usr/bin/bash /usr/bin/mednafen_gen_config.sh
    # Amlogic-nxtos (Mali-450 Lima): video.* do mednafen.template envenena o
    # render via Wayland (mednafen abre janela, frames Wayland submitted, mas
    # textura sai 100% preta). Remover video.* faz mednafen cair nos defaults
    # built-in pra render — joystick mappings @DEVICE_BTN_*@ → button_N
    # ficam OK pra controle funcionar.
    if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
        sed -i '/^video\./d' "$MEDNAFEN_HOME/mednafen.cfg"
        # USB Gamepad genericos expoem dpad como HAT, e mednafen 1.32 cfg nao
        # tem syntax pra hat (so button_N / abs_N+-). gen_config fallback poe
        # button_99 (botao inexistente) = dpad morto. Sobrescrever os mappings
        # dpad pra teclas arrow (mednafen ja tem suporte built-in pra teclas),
        # e o gptokeyb daemon spawnado depois converte hat do gamepad → arrows.
        for CORE_CFG in md sms gg nes snes_faust gb gba pce_fast pcfx ngp wswan lynx ss psx vb; do
            for DIR in up down left right; do
                case $DIR in
                    up)    KEY=82 ;;  # USB HID scancode Arrow Up
                    down)  KEY=81 ;;  # Arrow Down
                    left)  KEY=80 ;;  # Arrow Left
                    right) KEY=79 ;;  # Arrow Right
                esac
                sed -i "s|^${CORE_CFG}\.input\.port1\.gamepad\.${DIR} .*|${CORE_CFG}.input.port1.gamepad.${DIR} keyboard 0x0 ${KEY}|" "$MEDNAFEN_HOME/mednafen.cfg"
            done
        done
    fi
fi

#Emulation Station Features
GAME=$(echo "${1}"| sed "s#^/.*/##")
CORE=$(echo "${2}"| sed "s#^/.*/##")
PLATFORM=$(echo "${3}"| sed "s#^/.*/##")
STRETCH=$(get_setting stretch "${PLATFORM}" "${GAME}")
SHADER=$(get_setting shader "${PLATFORM}" "${GAME}")

#Set the cores to use
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
FEATURES_CMDLINE=""

# Amlogic-nxtos: PipeWire (pipewire-pulse) ocupa /dev/snd; mednafen ALSA bate
# "Device or resource busy". Forcar SDL audio (negocia via pipewire-pulse).
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    export SDL_AUDIODRIVER=pulseaudio
    FEATURES_CMDLINE+=" -sound.driver sdl"
fi
if [ "${CORES}" = "little" ]
then
  EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]
then
  EMUPERF="${FAST_CORES}"
  if [ "${HW_DEVICE}" = "RK3588" ]; then
    FEATURES_CMDLINE+=" -affinity.emu 0x30 "
    FEATURES_CMDLINE+=" -ss.affinity.vdp2 0xc0 "
  elif [ "${HW_DEVICE}" = "RK3399" ]; then
    FEATURES_CMDLINE+=" -affinity.emu 0x10 "
    FEATURES_CMDLINE+=" -ss.affinity.vdp2 0x20 "
  fi
else
  ### All..
  unset EMUPERF
fi

#Set Save paths
sed -i "s/filesys.path_sav .*/filesys.path_sav \/storage\/roms\/${PLATFORM}/g" $MEDNAFEN_HOME/mednafen.cfg
sed -i "s/filesys.path_savbackup.*/filesys.path_savbackup \/storage\/roms\/${PLATFORM}/g" $MEDNAFEN_HOME/mednafen.cfg
sed -i "s/filesys.path_state.*/filesys.path_state \/storage\/roms\/savestates\/${PLATFORM}/g" $MEDNAFEN_HOME/mednafen.cfg

# Get command line switches
CORRECT_ASPECT=$(get_setting correct_aspect ${PLATFORM} "${GAME}")
CR=""
if [ ! -z "${CORRECT_ASPECT}" ] 
then
    CR=" -${CORE}.correct_aspect ${CORRECT_ASPECT}"
fi
if [[ "${CORE}" =~ pce[_fast] ]]
then
    if [ "$(get_setting nospritelimit ${PLATFORM} "${GAME}")" = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.nospritelimit 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.nospritelimit 0"
    fi
    if [ "$(get_setting forcesgx ${PLATFORM} "${GAME}")" = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.forcesgx 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.forcesgx 0"
    fi
    if [ "${CORE}" = pce_fast ]
    then
        FEATURES_CMDLINE+=$CR
        OCM=$(get_setting ocmultiplier ${PLATFORM} "${GAME}")
        if [ ${OCM} > 1 ]
        then
            FEATURES_CMDLINE+=" -${CORE}.ocmultiplier ${OCM}"
        else
            FEATURES_CMDLINE+=" -${CORE}.ocmultiplier 1"
        fi
        CDS=$(get_setting cdspeed ${PLATFORM} "${GAME}")
        if [ ${CDS} > 1 ]
        then
            FEATURES_CMDLINE+=" -${CORE}.cdspeed ${CDS}"
        else
            FEATURES_CMDLINE+=" -${CORE}.cdspeed 1"
        fi
    fi
elif [ "${CORE}" = "gb" ]
then
    ST=$(get_setting system_type "${PLATFORM}" "${GAME}")
    if [[ "${ST}" =~ auto|dmg|cgb|agb  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.system_type ${ST}"
    else
        FEATURES_CMDLINE+=" -${CORE}.system_type auto"
    fi
elif [ "${CORE}" = "gba" ]
then
    if [ $(get_setting tblur "${PLATFORM}" "${GAME}") = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.tblur 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.tblur 0"
    fi
elif [ "${CORE}" = "nes" ]
then
    FEATURES_CMDLINE+=$CR
    if [ $(get_setting clipsides "${PLATFORM}" "${GAME}") = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.clipsides 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.clipsides 0"
    fi
    if [ $(get_setting no8lim "${PLATFORM}" "${GAME}") = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.no8lim 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.no8lim 0"
    fi
elif [ "${CORE}" = "snes_faust" ]
then
    FEATURES_CMDLINE+=$CR
    if [ $(get_setting spex "${PLATFORM}" "${GAME}") = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.spex 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.spex 0"
    fi
    if [ $(get_setting spex.sound "${PLATFORM}" "${GAME}") = "1" ]
    then
        FEATURES_CMDLINE+=" -${CORE}.spex.sound 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.spex.sound 0"
    fi
    SFXCR=$(get_setting superfx.clock_rate ${PLATFORM} "${GAME}")
    if [ ${SFXCR} > 1 ]
    then
        FEATURES_CMDLINE+=" -${CORE}.superfx.clock_rate ${SFXCR}"
    else
        FEATURES_CMDLINE+=" -${CORE}.superfx.clock_rate 100"
    fi
    if [[ "$(get_setting superfx.icache ${PLATFORM} "${GAME}")" == "1" ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.superfx.icache 1"
    else
        FEATURES_CMDLINE+=" -${CORE}.superfx.icache 0"
    fi
    CX4CR=$(get_setting cx4.clock_rate ${PLATFORM} "${GAME}")
    if [ ${CX4CR} > 1 ]
    then
        FEATURES_CMDLINE+=" -${CORE}.cx4.clock_rate ${CX4CR}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cx4.clock_rate 100"
    fi
elif [ "${CORE}" = "vb" ]
then
    CE=$(get_setting cpu_emulation "${PLATFORM}" "${GAME}")
    if [[ "${CE}" =~ fast|accurate  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.cpu_emulation ${CE}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cpu_emulation fast"
    fi
    DM=$(get_setting 3dmode "${PLATFORM}" "${GAME}")
    if [[ "${DM}" =~ anaglyph|cscope|sidebyside|vli|hli|left|right]  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.3dmode ${CE}"
    fi
elif [ "${CORE}" = "pcfx" ]
then
    CE=$(get_setting cpu_emulation "${PLATFORM}" "${GAME}")
    if [[ "${CE}" =~ auto|fast|accurate  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.cpu_emulation ${CE}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cpu_emulation auto"
    fi
    CS=$(get_setting cdspeed "${PLATFORM}" "${GAME}")
    if [ CS > 2]
    then
        FEATURES_CMDLINE+=" -${CORE}.cdspeed ${CS}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cdspeed 2"
    fi
elif [ "${CORE}" = "ss" ]
then
    FEATURES_CMDLINE+=$CR
    IP1=$(get_setting input.port1 "${PLATFORM}" "${GAME}")
    if [[ "${IP1}" =~ gamepad|3dpad|gun  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.input.port1 ${IP1}"
    else
        FEATURES_CMDLINE+=" -${CORE}.input.port1 gamepad"
    fi
    IP13DMODE=$(get_setting input.port1.3dpad.mode.defpos "${PLATFORM}" "${GAME}")
    if [[ "${IP13DMODE}" =~ digital|analog  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.input.port1.3dpad.mode.defpos ${IP13DMODE}"
    else
        FEATURES_CMDLINE+=" -${CORE}.input.port1.3dpad.mode.defpos analog"
    fi
    CART=$(get_setting cart "${PLATFORM}" "${GAME}")
    if [[ "${CART}" =~ auto|none|backup|extram1|extram4|cs1ram16  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.cart ${CART}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cart auto"
    fi
    CARTAD=$(get_setting cart.auto_default "${PLATFORM}" "${GAME}")
    if [[ "${CARTAD}" =~ none|backup|extram1|extram4|cs1ram16  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.cart.auto_default ${CARTAD}"
    else
        FEATURES_CMDLINE+=" -${CORE}.cart.auto_default none"
    fi
elif [ "${CORE}" = "md" ]
then
    FEATURES_CMDLINE+=$CR
elif [ "${CORE}" = "psx" ]
then
    FEATURES_CMDLINE+=$CR
    IP1=$(get_setting input.port1 "${PLATFORM}" "${GAME}")
    if [[ "${IP1}" =~ gamepad|dualshock  ]]
    then
        FEATURES_CMDLINE+=" -${CORE}.input.port1 ${IP1}"
    else
        FEATURES_CMDLINE+=" -${CORE}.input.port1 gamepad"
    fi
fi

# Amlogic-nxtos: spawn gptokeyb SO pra dpad → arrows (mednafen.cfg ja foi
# patchado pra dpad=keyboard arrows acima). Sem isso, USB Gamepad hat fica morto.
# Trap pra matar gptokeyb + show_splash quando mednafen sair.
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ] && [ -x /usr/bin/gptokeyb ]; then
    cat > /tmp/mednafen-dpad.gptk << 'GPTK'
up    = up
down  = down
left  = left
right = right
GPTK
    pkill -9 -f "gptokeyb.*mednafen" 2>/dev/null
    env -u EMUELEC /usr/bin/gptokeyb 1 mednafen -c /tmp/mednafen-dpad.gptk &
    sleep 0.3
    trap 'pkill -9 -f "gptokeyb.*mednafen" 2>/dev/null; pkill -9 -f "show_splash.sh exit" 2>/dev/null; true' EXIT INT TERM HUP
fi

# Amlogic-nxtos: mednafen 1.32 nativamente le zip/gz/bz2 + raw, mas NAO 7z.
# Extrair .7z pra /tmp/ e passar arquivo cru pro mednafen. Cleanup em trap.
ROM_FOR_MEDNAFEN="${1}"
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ] && [[ "${1,,}" == *.7z ]]; then
    EXTRACT_DIR="/tmp/mednafen-rom-$$"
    mkdir -p "${EXTRACT_DIR}"
    /usr/bin/7zr e -y -o"${EXTRACT_DIR}" "${1}" >/dev/null 2>&1
    EXTRACTED="$(find "${EXTRACT_DIR}" -type f | head -1)"
    if [ -n "${EXTRACTED}" ]; then
        ROM_FOR_MEDNAFEN="${EXTRACTED}"
        # Cleanup extra-dir junto com gptokeyb na saida
        if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
            trap 'pkill -9 -f "gptokeyb.*mednafen" 2>/dev/null; pkill -9 -f "show_splash.sh exit" 2>/dev/null; rm -rf "'"${EXTRACT_DIR}"'"; true' EXIT INT TERM HUP
        fi
    fi
fi

# Amlogic-nxtos: forcar fullscreen via cmdline (cfg video.* foi removido pra
# nao envenenar render no Mali-450 Lima, daí mednafen default = window 876x672).
# stretch=full preenche os 1280x720 (16:9).
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    FEATURES_CMDLINE+=" -fs 1"
    STRETCH="${STRETCH:-full}"
fi

#Run mednafen
${EMUPERF} /usr/bin/mednafen -force_module ${CORE} -${CORE}.stretch ${STRETCH:="aspect"} -${CORE}.shader ${SHADER:="ipsharper"} ${FEATURES_CMDLINE} "${ROM_FOR_MEDNAFEN}"
