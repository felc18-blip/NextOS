# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
PKG_NAME="waffle"
PKG_LICENSE="BSD"
PKG_VERSION="v1.8.1"
PKG_SHA256="8a9f70b134c72d9969ff9b6560a13ffd650de1f83746d19e61224a0c639a5788"
PKG_SITE="https://waffle.freedesktop.org/"
PKG_URL="https://gitlab.freedesktop.org/mesa/waffle/-/archive/${PKG_VERSION}/waffle-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain wayland mesa Python3"
PKG_LONGDESC="Waffle - a library for selecting an OpenGL API and window system at runtime"
PKG_TOOLCHAIN="meson"

PKG_MESON_OPTS_TARGET+=" -Dwayland=enabled \
                       -Dgbm=enabled \
                       -Dx11_egl=enabled \
                       -Dsurfaceless_egl=enabled \
                       -Dglx=enabled \
                       -Dbuild-examples=false"

pre_configure_target() {
  # glibc 2.43 provides C11 threads natively. waffle vendored threads.h
  # conflicts. Use include_next to fall through to glibc <threads.h>.
  cat > ${PKG_BUILD}/third_party/threads/threads.h <<'EOF'
#pragma once
#include_next <threads.h>
EOF
  cat > ${PKG_BUILD}/third_party/threads/threads_posix.c <<'EOF'
/* glibc 2.43 provides C11 threads — stub. */
EOF
}
