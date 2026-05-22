# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
#
# Amlogic-no device override: importar o debug do projeto NextOS e remover
# gdb + apitrace + strace que ainda não compilam no toolchain GCC 16 BSP
# 5.15. Sem isso, o build do virtual/debug falha pq esses pacotes ainda não
# estão portados (NCURSES_BOOL collision em gdb, waffle dup em apitrace,
# strace 6.19 não detecta cabeçalhos do kernel 5.15.196).

. ${ROOT}/projects/NextOS/packages/virtual/debug/package.mk

PKG_DEPENDS_TARGET=${PKG_DEPENDS_TARGET//"gdb"/}
PKG_DEPENDS_TARGET=${PKG_DEPENDS_TARGET//"apitrace"/}
PKG_DEPENDS_TARGET=${PKG_DEPENDS_TARGET//"strace"/}
