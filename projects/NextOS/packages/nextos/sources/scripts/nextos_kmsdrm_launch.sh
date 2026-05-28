#!/bin/bash
#
# SPDX-License-Identifier: GPL-2.0-or-later
#
# nextos_kmsdrm_launch.sh — wrapper systemd-run pra emuladores standalone
# que precisam virar DRM master do /dev/dri/card0 (KMSDRM-direto).
#
# No Amlogic-no (S905X5M Mali Valhall G310 sem compositor) o blob libMali
# do ES segura refs no card0 mesmo apos SDL_Quit. A unica forma confiavel
# de liberar e parar o servico essway (ES). Mas o emulador esta sendo
# chamado por dentro do ES (runemu.sh é filho do ES) — se ele mesmo parar
# essway, o cgroup todo morre, incluindo o proprio emulador.
#
# Solucao: lançar o emulador num service systemd-run --no-block transient,
# fora do cgroup do ES. ExecStartPre para essway. Wrapper interno reinicia
# essway no fim. Mesma logica do mod_NextOS.txt (PortMaster) mas para
# emuladores que NAO passam pelo PortMaster (chamados via runemu.sh ->
# start_<emu>.sh diretamente).
#
# Uso:
#   nextos_kmsdrm_launch.sh <binario> [args...]
#
# Variaveis herdadas (preservadas pro service):
#   SDL_VIDEODRIVER, SDL_KMSDRM_VSYNC_DEFAULT, HOME, XDG_DATA_HOME,
#   XDG_RUNTIME_DIR, SDL_GAMECONTROLLERCONFIG, LD_LIBRARY_PATH, EMUPERF,
#   <GPTOKEYB_*> (lanca gptokeyb dentro do service se GPTOKEYB_BIN setado)
#
# Devices que NAO sao Amlogic-no: degrada gracefully pra exec direto
# (sem systemd-run). Isso permite os start_*.sh chamarem nextos_kmsdrm_launch
# sempre, sem if/else.

BIN="$1"
shift

if [ -z "${BIN}" ] || [ ! -x "${BIN}" ]; then
    echo "[kmsdrm_launch] binario invalido: ${BIN}" >&2
    exit 1
fi

# Fora do Amlogic-no: fluxo legado direto (sem systemd-run)
if [ "${HW_DEVICE}" != "Amlogic-no" ]; then
    exec ${EMUPERF} "${BIN}" "$@"
fi

# === Amlogic-no path ===

# Mata gptokeyb anterior (orfanado do shell pai do start_*.sh).
# Sera morto junto com o cgroup do ES quando ExecStartPre rodar systemctl
# stop essway, mas evitamos race condition.
pkill -9 -f gptokeyb 2>/dev/null

# Gera wrapper script transiente que vai rodar dentro do service systemd-run.
# Captura args via argv pra escapar aspas/espacos corretamente.
WRAPPER="/tmp/nextos_kmsdrm_wrapper_$$.sh"
GPTOKEYB_LINE=""
if [ -n "${GPTOKEYB_BIN}" ] && [ -x "${GPTOKEYB_BIN}" ]; then
    BIN_NAME="$(basename "${BIN}")"
    GPTK_ARG=""
    if [ -n "${GPTOKEYB_GPTK}" ] && [ -f "${GPTOKEYB_GPTK}" ]; then
        GPTK_ARG="-c ${GPTOKEYB_GPTK}"
    fi
    GPTOKEYB_LINE="( sleep 3 && ${GPTOKEYB_BIN} \"${BIN_NAME}\" ${GPTK_ARG} ) &"
fi

cat > "${WRAPPER}" <<WRAPEOF
#!/bin/sh
cd "$(dirname "${BIN}")"
${GPTOKEYB_LINE}
GPID=\$!
${EMUPERF} "${BIN}" $(printf ' %q' "$@")
RC=\$?
[ -n "\${GPID}" ] && kill -9 \${GPID} 2>/dev/null
pkill -9 -f gptokeyb 2>/dev/null
# Restaura essway via systemd-run fora do nosso cgroup (evita SIGKILL que
# ExecStopPost levava por deadlock de stop transient + start essway)
systemd-run --no-block --collect /bin/sh -c 'touch /var/lock/start.games; systemctl reset-failed essway 2>/dev/null; systemctl start essway' 2>/dev/null
rm -f "${WRAPPER}"
exit \$RC
WRAPEOF
chmod +x "${WRAPPER}"

UNIT="nextos-kmsdrm-$$.service"

# Setenv minimal: passa apenas o que o emulador precisa, evitando vazar
# variaveis do shell pai (especialmente WAYLAND_DISPLAY/DISPLAY do ES).
systemd-run \
    --no-block \
    --collect \
    --unit="${UNIT}" \
    --service-type=simple \
    --setenv="SDL_VIDEODRIVER=${SDL_VIDEODRIVER:-kmsdrm}" \
    --setenv="SDL_KMSDRM_VSYNC_DEFAULT=${SDL_KMSDRM_VSYNC_DEFAULT:-1}" \
    --setenv="HOME=/storage" \
    --setenv="XDG_RUNTIME_DIR=/tmp" \
    --setenv="XDG_DATA_HOME=${XDG_DATA_HOME}" \
    --setenv="SDL_GAMECONTROLLERCONFIG=${SDL_GAMECONTROLLERCONFIG}" \
    --setenv="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
    --setenv="LD_PRELOAD=${LD_PRELOAD}" \
    --property=ExecStartPre='/bin/sh -c "rm -f /var/lock/start.games; systemctl stop essway"' \
    "${WRAPPER}"

# Sai do start_*.sh — runemu retorna, ES morre junto com essway, service roda
# livre. Quando emulador termina, wrapper restaura essway -> ES volta na
# ultima posicao salva (LastSystem em es_settings.cfg).
exit 0
