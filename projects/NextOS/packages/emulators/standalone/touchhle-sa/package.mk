# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="touchhle-sa"
PKG_LICENSE="MPLv2"
PKG_VERSION="d7668926268eded91545fa8ffae6590871ecf5b1"
PKG_SITE="https://github.com/touchHLE/touchHLE"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust SDL2 openal-soft"
PKG_LONGDESC="touchHLE: high-level emulator for iPhone OS apps"
PKG_TOOLCHAIN="manual"

make_target() {
  unset CMAKE
  # A feature "static" (default) do touchHLE compila SDL2 + openal-soft do ZERO
  # via cmake-rs -> bate de frente com nosso GCC/glibc novos (samplerate.h,
  # cstdint no openal, jack.h, LFS, X11...). Em vez de remendar cada um,
  # --no-default-features faz o sdl2-sys usar o SDL2 do sistema (via pkg-config)
  # e o wrapper do openal so linkar -lopenal do sysroot. Mesma receita que ja
  # compila no Amlogic-old do NextOS-Elite-Edition.
  #
  # Rust 1.94 exige -Zunstable-options pra aceitar triple custom
  # (aarch64-nextos-linux-gnu); RUSTC_BOOTSTRAP=1 libera os -Z no rustc stable.
  # opt-level=2 desvia de um bug do vetorizador do LLVM em opt-level=3.
  export RUSTC_BOOTSTRAP=1
  export RUSTFLAGS="-Zunstable-options -C opt-level=2 ${RUSTFLAGS}"

  cargo build \
    --target ${TARGET_NAME} \
    --release \
    --no-default-features
}


makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -rf ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release/touchHLE ${INSTALL}/usr/bin
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
  mkdir -p ${INSTALL}/usr/lib/touchHLE/touchHLE_dylibs
  cp -rf ${PKG_BUILD}/touchHLE_dylibs/lib* ${INSTALL}/usr/lib/touchHLE/touchHLE_dylibs/
  mkdir -p ${INSTALL}/usr/lib/touchHLE/touchHLE_fonts
  cp -rf ${PKG_BUILD}/touchHLE_fonts/LiberationSans-* ${INSTALL}/usr/lib/touchHLE/touchHLE_fonts
  cp -rf ${PKG_BUILD}/touchHLE_default_options.txt ${INSTALL}/usr/lib/touchHLE/
  mkdir -p ${INSTALL}/usr/config/touchHLE
  cp -rf ${PKG_BUILD}/touchHLE_options.txt ${INSTALL}/usr/config/touchHLE/
  chmod +x ${INSTALL}/usr/bin/*
}
