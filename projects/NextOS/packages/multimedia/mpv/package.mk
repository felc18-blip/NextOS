# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="mpv"
PKG_VERSION="2c219aa822df18a1b7fd9abe3e151cd93ad67307" # 0.41.0
PKG_LICENSE="GPLv2+"
PKG_SITE="https://github.com/mpv-player/mpv"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ffmpeg SDL2 luajit libass libplacebo"
PKG_LONGDESC="Video player based on MPlayer/mplayer2 https://mpv.io"

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_MESON_OPTS_TARGET+=" -Dgl=disabled -Degl=enabled"
fi

if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
  PKG_MESON_OPTS_TARGET+=" -Dgl=enabled -Degl=disabled"
fi

if [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_MESON_OPTS_TARGET+=" -Dwayland=enabled"
else
  PKG_MESON_OPTS_TARGET+=" -Dwayland=disabled"
fi

PKG_MESON_OPTS_TARGET+=" -Dsdl2-gamepad=enabled -Dsdl2-audio=enabled -Dsdl2-video=enabled"

post_makeinstall_target() {
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/* 2>/dev/null ||:
  mkdir -p ${INSTALL}/usr/config/mpv
  cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/mpv/
}
