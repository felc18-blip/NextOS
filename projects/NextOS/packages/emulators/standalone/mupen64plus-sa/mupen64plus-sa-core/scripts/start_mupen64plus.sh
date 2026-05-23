#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present 351ELEC (https://github.com/351ELEC)
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile

set_kill set "-9 mupen64plus"

# Emulation Station features
GAME=$(echo "${1}"| sed "s#^/.*/##")
PLATFORM=$(echo "${2}"| sed "s#^/.*/##")
SCREENWIDTH=$(fbwidth)
SCREENHEIGHT=$(fbheight)
ASPECT=$(get_setting game_aspect_ratio "${PLATFORM}" "${GAME}")
IRES=$(get_setting internal_resolution "${PLATFORM}" "${GAME}")
RSP=$(get_setting rsp_plugin "${PLATFORM}" "${GAME}")
SIMPLECORE=$(get_setting core_plugin "${PLATFORM}" "${GAME}")
FPS=$(get_setting show_fps "${PLATFORM}" "${GAME}")
PAK=$(get_setting controller_pak "${PLATFORM}" "${GAME}")
CON=$(get_setting input_configuration "${PLATFORM}" "${GAME}")
VPLUGIN=$(get_setting video_plugin "${PLATFORM}" "${GAME}")
CORES=$(get_setting "cores" "${PLATFORM}" "${GAME}")
GLIDEN64CONF=$(get_setting gliden64_profiles "${PLATFORM}" "${GAME}")

# File locations
SHARE="/usr/local/share/mupen64plus"
GAMEDATA="/storage/.config/mupen64plus"
M64PCONF="${GAMEDATA}/mupen64plus.cfg"
CUSTOMINP="${GAMEDATA}/custominput.ini"
TMP="/tmp/mupen64plus"

# Clean and create directories
rm -rf ${TMP}
mkdir -p ${TMP}
mkdir -p ${GAMEDATA}

# Copy files to GAMEDATA
if [[ ! -f "${M64PCONF}" ]]; then
    cp ${SHARE}/mupen64plus.cfg* ${GAMEDATA}
fi
if [[ ! -f "${CUSTOMINP}" ]]; then
    cp ${SHARE}/default.ini ${CUSTOMINP}
fi

# Copy files to TMP
cp ${M64PCONF} ${TMP}

# Amlogic-nxtos: setar Joy Mapping Stop = Select+Start (B8+B9 do USB Gamepad)
# em vez do default J0B7/B6 (R2+L2) — convencao Black Retro mata-jogo +
# bate com gptokeyb dos outros emus. Aplicar tanto no M64PCONF (persistido)
# quanto na copia /tmp pra valer no launch atual.
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    sed -i 's|^Joy Mapping Stop = .*|Joy Mapping Stop = "J0B8/B9"|' "${M64PCONF}" "${TMP}/mupen64plus.cfg"
fi

if [ "${CON}" = "custom" ]; then
    cp ${CUSTOMINP} ${TMP}/InputAutoCfg.ini
elif [ "${CON}" = "standard" ]; then
    cp ${SHARE}/default.ini ${TMP}/InputAutoCfg.ini
else
    cp ${SHARE}/default.ini ${TMP}/InputAutoCfg.ini
fi

