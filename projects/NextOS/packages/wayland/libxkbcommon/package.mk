# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

# 2026-05-28 bump 1.6.0 -> 1.13.1 (wlroots 0.20.1 exige >= 1.8.0).
# xkbcommon.org/download/ retornava 404 — agora github archive (CoreELEC).
PKG_NAME="libxkbcommon"
PKG_VERSION="1.13.1"
PKG_SHA256="aeb951964c2f7ecc08174cb5517962d157595e9e3f38fc4a130b91dc2f9fec18"
PKG_LICENSE="MIT"
PKG_SITE="https://xkbcommon.org"
PKG_URL="https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain xkeyboard-config libxml2 libXau libxcb"
PKG_LONGDESC="xkbcommon is a library to handle keyboard descriptions."

PKG_MESON_OPTS_TARGET="-Denable-docs=false"

if [ "${DISPLAYSERVER}" = "x11" ]; then
  PKG_MESON_OPTS_TARGET+=" -Denable-x11=true \
                           -Denable-wayland=false"
elif [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" wayland wayland-protocols"
  PKG_MESON_OPTS_TARGET+=" -Denable-x11=true \
                           -Denable-wayland=true \
                           -Dxkb-config-root=/usr/share/X11/xkb"
else
  PKG_MESON_OPTS_TARGET+=" -Denable-x11=false \
                           -Denable-wayland=false"
fi
