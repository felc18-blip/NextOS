#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

source /etc/profile

set_kill set "hatarisa"

sway_fullscreen "hatari" &

# Amlogic-no (blob Mali Valhall + KMSDRM): hatarisa deadloca no exit (Quit) liberando
# o contexto GL (threads em futex_wait, voluntary_ctxt_switches=0). Processo nao morre
# -> ES nao volta. Watchdog: roda em bg + SIGKILL se vcs ficar parado 5s. Gate Amlogic-no.
if echo "${HW_DEVICE}" | grep -qE "Amlogic-no"; then
  /usr/bin/hatarisa >/dev/null 2>&1 &
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
          echo "[Start HATARISA] exit deadlock (ctxt estagnado ${stuck}s), SIGKILL pid=${PPID_}" >&2
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
  /usr/bin/hatarisa >/dev/null 2>&1
fi