# Amlogic-nxtos: tradutor SDL_GameControllerDB → InputAutoCfg.ini do mupen.
# USB Gamepad genericos nao tem entry em default.ini, mupen tenta auto-config,
# nao acha e crasha SIGSEGV no input init. Adicionar entry derivada de
# /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt no momento do
# launch, ate 4 controles. Logica portada do NextOS_Staging IMAGEM BASE
# backup (mupen64plus-sa-nextos-backup-20260425).
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    SDL_DB="/storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt"
    CONNECTED_PADS=$(awk '/^N: Name="/ {name=$0; sub(/N: Name="/, "", name); sub(/"$/, "", name)} /^H: Handlers=.*js[0-9]+/ {print name}' /proc/bus/input/devices)
    if [ -f "$SDL_DB" ] && [ -n "$CONNECTED_PADS" ]; then
        INJECTED="${TMP}/injected_pads.txt"
        touch "$INJECTED"
        while IFS= read -r raw_name; do
            [ -z "$raw_name" ] && continue
            dev_name=$(echo "$raw_name" | sed 's/^ *//;s/ *$//' | tr -s ' ')
            grep -q -F "$dev_name" "$INJECTED" && continue
            grep -q -F "[$dev_name]" "${TMP}/InputAutoCfg.ini" && { echo "$dev_name" >> "$INJECTED"; continue; }
            SDL_LINE=$(grep -F ",${dev_name}," "$SDL_DB" | head -n1)
            [ -z "$SDL_LINE" ] && continue
            M_A=""; M_B=""; M_S=""; M_Z=""; M_L=""; M_R=""; M_X=""; M_Y=""
            M_CR=""; M_CL=""; M_CD=""; M_CU=""
            M_DPR=""; M_DPL=""; M_DPD=""; M_DPU=""
            IFS=',' read -ra PARTS <<< "$SDL_LINE"
            for part in "${PARTS[@]}"; do
                key="${part%%:*}"
                val="${part#*:}"
                m_val=""
                if   [[ "$val" == b* ]];    then m_val="button(${val:1})"
                elif [[ "$val" == h0.1 ]];  then m_val="hat(0 Up)"
                elif [[ "$val" == h0.2 ]];  then m_val="hat(0 Right)"
                elif [[ "$val" == h0.4 ]];  then m_val="hat(0 Down)"
                elif [[ "$val" == h0.8 ]];  then m_val="hat(0 Left)"
                elif [[ "$val" == a* ]];    then m_val="axis(${val:1}+)"
                fi
                case "$key" in
                    a)             M_A="$m_val" ;;
                    b|x)           [ -z "$M_B" ] && M_B="$m_val" ;;
                    start)         M_S="$m_val" ;;
                    leftshoulder)  M_L="$m_val" ;;
                    rightshoulder) M_R="$m_val" ;;
                    lefttrigger)   M_Z="$m_val" ;;
                    dpup)          M_DPU="$m_val" ;;
                    dpdown)        M_DPD="$m_val" ;;
                    dpleft)        M_DPL="$m_val" ;;
                    dpright)       M_DPR="$m_val" ;;
                    leftx)         M_X="axis(${val:1}-,${val:1}+)" ;;
                    lefty)         M_Y="axis(${val:1}-,${val:1}+)" ;;
                    rightx)        M_CR="axis(${val:1}+)"; M_CL="axis(${val:1}-)" ;;
                    righty)        M_CD="axis(${val:1}+)"; M_CU="axis(${val:1}-)" ;;
                esac
            done
            cat >> "${TMP}/InputAutoCfg.ini" <<EOT

[$dev_name]
plugged = True
plugin = 2
mouse = False
DPad R = $M_DPR
DPad L = $M_DPL
DPad D = $M_DPD
DPad U = $M_DPU
Start = $M_S
Z Trig = $M_Z
B Button = $M_B
A Button = $M_A
R Trig = $M_R
L Trig = $M_L
C Button R = $M_CR
C Button L = $M_CL
C Button D = $M_CD
C Button U = $M_CU
X Axis = $M_X
Y Axis = $M_Y
EOT
            echo "$dev_name" >> "$INJECTED"
        done <<< "$CONNECTED_PADS"
    fi
fi
if [ $(echo $1 | grep -i .zip | wc -l) -eq 1 ]; then
    # Unzip the game ROM if needed
    unzip -q -o "$1" -d ${TMP}
    # BusyBox unzip (que e o que esta no rootfs) NAO tem o flag "-Z" do Info-ZIP,
    # entao listar conteudo do zip dessa forma falhava silenciosamente e $ROM
    # ficava vazio → mupen tentava abrir o diretorio TMP em vez do ROM real.
    # Pegar o primeiro .z64/.n64/.v64 do TMP pos-extract resolve sem precisar
    # do Info-ZIP.
    ROM=$(basename "$(ls "${TMP}"/*.z64 "${TMP}"/*.n64 "${TMP}"/*.v64 2>/dev/null | head -1)")
elif [ $(echo $1 | grep -i .7z | wc -l) -eq 1 ]; then
    # 7z extraction via 7zr (mupen64plus nao le 7z nativo).
    /usr/bin/7zr e -y -o"${TMP}" "$1" >/dev/null 2>&1
    ROM=$(basename "$(ls "${TMP}"/*.z64 "${TMP}"/*.n64 "${TMP}"/*.v64 2>/dev/null | head -1)")
