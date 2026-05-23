# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="mednafen"
PKG_VERSION="1.32.1"
PKG_LICENSE="mixed"
PKG_SITE="https://mednafen.github.io/"
# Upstream pull url
#PKG_URL="${PKG_SITE}/releases/files/${PKG_NAME}-${PKG_VERSION}.tar.xz"
# Fork with CHD additions
PKG_URL="https://github.com/sydarn/mednafen/archive/refs/tags/1.32.1-chd.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 flac zstd zlib gptokeyb"
PKG_TOOLCHAIN="configure"

case ${DEVICE} in
  H700|SM8*|Amlogic-nxtos)
    # SDL2 input only (avoids Linux joystick API path) — Mali-450 + gen'rico
    # USB Gamepad mapeia mais limpo via SDL2 que via direct evdev.
    PKG_PATCH_DIRS+=" sdl-input"
  ;;
esac

pre_configure_target() {

export CFLAGS="${CFLAGS} -flto -fipa-pta"
export CXXFLAGS="${CXXFLAGS} -flto -fipa-pta"
export LDFLAGS="${LDFLAGS} -flto -fipa-pta"

# unsupported modules
DISABLED_MODULES+=" --disable-apple2 \
                    --disable-sasplay \
                    --disable-ssfplay"

case ${DEVICE} in
  RK3326|RK3566*|H700)
    DISABLED_MODULES+=" --disable-snes \
                        --disable-ss \
                        --disable-psx"
  ;;
  RK3399)
    DISABLED_MODULES+=" --disable-snes \
                        --disable-ss"
  ;;
  RK3588*)
    DISABLED_MODULES+=" --disable-snes"
  ;;
esac

PKG_CONFIGURE_OPTS_TARGET="${DISABLED_MODULES}"
# Need to update automake files
  (
    cd ..
    sh autogen.sh
  )
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/src/mednafen ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/start_mednafen.sh
  chmod +x ${INSTALL}/usr/bin/mednafen_gen_config.sh

  mkdir -p ${INSTALL}/usr/config/${PKG_NAME}
  cp ${PKG_DIR}/config/common/* ${INSTALL}/usr/config/${PKG_NAME}
  # mednafen.gptk pode ter vindo com bits +x do source tree; reset pro modo correto
  chmod 0644 ${INSTALL}/usr/config/${PKG_NAME}/mednafen.gptk 2>/dev/null || true
}
