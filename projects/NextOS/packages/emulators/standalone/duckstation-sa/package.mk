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
# NextOS: a resolucao de DEPENDENCIAS da imagem le ESTE package.mk base (a
# pegadinha per-device: get_pkg_variable/closure usa o base, nao o override
# device). No Amlogic-no usamos a AppImage Qt 6.11 (override install) que precisa
# do qt6 do SISTEMA (eglfs_kms) -> dep qt6 aqui p/ o qt6 entrar na imagem; e NAO
# o felc18 nogui (que e so p/ Mali-450/nxtos). Demais devices: meta -> nogui.
if [ "${DEVICE}" = "Amlogic-no" ]; then
  PKG_DEPENDS_TARGET="qt6"
else
  PKG_DEPENDS_TARGET="duckstation-nogui"
fi
PKG_LONGDESC="DuckStation (meta-package -> duckstation-nogui)"
PKG_TOOLCHAIN="manual"

unpack() { mkdir -p ${PKG_BUILD}; }
configure_target() { :; }
make_target() { :; }
makeinstall_target() { :; }