else
    cp "$1" ${TMP}
    ROM="${GAME}"
fi

# CPU core settings
if [ "${CORES}" = "little" ]; then
    EMUPERF="${SLOW_CORES}"
elif [ "${CORES}" = "big" ]; then
    EMUPERF="${FAST_CORES}"
else
    unset EMUPERF
fi

# Configure Mupen64Plus-SA parameters
SET_PARAMS=""

# Emulator core settings
SET_PARAMS+=" --set Core[SharedDataPath]=${TMP}"
if [ "${SIMPLECORE}" = "simple" ]; then
    SIMPLESUFFIX="-simple"
    SET_PARAMS+=" --set Core[R4300Emulator]=1"
else
    SIMPLESUFFIX=""
    SET_PARAMS+=" --set Core[R4300Emulator]=2"
fi

# Input settings
SET_PARAMS+=" --set Input-SDL-Control1[plugin]=${PAK}"
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    # Forcar controles 2/3/4 desplugados — defaults built-in tentam autoinit
    # SDL gamepad em slots sem joystick fisico e crashava SIGSEGV apos
    # "Memory pak plugged in" pros 4 controllers. plugged=False + plugin=2
    # (memory pak basic) garante setup limpo dos slots vazios.
    SET_PARAMS+=" --set Input-SDL-Control2[plugged]=False --set Input-SDL-Control2[device]=-1"
    SET_PARAMS+=" --set Input-SDL-Control3[plugged]=False --set Input-SDL-Control3[device]=-1"
    SET_PARAMS+=" --set Input-SDL-Control4[plugged]=False --set Input-SDL-Control4[device]=-1"
else
    SET_PARAMS+=" --set Input-SDL-Control2[plugin]=${PAK}"
    SET_PARAMS+=" --set Input-SDL-Control3[plugin]=${PAK}"
    SET_PARAMS+=" --set Input-SDL-Control4[plugin]=${PAK}"
fi

# Video settings
SET_PARAMS+=" --set Video-General[ScreenHeight]=${SCREENHEIGHT}"
SET_PARAMS+=" --set Video-Parallel[ScreenWidth]=${SCREENWIDTH}"
SET_PARAMS+=" --set Video-Parallel[ScreenHeight]=${SCREENHEIGHT}"
SET_PARAMS+=" --set Video-Parallel[Upscaling]=${IRES}"
SET_PARAMS+=" --set Video-GLideN64[UseNativeResolutionFactor]=${IRES}"
SET_PARAMS+=" --set Video-Rice[ResolutionWidth]=${SCREENWIDTH}"
if [ "${ASPECT}" = "fullscreen" ]; then
    SET_PARAMS+=" --set Video-General[ScreenWidth]=${SCREENWIDTH}"
    SET_PARAMS+=" --set Video-Parallel[WidescreenStretch]=False"
    SET_PARAMS+=" --set Video-GLideN64[AspectRatio]=3"
    SET_PARAMS+=" --set Video-Glide64mk2[aspect]=2"
else
    if [ -z "${VPLUGIN}" ] || [ "${VPLUGIN}" = "rice" ]; then
        GAMEWIDTH=$(((SCREENHEIGHT * 4) / 3))
        SET_PARAMS+=" --set Video-General[ScreenWidth]=${GAMEWIDTH}"
    else
        SET_PARAMS+=" --set Video-General[ScreenWidth]=${SCREENWIDTH}"
    fi
    SET_PARAMS+=" --set Video-Parallel[WidescreenStretch]=False"
    SET_PARAMS+=" --set Video-GLideN64[AspectRatio]=1"
    SET_PARAMS+=" --set Video-Glide64mk2[aspect]=0"
fi
if [ "${FPS}" = "true" ]; then
    export LIBGL_SHOW_FPS="1"
    export GALLIUM_HUD="cpu+GPU-load+fps"
    SET_PARAMS+=" --set Video-GLideN64[ShowFPS]=True"
    SET_PARAMS+=" --set Video-Glide64mk2[show_fps]=1"
    SET_PARAMS+=" --set Video-Rice[ShowFPS]=True"
