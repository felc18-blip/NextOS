# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present 351ELEC (https://github.com/351ELEC)

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

  # Force lib32 libEGL/libGLESv2 symlinks → Mesa direct (bypass libglvnd).
  # ONLY when no Mali blob (MALI_FAMILY empty) — devices like Amlogic-no use
  # libMali.so as libEGL.so via lib32-opengl-meson; redirecting would break it.
  # The rsync above pulls glvnd's libEGL.so.1 symlink which points to
  # libEGL.so.1.1.0 (glvnd) instead of libEGL.so.1.0.0 (Mesa). Without ICD
  # JSON vendor in /usr/share/glvnd/egl_vendor.d/, gmloader/Love2D/etc fail
  # with "Could not get EGL display". Same fix as nextos/package.mk does for
  # /usr/lib, but applied here because compat/lib32 runs AFTER nextos's
  # post_install and would overwrite our work.
  if [ -z "${MALI_FAMILY}" ]; then
    if [ -f "${INSTALL}/usr/lib32/libEGL.so.1.0.0" ]; then
      ln -sf libEGL.so.1.0.0 "${INSTALL}/usr/lib32/libEGL.so.1"
    fi
    if [ -f "${INSTALL}/usr/lib32/libGLESv2.so.2.0.0" ]; then
      ln -sf libGLESv2.so.2.0.0 "${INSTALL}/usr/lib32/libGLESv2.so.2"
    fi
  fi
}
