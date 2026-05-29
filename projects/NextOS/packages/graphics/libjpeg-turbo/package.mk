# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 NextOS — habilitar SHARED pra Weston/Xwayland precisarem libjpeg.so.8

PKG_NAME="libjpeg-turbo"
PKG_VERSION="3.1.4.1"
PKG_SHA256="ecae8008e2cc9ade2f2c1bb9d5e6d4fb73e7c433866a056bd82980741571a022"
PKG_LICENSE="GPL"
PKG_SITE="https://libjpeg-turbo.org/"
PKG_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="cmake:host ninja:host"
PKG_DEPENDS_TARGET="cmake:host ninja:host gcc:host"
PKG_LONGDESC="A JPEG image codec that uses SIMD instructions."
PKG_BUILD_FLAGS="+pic +pic:host"

PKG_CMAKE_OPTS_HOST="-DENABLE_STATIC=ON \
                     -DENABLE_SHARED=OFF \
                     -DWITH_JPEG8=ON \
                     -DWITH_SIMD=OFF"

# NextOS 2026-05-29: SHARED=ON pra gerar libjpeg.so.8 que Weston/Xwayland/demo
# clients precisam. Upstream Arch-R só compila .a (STATIC). Sem isto,
# /usr/lib/libjpeg.so.8 não existe → xwayland.so falha load → weston cliente fail.
PKG_CMAKE_OPTS_TARGET="-DENABLE_STATIC=ON \
                       -DENABLE_SHARED=ON \
                       -DWITH_JPEG8=ON"

if target_has_feature "(neon|sse)"; then
  PKG_CMAKE_OPTS_TARGET+=" -DWITH_SIMD=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DWITH_SIMD=OFF"
fi
