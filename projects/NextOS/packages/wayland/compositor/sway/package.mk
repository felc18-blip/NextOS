# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="sway"
PKG_LICENSE="MIT"
PKG_SITE="https://swaywm.org/"
PKG_DEPENDS_TARGET="toolchain glib wayland wayland-protocols libdrm libxkbcommon libinput cairo pango libjpeg-turbo dbus json-c wlroots gdk-pixbuf swaybg foot bemenu xcb-util-wm xwayland xkbcomp xterm libthai"
PKG_LONGDESC="i3-compatible Wayland compositor"
PKG_TOOLCHAIN="meson"

case ${DEVICE} in
  RK3588|SDM845)
    PKG_VERSION="1.9"
    PKG_URL="https://github.com/swaywm/sway/archive/${PKG_VERSION}.zip"
  ;;
  RK3326|RK3566|S922X|Amlogic-no)
    # 2026-05-29 NextOS: pareia com wlroots 0.19.3-rk (fork ROCKNIX com hack
    # mali_buffer_sharing). sway 1.12 exige wlroots >=0.20.0 mas o fork rk
    # vai só até 0.19.3-rk. Sem isso o sway linka contra libwlroots-0.20.so
    # que não existe no rootfs e crasha exit 127 ("cannot open shared object").
    # Patches 1001/1002 aplicam limpos em 1.11 também (validado dry-run).
    PKG_VERSION="1.11"
    PKG_SHA256="034ec4519326d6af5275814700dde46e852c5174614109affe4c86b2fbee062a"
    PKG_URL="https://github.com/swaywm/sway/archive/${PKG_VERSION}.tar.gz"
  ;;
  *)
    # 2026-05-28 bump CoreELEC 89a6964f — sway 1.11 -> 1.12 (drop setuid patch).
    # Patches renomeados: sway-100.01-static-ipc-socket.patch -> 1001-...,
    # adicionado 1002-do-not-use-git-version.patch.
    PKG_VERSION="1.12"
    PKG_SHA256="29ca7caac960d13e02d8213418d91a5422c7c23102a283ceab944c57c5e1efcf"
    PKG_URL="https://github.com/swaywm/sway/archive/${PKG_VERSION}.tar.gz"
  ;;
esac

# to enable xwayland package: https://gitlab.freedesktop.org/xorg/lib/libxcb-wm/-/tree/master/icccm?ref_type=heads

PKG_MESON_OPTS_TARGET="-Ddefault-wallpaper=false \
                       -Dzsh-completions=false \
                       -Dbash-completions=false \
                       -Dfish-completions=false \
                       -Dswaybar=true \
                       -Dswaynag=true \
                       -Dtray=disabled \
                       -Dgdk-pixbuf=enabled \
                       -Dman-pages=disabled \
                       -Dsd-bus-provider=auto"

pre_configure_target() {
  # sway does not build without -Wno flags as all warnings being treated as errors
  export TARGET_CFLAGS=$(echo "${TARGET_CFLAGS} -Wno-unused-variable")
}

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway.sh     ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/sway-config ${INSTALL}/usr/lib/sway
  mkdir -p ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/autostart/111-sway-init     ${INSTALL}/usr/lib/autostart/common
    cp ${PKG_DIR}/scripts/sway-touch.sh     ${INSTALL}/usr/bin

  chmod +x ${INSTALL}/usr/bin/sway*

  # install config & wallpaper
  mkdir -p ${INSTALL}/usr/share/sway
    cp ${PKG_DIR}/config/* ${INSTALL}/usr/share/sway

  # clean up
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/share/wayland-sessions

  case ${DEVICE} in
    RK3588|SDM845)
      sed -i '/allow_tearing/d' ${INSTALL}/usr/lib/autostart/common/111-sway-init
    ;;
  esac
}

post_install() {
  enable_service sway-touch.service
}
