# SPDX-License-Identifier: GPL-2.0-or-later
# 2026-05-17 NextOS: duckstation-sa redirecionado pra duckstation-nogui em
# todos devices. Upstream AppImage Qt requer OpenGL desktop 3.3+ que nem
# Mali-450 (Amlogic-nxtos) nem outros SoCs ARM da NextOS têm; o fork NoGUI
# (felc18-blip/duckstation-nextos) usa SDL2+EGL+Wayland (USE_WAYLAND=ON) e
# roda em todo lugar. Esse package é meta — só puxa o nogui.

PKG_NAME="duckstation-sa"
PKG_VERSION="meta"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/felc18-blip/duckstation-nextos"
PKG_DEPENDS_TARGET="duckstation-nogui"
PKG_LONGDESC="DuckStation (meta-package -> duckstation-nogui)"
PKG_TOOLCHAIN="manual"

unpack() { mkdir -p ${PKG_BUILD}; }
configure_target() { :; }
make_target() { :; }
makeinstall_target() { :; }
