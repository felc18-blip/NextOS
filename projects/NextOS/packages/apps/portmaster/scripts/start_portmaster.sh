#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
. /etc/os-release
set_kill set "PortMaster"

#Make sure PortMaster exists in .config/PortMaster
if [ ! -d "/storage/.config/PortMaster" ]; then
    mkdir -p "/storage/.config/PortMaster"
      cp -r "/usr/config/PortMaster" "/storage/.config/"
fi

cd /storage/.config/PortMaster

#Grab the latest control.txt, mapper.txt & mod_NextOS.txt, then set correct permissions
cp /usr/config/PortMaster/control.txt control.txt
chmod +x /storage/.config/PortMaster/control.txt
cp /usr/config/PortMaster/mapper.txt mapper.txt
chmod +x /storage/.config/PortMaster/mapper.txt
if [ -f /usr/config/PortMaster/mod_NextOS.txt ]; then
    cp /usr/config/PortMaster/mod_NextOS.txt mod_NextOS.txt
    chmod +x /storage/.config/PortMaster/mod_NextOS.txt
fi


#Use our gamecontrollerdb.txt
rm -rf gamecontrollerdb.txt
ln -sf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt gamecontrollerdb.txt

#Delete old PortMaster fold first (we can probably remove this later)
if [ -d "/storage/roms/ports/PortMaster" ] && [ ! -f "/storage/roms/ports/PortMaster/pugwash" ]; then
    rm -rf /storage/roms/ports/PortMaster
fi

#Make sure roms/ports/PortMaster folder exists
if [ ! -d "/storage/roms/ports/PortMaster" ]; then
    unzip /usr/config/PortMaster/release/PortMaster.zip -d /storage/roms/ports/
    chmod +x /storage/roms/ports/PortMaster/PortMaster.sh
fi

#We dont use tasksetter, delete it
rm -rf /storage/roms/ports/PortMaster/tasksetter

#Use PortMasters gptokeyb
rm -f gptokeyb
[ -x /storage/roms/ports/PortMaster/gptokeyb ] && cp /storage/roms/ports/PortMaster/gptokeyb gptokeyb

#Copy over required files for ports
cp /storage/.config/PortMaster/control.txt /storage/roms/ports/PortMaster/control.txt
cp /storage/.config/PortMaster/mapper.txt /storage/roms/ports/PortMaster/mapper.txt
[ -f /storage/.config/PortMaster/mod_NextOS.txt ] && cp /storage/.config/PortMaster/mod_NextOS.txt /storage/roms/ports/PortMaster/mod_NextOS.txt
cp /storage/.config/PortMaster/gamecontrollerdb.txt /storage/roms/ports/PortMaster/gamecontrollerdb.txt
cp /usr/bin/oga_controls* /storage/roms/ports/PortMaster/

#Hide PortMaster folder in ports
if [ ! -f /storage/roms/ports/gamelist.xml ]; then
echo "<gameList>
	<folder>
		<path>./PortMaster</path>
		<name>PortMaster</name>
		<hidden>true</hidden>
	</folder>
</gameList>" > /storage/roms/ports/gamelist.xml
else
  xmlstarlet ed --inplace -d  "/gameList/folder[name='PortMaster']" /storage/roms/ports/gamelist.xml
  xmlstarlet ed --inplace -d  "/gameList/game[name='PortMaster']" /storage/roms/ports/gamelist.xml
  xmlstarlet ed --inplace --subnode "/gameList" --type elem -n folder -v "" /storage/roms/ports/gamelist.xml
  xmlstarlet ed --inplace --subnode "/gameList/folder[last()]" --type elem -n path -v "./PortMaster" /storage/roms/ports/gamelist.xml
  xmlstarlet ed --inplace --subnode "/gameList/folder[last()]" --type elem -n name -v "PortMaster" /storage/roms/ports/gamelist.xml
  xmlstarlet ed --inplace --subnode "/gameList/folder[last()]" --type elem -n hidden -v "true" /storage/roms/ports/gamelist.xml
fi

#Start PortMaster
cd /storage/roms/ports/PortMaster

# Amlogic-no (S905X5/X5M, blob Mali Valhall + KMSDRM): o pugwash (GUI SDL2 do
# PortMaster) deadloca no exit (futex_wait/pthread_join ao liberar GPU/audio),
# mesmo padrao do ppsspp/hatari. PortMaster.sh fica esperando o pugwash que
# nunca morre -> nunca chega no "systemctl restart essway" abaixo -> tela
# congela e nao volta pro ES. Watchdog: roda em bg e mede o
# voluntary_ctxt_switches agregado da arvore (PortMaster.sh + pugwash + tee).
# GUI viva = render loop gera ctxt switches; deadlock = todas threads em
# futex, delta 0. 6s estagnado => SIGKILL a arvore e o script segue pro restart.
if echo "${HW_DEVICE}" | grep -qE "Amlogic-no"; then
  ./PortMaster.sh 2>/dev/null &
  PMPID=$!
  (
    _tree() { local p="$1"; echo "$p"; for c in $(pgrep -P "$p" 2>/dev/null); do _tree "$c"; done; }
    stuck=0; last=-1
    while kill -0 "${PMPID}" 2>/dev/null; do
      sleep 1
      cur=$(for p in $(_tree "${PMPID}"); do
              awk '/voluntary_ctxt_switches/{s+=$2} END{print s+0}' /proc/"$p"/task/*/status 2>/dev/null
            done | awk '{t+=$1} END{print t+0}')
      if [ "${cur}" = "${last}" ]; then
        stuck=$((stuck + 1))
        if [ "${stuck}" -ge 6 ]; then
          echo "[start_portmaster] exit deadlock (ctxt estagnado ${stuck}s), SIGKILL arvore pid=${PMPID}" >&2
          for p in $(_tree "${PMPID}"); do kill -9 "$p" 2>/dev/null; done
          break
        fi
      else
        stuck=0
      fi
      last="${cur}"
    done
  ) &
  wait "${PMPID}" 2>/dev/null
else
  ./PortMaster.sh 2>/dev/null
fi

# Restart ES so it reloads gamelist.xml with the <image>/<desc> entries that
# PortMaster's PlatformNextOS.gamelist_add() just wrote. Without this, ES
# keeps the in-memory gamelist from boot and overwrites the file on next
# game exit, losing PortMaster's additions.
systemctl restart essway
