# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present 351ELEC (https://github.com/351ELEC)
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
#
# Amlogic-no device override: o rsync de ${LIBROOT}/usr/lib/* arrasta os
# symlinks que libglvnd:lib32 deixou pra libEGL.so.1 -> libEGL.so.1.1.0 etc.
# Pra esse device, libEGL precisa apontar pra libMali.so (libMali blob faz
# o papel de EGL/GLES via opengl-meson). Reescreve os symlinks DEPOIS do
# rsync pra forçar isso.

PKG_NAME="lib32"
PKG_VERSION="1.0"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_DEPENDS_TARGET="toolchain retroarch SDL2 SDL3 libsndfile libmodplug gl4es"
PKG_LONGDESC="ARM 32bit bundle for aarch64"
PKG_TOOLCHAIN="manual"
PKG_BUILD_FLAGS="-strip"

makeinstall_target() {
  case ${TARGET_ARCH} in
    aarch64)
      LIBARCH="arm"
      LDSO="ld-linux-armhf.so.3"
      ;;
  esac

  cd ${PKG_BUILD}
  LIBROOT="${ROOT}/build.${DISTRO}-${DEVICE}.${LIBARCH}/image/system/"
  mkdir -p ${INSTALL}/usr/lib32
  rsync -al ${LIBROOT}/usr/lib/* ${INSTALL}/usr/lib32 >/dev/null 2>&1
  rsync -al ${LIBROOT}/usr/lib32/* ${INSTALL}/usr/lib32 >/dev/null 2>&1
  mkdir -p ${INSTALL}/usr/lib
  ln -s /usr/lib32/${LDSO} ${INSTALL}/usr/lib/${LDSO}

  mkdir -p "${INSTALL}/etc/ld.so.conf.d"
  echo "/usr/lib32" > "${INSTALL}/etc/ld.so.conf.d/${LIBARCH}-lib32.conf"

  mkdir -p ${INSTALL}/usr/bin
  cp ${LIBROOT}/usr/bin/ldd ${INSTALL}/usr/bin/ldd32

  # Amlogic-no usa libMali blob: força lib32 EGL/GLES* symlinks pra libMali.so
  # (rsync acima trouxe stubs do glvnd que apontam pra libEGL.so.1.1.0 etc).
  # libMali.so é um symlink -> /var/lib/libMali.so (overlay runtime), então
  # usar -L em vez de -e pra detectar o symlink broken em build-time.
  if [ -L "${INSTALL}/usr/lib32/libMali.so" ] || [ -e "${INSTALL}/usr/lib32/libMali.so" ]; then
    for stem in libEGL libGLESv2 libGLESv1_CM; do
      for suffix in .so .so.1 .so.2 .so.1.0.0 .so.1.1.0 .so.2.0.0 .so.1.2.0; do
        target="${INSTALL}/usr/lib32/${stem}${suffix}"
        if [ -L "${target}" ] || [ -e "${target}" ]; then
          ln -sf libMali.so "${target}"
        fi
      done
    done
  fi
}
