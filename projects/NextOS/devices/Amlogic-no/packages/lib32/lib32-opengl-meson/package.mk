# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-opengl-meson"
PKG_VERSION="$(get_pkg_version opengl-meson)"
PKG_NEED_UNPACK="$(get_pkg_directory opengl-meson)"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="http://openlinux.amlogic.com:8000/download/ARM/filesystem/"
PKG_URL=""
# NextOS Arch-R: o lib32-toolchain do EmuELEC nao existe aqui (32-bit vem do
# build paralelo .arm). Como este pacote so COPIA blobs pre-compilados de
# src/eabihf/ pra /usr/lib32 (nao compila nada), basta o toolchain normal +
# opengl-meson (pros includes/pkgconfig). Sem PKG_BUILD_FLAGS=lib32.
PKG_DEPENDS_TARGET="toolchain opengl-meson"
PKG_LONGDESC="OpenGL ES pre-compiled libraries for Mali GPUs found in Amlogic Meson SoCs."
PKG_PATCH_DIRS+=" $(get_pkg_directory opengl-meson)/patches"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  # IMPORTANTE: este pacote é PKG_ARCH=aarch64 e instala APENAS os blobs
  # 32-bit (eabihf) em ${INSTALL}/usr/lib32 (runtime da imagem). NUNCA pode
  # escrever em ${SYSROOT_PREFIX} (sysroot 64-bit): blob 32-bit ali envenena
  # o link de todo pacote aarch64 que usa -lGLESv2/-lEGL -> erro
  # "skipping incompatible libGLESv2.so". O build ARM 32-bit tem o próprio
  # opengl-meson p/ popular o sysroot 32-bit. (NextOS 2026-05-27)
  mkdir -p ${INSTALL}/usr/lib32
  local DIR_MESON="$(get_build_dir opengl-meson)"
  local DIR_ARM=${DIR_MESON}/lib/eabihf
  local DIR_ARM_local=${PKG_DIR}/src/eabihf
  local SINGLE_LIBMALI='no'

      # NextOS 2026-05-10: CE-22 opengl-meson tarball atual (e8876882) droppou
      # lib32 eabihf (só tem arm64). Usamos blobs locais em src/eabihf/.
      #
      # V15.16 (2026-05-17): adicionado blob Valhall lib32 REAL extraído do
      # tarball CoreELEC SHA 8bfb8ebe38f615907852ada7ff375a04f53f3e81
      # (que EmuELEC upstream usa pro Amlogic-no). 14.7MB ELF 32-bit ARM EABI5
      # MD5 caff744c10fc685766a45ec9d7075b4b. Substitui a cópia FAKE (Bifrost
      # gondul g12b r12p0 disfarçada como valhall) que rodava antes —
      # causa raiz do PortMaster pugwash crash "Could not create EGL window
      # surface" em S905X5/X5M e S928X (gmloader/box86/scummvm lib32 com
      # blob errado → EGL incompatible).
      cp -p ${DIR_ARM_local}/gondul/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.gondul.g12b.so
      cp -p ${DIR_ARM_local}/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.g12a.so
      # Aliases pra cobrir os names que libmali-overlay-setup espera (apontam pro mesmo binário)
      cp -p ${DIR_ARM_local}/gondul/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.gondul.so
      cp -p ${DIR_ARM_local}/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.dvalin.so
      # Valhall REAL blob lib32 r41p0 fbdev — extraído do CoreELEC SHA 8bfb8ebe
      cp -p ${DIR_ARM_local}/valhall/r41p0/fbdev/libMali.so ${INSTALL}/usr/lib32/libMali.valhall.so

  if [[ "${SINGLE_LIBMALI}" == 'no' ]]; then
    ln -sf /var/lib32/libMali.so ${INSTALL}/usr/lib32/libMali.so
  fi

  local LINK_LIST="libmali.so \
                   libmali.so.0 \
                   libEGL.so \
                   libEGL.so.1 \
                   libEGL.so.1.0.0 \
                   libGLES_CM.so.1 \
                   libGLESv1_CM.so \
                   libGLESv1_CM.so.1 \
                   libGLESv1_CM.so.1.0.1 \
                   libGLESv1_CM.so.1.1 \
                   libGLESv2.so \
                   libGLESv2.so.2 \
                   libGLESv2.so.2.0 \
                   libGLESv2.so.2.0.0 \
                   libGLESv3.so \
                   libGLESv3.so.3 \
                   libGLESv3.so.3.0 \
                   libGLESv3.so.3.0.0"

  local LINK_NAME
  for LINK_NAME in ${LINK_LIST}; do
    ln -sf libMali.so ${INSTALL}/usr/lib32/${LINK_NAME}
  done
  # NÃO copiar headers/pkgconfig/symlinks pro sysroot 64-bit (ver nota acima).
}

