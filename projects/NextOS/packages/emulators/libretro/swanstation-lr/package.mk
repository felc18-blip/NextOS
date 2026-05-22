# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)
# Maintenance 2020 351ELEC team (https://github.com/fewtarius/351ELEC)

PKG_NAME="swanstation-lr"
PKG_VERSION="4d309c05fd7bdc503d91d267bd542edb8d192b09"
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/libretro/swanstation"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host"
PKG_LONGDESC="SwanStation - PlayStation 1, aka. PSX Emulator"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-lto"

if [ ! "${OPENGL}" = "no" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

if [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

pre_configure_target() {
 PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO_CORE=ON "
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/swanstation_libretro.so ${INSTALL}/usr/lib/libretro/

  # Default GPU renderer = Software. Mesa Lima (Mali-450) reporta GLES 3.1
  # mas swanstation hardware renderer pede GLES 3.2+ ou OpenGL desktop —
  # core falha EGL config e RA cai pra KMSDRM que conflita com sway. Em
  # Software o core renderiza CPU-only e fluxo Wayland inteiro funciona.
  # Usuario pode trocar pra Hardware (OpenGL/Vulkan) via menu RA se hardware
  # suportar (X5 Valhall talvez consiga GLES 3.2).
  mkdir -p ${INSTALL}/usr/config/retroarch/config/SwanStation
  cat > ${INSTALL}/usr/config/retroarch/config/SwanStation/SwanStation.opt <<'OPT'
swanstation_GPU_Renderer = "Software"
swanstation_GPU_UseSoftwareRendererForReadbacks = "false"
OPT
}
