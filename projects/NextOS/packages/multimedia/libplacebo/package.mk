# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="libplacebo"
PKG_VERSION="7.360.1"
PKG_SHA256="d05fdf90bea2f629eaa2d115e909fd356388ac639e54f77b87a018a6d76224bd"
PKG_LICENSE="LGPLv2.1"
PKG_SITE="https://code.videolan.org/videolan/libplacebo"
PKG_URL="https://github.com/haasn/libplacebo/archive/refs/tags/v${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ffmpeg SDL2 luajit libass glslang glad:host Jinja2:host vulkan-headers"
PKG_LONGDESC="The core rendering algorithms and ideas of mpv rewritten as an independent library."

if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
  PKG_MESON_OPTS_TARGET+=" -Dvulkan=enabled"
else
  PKG_MESON_OPTS_TARGET+=" -Dvulkan=disabled"
fi

pre_configure_target() {
  export TARGET_LDFLAGS="${LDFLAGS} -lglslang"
}
