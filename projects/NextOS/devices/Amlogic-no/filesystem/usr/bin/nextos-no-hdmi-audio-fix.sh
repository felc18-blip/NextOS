#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS-Retro-Elite-Edition
#
# AML-AUGE HDMI audio routing fix pro kernel 5.15.196 (Amlogic-no).
#
# O card 0 expõe múltiplos PCMs:
#   pcm0p = SPDIF-B-dummy soc:dummy-0  (rota interna pro HDMI TX)
#   pcm1p = TDM-B-T9015-audio-hifi     (lineout analog DAC)
#   pcm2p = SPDIF-dummy soc:dummy-2    (SPDIF físico optical, sem rota HDMI)
#
# Streams pro HDMI entram no pcm0p (SPDIF-B), e o controle ALSA
# "HDMITX Audio Source Select" precisa apontar pra "Spdif_b" (item 1).
# Adicionalmente, "Audio I2S to HDMITX Mask" precisa ter os canais L+R
# habilitados (3 = 0b0011). Sem isso, paplay simples toca por rota
# interna fortuita mas SDL3/mpv streams contínuos ficam silenciosos
# (HDMI TX recebe só zeros mesmo com sink Pulse correto).
#
# Bug confirmado em S905X4 (board sc2_s905x4) — provável o mesmo no
# S905X5/X5-M (mesmo AML-AUGE driver, mesma família de chip).

[ -e /proc/asound/card0 ] || exit 0

amixer -c 0 -q cset numid=34 1 2>/dev/null || true  # HDMITX Audio Source Select = Spdif_b
amixer -c 0 -q cset numid=36 3 2>/dev/null || true  # Audio I2S to HDMITX Mask = L+R

exit 0
