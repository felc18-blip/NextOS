# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS / NextOS

# SDL3 upstream main (libsdl-org/SDL) — 3.5.0-dev.
# Same KMSDRM/OPENGLES/Wayland flag set as SDL2 NextOS (graphics/SDL2);
# names migrated to SDL3 CMake (all -DSDL_*, no -DVIDEO_*).
# 64-bit (aarch64) is the primary target; the 32-bit (arm) build is
# consumed by compat/lib32, which copies it into /usr/lib32 of the aarch64
# rootfs — that's how NextOS delivers "lib32-SDL3" without a separate
# package (different model from NextOS).

PKG_NAME="SDL3"
PKG_VERSION="ae25abeb0daab3b33c94227e339e622bfa72769c"
PKG_SHA256="7a73d62aa8bbd92ee30b10e22eea2a969843c63aabec91d5e57f3b6844c2453f"
PKG_LICENSE="Zlib"
PKG_SITE="https://libsdl.org/"
PKG_URL="https://github.com/libsdl-org/SDL/archive/${PKG_VERSION}.tar.gz"
PKG_SOURCE_NAME="SDL3-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib systemd dbus pulseaudio libdrm SDL3:host"
PKG_LONGDESC="Simple DirectMedia Layer 3 — upstream main (3.5.0-dev)"
PKG_BUILD_FLAGS="+speed"
PKG_DEPENDS_HOST="toolchain:host distutilscross:host libX11:host"

if [ ! "${OPENGL_SUPPORT}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu"
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_OPENGL=ON -DSDL_KMSDRM=OFF"
else
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_OPENGL=OFF -DSDL_KMSDRM=OFF"
fi

if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_OPENGLES=ON -DSDL_KMSDRM=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_OPENGLES=OFF -DSDL_KMSDRM=OFF"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_VULKAN=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_VULKAN=OFF"
fi

if [ "${DISPLAYSERVER}" = "wl" ]; then
  PKG_DEPENDS_TARGET+=" wayland"
  case ${ARCH} in
    arm) true ;;
    *) PKG_DEPENDS_TARGET+=" ${WINDOWMANAGER}" ;;
  esac
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_WAYLAND=ON -DSDL_WAYLAND_SHARED=ON -DSDL_X11=OFF"
else
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_WAYLAND=OFF -DSDL_X11=OFF"
fi

pre_configure_target(){
  export LDFLAGS="${LDFLAGS} -ludev"
  PKG_CMAKE_OPTS_TARGET+=" -DSDL_STATIC=OFF \
                           -DSDL_SHARED=ON \
                           -DSDL_LIBC=ON \
                           -DSDL_GCC_ATOMICS=ON \
                           -DSDL_ALTIVEC=OFF \
                           -DSDL_OSS=OFF \
                           -DSDL_ALSA=ON \
                           -DSDL_ALSA_SHARED=ON \
                           -DSDL_JACK=OFF \
                           -DSDL_SNDIO=OFF \
                           -DSDL_DISKAUDIO=OFF \
                           -DSDL_DUMMYAUDIO=OFF \
                           -DSDL_COCOA=OFF \
                           -DSDL_VIVANTE=OFF \
                           -DSDL_DUMMYVIDEO=OFF \
                           -DSDL_HIDAPI_JOYSTICK=ON \
                           -DSDL_PTHREADS=ON \
                           -DSDL_PTHREADS_SEM=ON \
                           -DSDL_DLOPEN=ON \
                           -DSDL_RPATH=OFF \
                           -DSDL_PIPEWIRE=ON \
                           -DSDL_PIPEWIRE_SHARED=ON \
                           -DSDL_PULSEAUDIO=ON \
                           -DSDL_PULSEAUDIO_SHARED=ON \
                           -DSDL_TESTS=OFF \
                           -DSDL_EXAMPLES=OFF"
}

PKG_CMAKE_OPTS_HOST="-DSDL_MALI=OFF \
                     -DSDL_KMSDRM=OFF \
                     -DSDL_X11=OFF \
                     -DSDL_WAYLAND=OFF \
                     -DSDL_TESTS=OFF \
                     -DSDL_EXAMPLES=OFF \
                     -DSDL_UNIX_CONSOLE_BUILD=ON"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
}