else
    export LIBGL_SHOW_FPS="0"
    # GALLIUM_HUD="off" e' invalido pra Mesa — driver query parser nao reconhece
    # "off" como valor e em Lima/Rice plugin isso causa SIGSEGV apos init video.
    # Desabilitar corretamente = unset/vazio.
    unset GALLIUM_HUD
    SET_PARAMS+=" --set Video-GLideN64[ShowFPS]=False"
    SET_PARAMS+=" --set Video-Glide64mk2[show_fps]=0"
    SET_PARAMS+=" --set Video-Rice[ShowFPS]=False"
fi

# GLideN64 Profiles
if [ "${GLIDEN64CONF}" = "performance" ]; then
	SET_PARAMS+=" --set Video-GLideN64[EnableLOD]=False"
	SET_PARAMS+=" --set Video-GLideN64[EnableLegacyBlending]=True"
	SET_PARAMS+=" --set Video-GLideN64[EnableHybridFilter]=False"
	SET_PARAMS+=" --set Video-GLideN64[EnableInaccurateTextureCoordinates]=True"
	SET_PARAMS+=" --set Video-GLideN64[EnableCopyColorToRDRAM]=0"
	SET_PARAMS+=" --set Video-GLideN64[EnableCopyDepthToRDRAM]=0"
	SET_PARAMS+=" --set Video-GLideN64[BackgroundsMode]=0"
	SET_PARAMS+=" --set Video-GLideN64[RDRAMImageDitheringMode]=0"
	SET_PARAMS+=" --set Video-GLideN64[CorrectTexrectCoords]=0"
else
	SET_PARAMS+=" --set Video-GLideN64[EnableLOD]=True"
	SET_PARAMS+=" --set Video-GLideN64[EnableLegacyBlending]=False"
	SET_PARAMS+=" --set Video-GLideN64[EnableHybridFilter]=False"
	SET_PARAMS+=" --set Video-GLideN64[EnableInaccurateTextureCoordinates]=False"
	SET_PARAMS+=" --set Video-GLideN64[EnableCopyColorToRDRAM]=2"
fi

# Set the video plugin
case ${VPLUGIN} in
    "rmg_parallel")
        SET_PARAMS+=" --gfx mupen64plus-video-parallel${SIMPLESUFFIX}.so"
        RSP="parallel"
    ;;
    "gliden64")
        SET_PARAMS+=" --gfx mupen64plus-video-GLideN64${SIMPLESUFFIX}.so"
    ;;
    "gl64mk2")
        SET_PARAMS+=" --gfx mupen64plus-video-glide64mk2${SIMPLESUFFIX}.so"
    ;;
    "rice")
        SET_PARAMS+=" --gfx mupen64plus-video-rice${SIMPLESUFFIX}.so"
    ;;
    *)
        SET_PARAMS+=" --gfx mupen64plus-video-rice${SIMPLESUFFIX}.so"
    ;;
esac

# Set the RSP plugin
case "${RSP}" in
    "parallel")
        SET_PARAMS+=" --rsp mupen64plus-rsp-parallel${SIMPLESUFFIX}.so"
    ;;
    "hle")
        SET_PARAMS+=" --rsp mupen64plus-rsp-hle${SIMPLESUFFIX}.so"
    ;;
    *)
        SET_PARAMS+=" --rsp mupen64plus-rsp-cxd4${SIMPLESUFFIX}.so"
    ;;
esac

# Set the remaining plugins
SET_PARAMS+=" --input mupen64plus-input-sdl${SIMPLESUFFIX}.so"
SET_PARAMS+=" --audio mupen64plus-audio-sdl${SIMPLESUFFIX}.so"

# Echo the command line options to the log for debugging
echo ${SET_PARAMS}

# Mesa Lima (Mali-450) only — NUNCA exportar PAN_MESA_DEBUG (driver Panfrost,
# Bifrost+) nem MESA_NO_ERROR: quebram a init de EGL context no Lima e o
# emulador crasha SIGSEGV pouco depois de inicializar o gamepad.

# Amlogic-nxtos (sway+Wayland): forcar SDL Wayland video driver pra mupen
# nao tentar KMSDRM exclusive e bater com o compositor → SIGSEGV no SDL init.
# SDL_AUDIO=pulseaudio pra negociar via pipewire-pulse em vez de ALSA busy.
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    export SDL_VIDEODRIVER=wayland
    export SDL_AUDIODRIVER=pulseaudio
fi

${EMUPERF} /usr/local/bin/mupen64plus${SIMPLESUFFIX} --configdir ${TMP} ${SET_PARAMS} "${TMP}/${ROM}"
