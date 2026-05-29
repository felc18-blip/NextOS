#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile

# Generate controller config
# Set controller guid, just take the first one mednafen lists
GUID1="$(mednafen --list-joysticks | grep ID | awk 'NR==1 {print $2}')"
sed -e "s/@GUID1@/${GUID1}/g" ${MEDNAFEN_CONFIG} >> $MEDNAFEN_HOME/mednafen.cfg

NAME="$(mednafen --list-joysticks | grep ID | awk 'NR==1 {print $5$6}')"
if [[ "$(mednafen --list-joysticks | grep ID | awk 'NR==1 {print $4}')" = "8BitDo" ]]
then
NAME="X-Box360"
fi

if [[ "${NAME}" = "X-Box360" ]]
then
export DEVICE_FUNC_KEYA_MODIFIER="BTN_THUMBL"
export DEVICE_FUNC_KEYB_MODIFIER="BTN_THUMBR"
fi

# Default modifiers para gamepads gen'ricos (USB Gamepad / Anbernic / etc).
# Sem defaults, sed substitui @DEVICE_FUNC_KEY[AB]_MODIFIER@ por @DEVICE_@
# (string vazia) e o mednafen recusa o cfg inteiro com "Bad joystick bn string"
# → exit 255 antes de inicializar video. Bug presente no Arch-R upstream pra
# qualquer controle que nao tenha quirk per-device.
[ -z "${DEVICE_FUNC_KEYA_MODIFIER}" ] && export DEVICE_FUNC_KEYA_MODIFIER="BTN_THUMBL"
[ -z "${DEVICE_FUNC_KEYB_MODIFIER}" ] && export DEVICE_FUNC_KEYB_MODIFIER="BTN_THUMBR"

# explcitly override d-pad that are hats, they are somehow randomly mapped as analog in mednafen
if [[ "${NAME}" = "X-Box360" ]]
then
DEVICE_BTN_DPAD_UP="7-"
DEVICE_BTN_DPAD_DOWN="7+"
DEVICE_BTN_DPAD_LEFT="6-"
DEVICE_BTN_DPAD_RIGHT="6+"
elif [[ "${NAME}" = "OSHPB" ]]
then
DEVICE_BTN_DPAD_UP="6-"
DEVICE_BTN_DPAD_DOWN="6+"
DEVICE_BTN_DPAD_LEFT="5-"
DEVICE_BTN_DPAD_RIGHT="5+"
fi

# Generico: dpad reportado como HAT pelo ES (mkcontroller emite "h<id><dir>").
# O cfg do mednafen NAO tem syntax de hat (so button_N / abs_N+-), entao sem
# tratamento o gen_config poe button_99 = dpad morto (caso do "USB Gamepad" no
# Amlogic-no). Resolver computando do proprio ID do mednafen (GUID1 codifica
# num_axes[8:9] num_buttons[10:11] num_hats[12:13]):
#  - num_hats>0  : driver SDL expoe o hat como botoes virtuais a partir de
#                  num_buttons (HatToButtonCompat: +0 up, +1 right, +2 down, +3 left).
#  - num_hats==0 : SDL colapsou o hat em eixos; ABS_HAT0X/Y vem por ultimo, entao
#                  o dpad sao os 2 ultimos eixos (mesma ideia dos overrides X-Box360/OSHPB).
if [[ "${DEVICE_BTN_DPAD_UP}" == h* ]]; then
    HEXID="${GUID1#0x}"
    NUM_AXES=$((16#${HEXID:16:4}))
    NUM_HATS=$((16#${HEXID:24:4}))
    if [ "${NUM_HATS}" -gt 0 ]; then
        NUM_BTN=$((16#${HEXID:20:4}))
        DEVICE_BTN_DPAD_UP="$((NUM_BTN+0))";  DEVICE_BTN_DPAD_RIGHT="$((NUM_BTN+1))"
        DEVICE_BTN_DPAD_DOWN="$((NUM_BTN+2))"; DEVICE_BTN_DPAD_LEFT="$((NUM_BTN+3))"
    elif [ "${NUM_AXES}" -ge 2 ]; then
        AXY=$((NUM_AXES-1)); AXX=$((NUM_AXES-2))
        DEVICE_BTN_DPAD_UP="${AXY}-";  DEVICE_BTN_DPAD_DOWN="${AXY}+"
        DEVICE_BTN_DPAD_LEFT="${AXX}-"; DEVICE_BTN_DPAD_RIGHT="${AXX}+"
    fi
fi

# Replace modifiers with actual buttons
for MOD in DEVICE_FUNC_KEYA_MODIFIER DEVICE_FUNC_KEYB_MODIFIER
do
    sed -i -e "s/${MOD}/DEVICE_${!MOD}/g" $MEDNAFEN_HOME/mednafen.cfg
done

# If not trigger minus axes, default to same as trigger button
if [[ -z "${DEVICE_BTN_TL2_MINUS}" ]]; then
DEVICE_BTN_TL2_MINUS=${DEVICE_BTN_TL2}
fi
if [[ -z "${DEVICE_BTN_TR2_MINUS}" ]]; then
DEVICE_BTN_TR2_MINUS=${DEVICE_BTN_TR2}
fi
# General case our 098-controller is right, we just need prefixes. First axes that are prefixed with abs_
for CONTROL in DEVICE_BTN_AL_DOWN DEVICE_BTN_AL_UP DEVICE_BTN_AL_LEFT    \
               DEVICE_BTN_AL_RIGHT DEVICE_BTN_AR_DOWN DEVICE_BTN_AR_UP   \
               DEVICE_BTN_AR_LEFT DEVICE_BTN_AR_RIGHT                    \
    	       DEVICE_BTN_SOUTH DEVICE_BTN_EAST DEVICE_BTN_NORTH         \
               DEVICE_BTN_WEST DEVICE_BTN_TL DEVICE_BTN_TR               \
               DEVICE_BTN_TL2 DEVICE_BTN_TR2 DEVICE_BTN_SELECT           \
               DEVICE_BTN_START DEVICE_BTN_MODE DEVICE_BTN_THUMBL        \
               DEVICE_BTN_THUMBR DEVICE_BTN_DPAD_UP DEVICE_BTN_DPAD_DOWN \
               DEVICE_BTN_DPAD_LEFT DEVICE_BTN_DPAD_RIGHT                \
               DEVICE_BTN_TL2_MINUS DEVICE_BTN_TR2_MINUS

do
    # Detect axes, and treat appropriately. Default is button
    if [[ ${!CONTROL} =~ [+|-]$ ]]; then
        sed -i -e "s/@${CONTROL}@/abs_${!CONTROL}/g" $MEDNAFEN_HOME/mednafen.cfg
    elif [[ ${!CONTROL} =~ ^[0-9]+$ ]]; then
        # if it's just a number its a button
        sed -i -e "s/@${CONTROL}@/button_${!CONTROL}/g" $MEDNAFEN_HOME/mednafen.cfg
    else
        # unidentifiable buttons or non-existent on this pad
        # Set a non-consequential value so that we don't get a syntax error in mednafen config
        # I randomly picked button_99 here.
        sed -i -e "s/@${CONTROL}@/button_99/g" $MEDNAFEN_HOME/mednafen.cfg
    fi
done
