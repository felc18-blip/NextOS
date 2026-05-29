
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

# 2026-05-28 bump 2.4.128 -> 2.4.133 (wlroots 0.20.1 exige >= 2.4.129).
# Mantém customizações NextOS: dep libdisplay-info, sed nos headers, install
# modetest.
PKG_NAME="libdrm"
PKG_VERSION="2.4.133"
PKG_SHA256="fc68f9d0ba2ea63c9432a299e14fea09fad7a8a66e8039fcd7802ca59f77b4f5"
PKG_LICENSE="GPL"
PKG_SITE="http://dri.freedesktop.org"
PKG_URL="http://dri.freedesktop.org/libdrm/libdrm-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="toolchain libpciaccess libdisplay-info"
PKG_DEPENDS_TARGET="toolchain libpciaccess libdisplay-info"
PKG_LONGDESC="The userspace interface library to kernel DRM services."
PKG_TOOLCHAIN="meson"

get_graphicdrivers

PKG_MESON_OPTS_TARGET="-Dnouveau=disabled \
                       -Domap=disabled \
                       -Dexynos=disabled \
                       -Dtegra=disabled \
                       -Dcairo-tests=disabled \
                       -Dman-pages=disabled \
                       -Dvalgrind=disabled \
                       -Dfreedreno-kgsl=false \
                       -Dinstall-test-programs=false \
                       -Dudev=false"

listcontains "${GRAPHIC_DRIVERS}" "(iris|i915|i965)" &&
  PKG_MESON_OPTS_TARGET+=" -Dintel=enabled" || PKG_MESON_OPTS_TARGET+=" -Dintel=disabled"

listcontains "${GRAPHIC_DRIVERS}" "(r200|r300|r600|radeonsi)" &&
  PKG_MESON_OPTS_TARGET+=" -Dradeon=enabled" || PKG_MESON_OPTS_TARGET+=" -Dradeon=disabled"

listcontains "${GRAPHIC_DRIVERS}" "radeonsi" &&
  PKG_MESON_OPTS_TARGET+=" -Damdgpu=enabled" || PKG_MESON_OPTS_TARGET+=" -Damdgpu=disabled"

listcontains "${GRAPHIC_DRIVERS}" "freedreno" &&
  PKG_MESON_OPTS_TARGET+=" -Dfreedreno=enabled" || PKG_MESON_OPTS_TARGET+=" -Dfreedreno=disabled"

listcontains "${GRAPHIC_DRIVERS}" "etnaviv" &&
  PKG_MESON_OPTS_TARGET+=" -Detnaviv=enabled" || PKG_MESON_OPTS_TARGET+=" -Detnaviv=disabled"

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_BUILD}/.${TARGET_NAME}/tests/modetest/modetest ${INSTALL}/usr/bin/
  # 2026-05-28 REMOVIDO sed que trocava <drm.h> -> <drm/drm.h> em xf86drm.h:
  # com libdrm 2.4.133 instalando headers em /usr/include/libdrm/drm.h, o
  # original <drm.h> resolve corretamente via -I/usr/include/libdrm/.
  # Com o sed antigo, <drm/drm.h> ia pegar o KERNEL header (5.15.196) que
  # nao tem drm_syncobj_eventfd, quebrando wlroots 0.20.1.
}
