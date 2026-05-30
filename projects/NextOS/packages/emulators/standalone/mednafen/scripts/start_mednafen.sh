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

# Mednafen 1.32 trava o load do cfg (Line 201 error) -> emulador aborta e volta
# pro ES. Dois problemas nas linhas command.*: (1) combos joystick com && / || nao
# sao aceitos; (2) o gen_config nao substitui o GUID do controle, gerando bindings
# malformados "joystick  button_N" (GUID vazio) que tambem sao rejeitados.
# Fix SEMPRE no cfg primario ($MEDNAFEN_HOME, o que o mednafen carrega): cortar no
# primeiro " && "/" || " e, se o que sobrar tiver "joystick" (sem GUID valido),
# descartar a linha (mednafen cai no default interno teclado). Linhas keyboard
# (ex: insert_coin "keyboard ... || joystick ...") sobrevivem com o mapping valido.
if [ -f "$MEDNAFEN_HOME/mednafen.cfg" ]; then
    python3 -c "
out=[]
for l in open('$MEDNAFEN_HOME/mednafen.cfg'):
    # So mexe em bindings MALFORMADOS = GUID vazio ('joystick' seguido de 2+ espacos),
    # que so acontece quando o gen_config roda sem ver o controle (sem /dev/input/js0).
    # Bindings VALIDOS ('joystick 0x.. button_N', inclusive combos com && em command.*)
    # ficam INTACTOS -> com joydev ativo isto e no-op (preserva o mapeamento e o exit).
    if 'joystick  ' in l:
        kv=l.rstrip('\n')
        for s in (' && ',' || '):
            i=kv.find(s)
            if i!=-1: kv=kv[:i].rstrip()
        if 'joystick  ' in kv+' ' or kv.endswith('joystick'):
            continue
        out.append(kv+'\n')
    else:
        out.append(l)
open('$MEDNAFEN_HOME/mednafen.cfg','w').writelines(out)
" 2>/dev/null || true
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

# Amlogic-nxtos: PipeWire (pipewire-pulse) ocupa /dev/snd; mednafen ALSA direto
# bate "Device or resource busy". Forcar SDL audio (via pipewire-pulse).
# (Amlogic-no NAO entra aqui: tem bloco GLES isolado proprio com pipewire morto +
#  ALSA direto no HDMI, mais abaixo.)
if [ "${HW_DEVICE}" = "Amlogic-nxtos" ]; then
    export SDL_AUDIODRIVER=alsa
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

# Amlogic-no (X5M): mednafen 1.32 IGNORA $MEDNAFEN_HOME e usa hardcoded
# ~/.mednafen (HOME-based). Sem MEDNAFEN_HOME conhecido, ele cria
# /storage/.mednafen/ separado e procura BIOS em ./firmware (relativo) =
# /storage/.mednafen/firmware/. Fix: aplicar mesmo sed em /storage/.mednafen/
# se existir + setar filesys.path_firmware absoluto pro path correto.
if [ "${HW_DEVICE}" = "Amlogic-no" ]; then
    SECOND_CFG="/storage/.mednafen/mednafen.cfg"
    if [ -f "$SECOND_CFG" ]; then
        sed -i "s|^filesys.path_firmware .*|filesys.path_firmware /storage/roms/bios|" "$SECOND_CFG"
        sed -i "s|^filesys.path_sav .*|filesys.path_sav /storage/roms/${PLATFORM}|" "$SECOND_CFG"
        sed -i "s|^filesys.path_savbackup .*|filesys.path_savbackup /storage/roms/${PLATFORM}|" "$SECOND_CFG"
        sed -i "s|^filesys.path_state .*|filesys.path_state /storage/roms/savestates/${PLATFORM}|" "$SECOND_CFG"
        # Fullscreen + driver software (Mali Valhall sem OpenGL desktop)
        sed -i "s|^video.fs .*|video.fs 1|" "$SECOND_CFG"
        sed -i "s|^video.driver .*|video.driver sdl|" "$SECOND_CFG"
        # Limpar mappings command.* com && / || (mednafen 1.32 nao aceita)
        # Linhas command.exit/fast_forward/etc com joystick AND joystick travam
        # o load do cfg (Line 201 error). Cortar tudo apos primeiro " && " /
        # " || " em linhas command.* mantem o primeiro mapping valido.
        python3 -c "
import re
with open('$SECOND_CFG') as f:
    lines = f.readlines()
for i, l in enumerate(lines):
    if l.startswith('command.') and (' && ' in l or ' || ' in l):
        cut = min((l.find(s) for s in [' && ', ' || '] if s in l))
        lines[i] = l[:cut].rstrip() + '\n'
with open('$SECOND_CFG', 'w') as f:
    f.writelines(lines)
" 2>/dev/null || true
    fi
fi

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

