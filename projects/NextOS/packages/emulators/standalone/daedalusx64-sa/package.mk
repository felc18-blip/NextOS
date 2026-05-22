# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="daedalusx64-sa"
# Fork felc18-blip/daedalusx64-nextos branch nextos-gles2: patches GLES2 ports
# pra Mali-450 (Utgard). Versão validada rodando no NextOS-Elite-Edition.
# Upstream DaedalusX64 oficial assume GLES3/desktop GL — não roda em Mali-450.
PKG_VERSION="832bd3d74bb21fc100180c91dc21e7ef13c9f80f"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/felc18-blip/daedalusx64-nextos"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="nextos-gles2"
PKG_DEPENDS_TARGET="toolchain libfmt SDL2 SDL2_ttf glew glu mesa glm ${OPENGLES}"
PKG_LONGDESC="DaedalusX64 — N64 emulator (NextOS Amlogic, native GLES2 port pra Mali-450 Utgard)"
PKG_PATCH_DIRS+=" ${DEVICE}"

if [ "${ARCH}" = "aarch64" ]; then
  PKG_TOOLCHAIN="manual"
else
  PKG_TOOLCHAIN="cmake"
fi

if [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL}"
elif [ "${OPENGLES_SUPPORT}" = yes ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
fi

makeinstall_target() {
  if [ "${ARCH}" = "aarch64" ]
  then
    mkdir -p ${INSTALL}/usr
    cp -r ${ROOT}/build.${DISTRO}-${DEVICE}.arm/install_pkg/daedalusx64-sa-${PKG_VERSION}/usr/* ${INSTALL}/usr/
    chmod +x ${INSTALL}/usr/bin/*
  else
    mkdir -p ${INSTALL}/usr/bin
    mkdir -p ${INSTALL}/usr/config/DaedalusX64
    cp ${PKG_BUILD}/.${TARGET_NAME}/Source/daedalus ${INSTALL}/usr/config/DaedalusX64/daedalus
    cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin
    cp ${PKG_DIR}/config/* ${INSTALL}/usr/config/DaedalusX64
    cp -r ${PKG_BUILD}/Data/* ${INSTALL}/usr/config/DaedalusX64
    cp -r ${PKG_BUILD}/Source/SysGL/HLEGraphics/n64.psh ${INSTALL}/usr/config/DaedalusX64
    chmod +x ${INSTALL}/usr/bin/*
  fi
}
