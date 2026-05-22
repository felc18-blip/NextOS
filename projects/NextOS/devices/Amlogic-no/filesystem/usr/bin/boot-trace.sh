#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS Elite Edition V15.2 Tier 1 — Boot trace helper (Amlogic-no per-device)
#
# Pattern adoptado do Arch-R/JELOS (autostart/sources/autostart):
# Cada script de boot escreve seu nome em /storage/.boot_last_step ANTES de
# rodar, apaga ao terminar. Se boot trava: arquivo persiste → SSH/recovery
# `cat /storage/.boot_last_hang` diz exatamente onde travou. Substitui
# dependência de serial console / dmesg via mídia.
#
# Per-device Amlogic-no — Amlogic-old (kernel 3.14) e ng (4.9) intocados.
#
# Uso em systemd service:
#   ExecStartPre=/usr/bin/boot-trace.sh step my-service-name
#   ExecStartPost=/usr/bin/boot-trace.sh done
#
# Uso em shell script:
#   . /usr/bin/boot-trace.sh
#   trace_step "init-gpu"
#   ... do work ...
#   trace_done
#
# Inspect after hang reboot:
#   cat /storage/.boot_last_hang        # last hang location
#   ls -la /storage/.boot_last_*        # all trace files

STEP_FILE=/storage/.boot_last_step
HANG_FILE=/storage/.boot_last_hang
LOG=/var/log/boot-trace.log

trace_step() {
    [ -d /storage ] || return 0
    echo "$1" > "$STEP_FILE" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S'): step=$1" >> "$LOG" 2>/dev/null
}

trace_done() {
    rm -f "$STEP_FILE" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S'): done" >> "$LOG" 2>/dev/null
}

trace_init() {
    # On boot start: if /storage/.boot_last_step exists, previous boot HUNG.
    # Preserve copy at .boot_last_hang (survives next boot's overwrite).
    [ -d /storage ] || return 0
    if [ -f "$STEP_FILE" ]; then
        cp -f "$STEP_FILE" "$HANG_FILE" 2>/dev/null
        local LAST_HANG=$(cat "$STEP_FILE" 2>/dev/null)
        echo "$(date '+%Y-%m-%d %H:%M:%S'): PREVIOUS BOOT HUNG at: $LAST_HANG" >> "$LOG" 2>/dev/null
        # rotate log se >100KB
        [ -f "$LOG" ] && [ $(stat -c%s "$LOG" 2>/dev/null) -gt 102400 ] && \
            mv "$LOG" "${LOG}.1" 2>/dev/null
    fi
    rm -f "$STEP_FILE" 2>/dev/null
}

trace_status() {
    echo "Boot trace status:"
    if [ -f "$STEP_FILE" ]; then
        echo "  CURRENT step (boot in progress or last hang): $(cat "$STEP_FILE" 2>/dev/null)"
    else
        echo "  current: idle (last boot completed cleanly)"
    fi
    if [ -f "$HANG_FILE" ]; then
        echo "  LAST HANG: $(cat "$HANG_FILE" 2>/dev/null)"
    else
        echo "  last hang: none recorded"
    fi
    [ -f "$LOG" ] && {
        echo ""
        echo "Recent log entries:"
        tail -10 "$LOG"
    }
}

# When sourced, only define functions. When called directly, dispatch.
if [ "$(basename "$0" 2>/dev/null)" = "boot-trace.sh" ] || [ "$(basename "$0" 2>/dev/null)" = "boot-trace" ]; then
    case "${1:-status}" in
        step)
            shift
            trace_step "${1:-unknown}"
            ;;
        done|complete)
            trace_done
            ;;
        init)
            trace_init
            ;;
        status|"")
            trace_status
            ;;
        *)
            echo "Uso: $0 {step <name>|done|init|status}"
            exit 1
            ;;
    esac
fi