# === Amlogic-no (X5M Mali Valhall G310): mednafen em GLES via gl4es no KMSDRM ===
# Modelo "Arch-R nativo": NAO mata o essway. O ES solta o DRM master sozinho ao
# lancar (patch EE_KMSDRM_RELEASE_DRM) -> o input.service segue vivo e o
# select+start MATA o mednafen nativamente (runemu fez set_kill "-9 mednafen").
# So paramos o PIPEWIRE (com ele vivo o gl4es fica PRETO - ele segura o CRTC) e
# religamos no fim. Render: gl4es (LD_PRELOAD libGL) traduz GL desktop->GLES2;
# precisa SDL kmsdrm + preload libwayland/libGLESv2 (page-flip). Som (pipewire
# morto): ALSA direto no HDMI (HDMITX=Spdif_b, device hdmi:). Controle: botoes
# de acao nativos (joydev/js0) + D-pad (HAT, morto no joystick) via gptokeyb->setas.
# OBS: numeros dos botoes sao do "USB Gamepad" do Felipe (es_input); outro pad pode diferir.
if [ "${HW_DEVICE}" = "Amlogic-no" ] && [ -f /usr/lib/gl4es/libGL.so.1 ]; then
    C="$MEDNAFEN_HOME/mednafen.cfg"
    systemctl stop pipewire pipewire-pulse wireplumber 2>/dev/null
    sleep 1
    amixer -c 0 cset numid=35 1 >/dev/null 2>&1
    amixer -c 0 cset numid=12 0 >/dev/null 2>&1
    amixer -c 0 cset numid=1 0 >/dev/null 2>&1
    if [ -f "$C" ]; then
        # Botoes de acao NATIVOS (joydev/js0). Remap pros numeros fisicos do pad (es_input).
        G="$(grep -m1 -oE 'joystick 0x[0-9a-f]+' "$C" 2>/dev/null)"
        [ -z "$G" ] && G="joystick 0x00030810000101100006000c00000000"
        for kv in x:0 a:1 b:2 y:3 z:6 c:7 ls:4 rs:5; do
            k="${kv%%:*}"; n="${kv##*:}"
            sed -i "s|^ss.input.port1.gamepad.${k} .*|ss.input.port1.gamepad.${k} ${G} button_${n}|" "$C"
        done
        # D-pad e HAT (morto no joystick) -> teclado setas. PENDENTE: o gptokeyb ainda
        # nao esta convertendo o HAT desse "USB Gamepad" (SDL gamecontroller). D-pad nao pega.
        sed -i "s|^ss.input.port1.gamepad.up .*|ss.input.port1.gamepad.up keyboard 0x0 82|" "$C"
        sed -i "s|^ss.input.port1.gamepad.down .*|ss.input.port1.gamepad.down keyboard 0x0 81|" "$C"
        sed -i "s|^ss.input.port1.gamepad.left .*|ss.input.port1.gamepad.left keyboard 0x0 80|" "$C"
        sed -i "s|^ss.input.port1.gamepad.right .*|ss.input.port1.gamepad.right keyboard 0x0 79|" "$C"
    fi
    printf 'up=up\ndown=down\nleft=left\nright=right\n' > /tmp/mednafen-dpad.gptk
    # Sair: NAO mexer no command.exit. select+start fecha pelo mecanismo NATIVO do Arch-R
    # (input.service + set_kill "-9 mednafen"), que funciona porque o essway fica vivo e o
    # gptokeyb '1' nao faz grab exclusivo do controle. [CONFIRMADO funcionando]
    GPTK_WRAP=""
    if [ -x /usr/bin/gptokeyb ]; then
        ( sleep 2 && exec env -u EMUELEC /usr/bin/gptokeyb 1 mednafen -c /tmp/mednafen-dpad.gptk ) &
        GPTK_WRAP=$!
    fi
    export SDL_VIDEODRIVER=kmsdrm SDL_KMSDRM_VSYNC_DEFAULT=1 SDL_VIDEO_FULLSCREEN=1
    export HOME=/storage XDG_RUNTIME_DIR=/tmp
    export LD_PRELOAD="/usr/lib/gl4es/libGL.so.1 /usr/lib/libwayland-client.so.0 /usr/lib/libwayland-server.so.0 /usr/lib/libGLESv2.so.2"
    export LIBGL_ES=2 LIBGL_GL=21 LIBGL_NOTEST=1
    ${EMUPERF} /usr/bin/mednafen -force_module ${CORE} -${CORE}.stretch ${STRETCH:=full} -${CORE}.shader ${SHADER:="ipsharper"} -video.driver opengl -fs 1 -sound.driver alsa -sound.device sexyal-literal-hdmi:CARD=AMLAUGESOUND ${FEATURES_CMDLINE} "${ROM_FOR_MEDNAFEN}"
    [ -n "$GPTK_WRAP" ] && kill -9 "$GPTK_WRAP" 2>/dev/null   # mata o wrapper mesmo se ainda no sleep (evita gptokeyb orfao)
    pkill -9 -f "gptokeyb .*mednafen" 2>/dev/null
    systemctl start pipewire pipewire-pulse wireplumber 2>/dev/null
    exit 0
fi

#Run mednafen
${EMUPERF} /usr/bin/mednafen -force_module ${CORE} -${CORE}.stretch ${STRETCH:="aspect"} -${CORE}.shader ${SHADER:="ipsharper"} ${FEATURES_CMDLINE} "${ROM_FOR_MEDNAFEN}"
