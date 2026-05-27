#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

source /etc/profile

set_kill set "ppsspp"

cp -f /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt /storage/.config/ppsspp/assets/gamecontrollerdb.txt

# Amlogic-no (S905X5/X5M, blob Mali Valhall + KMSDRM): o ppsspp standalone
# deadloca no exit — threads mali (event/mem-purge/cpu/compiler) + main em
# futex_wait ao liberar o contexto GL, voluntary_ctxt_switches=0 (confirmado
# por inspecao). O processo nunca morre -> ES nao volta (tela congelada).
# Watchdog: roda em bg; se o vcs agregado ficar parado (delta 0) por 5s
# (= deadlock; em uso normal o render loop gera switches), SIGKILL.
if echo "${HW_DEVICE}" | grep -qE "Amlogic-no"; then
  /usr/bin/ppsspp >/dev/null 2>&1 &
  PPID_=$!
  (
    stuck=0; last=-1
    while kill -0 "${PPID_}" 2>/dev/null; do
      sleep 1
      [ -d "/proc/${PPID_}/task" ] || break
      cur=$(awk '/^voluntary_ctxt_switches/{s+=$2} END{print s+0}' /proc/"${PPID_}"/task/*/status 2>/dev/null)
      if [ "${cur}" = "${last}" ]; then
        stuck=$((stuck + 1))
        if [ "${stuck}" -ge 5 ]; then
          echo "[Start PPSSPP] exit deadlock (ctxt estagnado ${stuck}s), SIGKILL pid=${PPID_}" >&2
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
  kill "${WPID}" 2>/dev/null
else
  /usr/bin/ppsspp >/dev/null 2>&1
fi
