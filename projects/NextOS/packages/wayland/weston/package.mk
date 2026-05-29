# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 NextOS — base CoreELEC coreelec-22 + xwayland/kiosk pro plano

PKG_NAME="weston"
PKG_VERSION="15.0.1"
PKG_SHA256="551d039bfb0c837ba5a4d027cdb8ee16bded0eedb789821f8025d8a64b791f6d"
PKG_LICENSE="MIT"
PKG_SITE="https://wayland.freedesktop.org/"
PKG_URL="https://gitlab.freedesktop.org/wayland/weston/-/releases/${PKG_VERSION}/downloads/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain cairo dbus libdrm libinput libjpeg-turbo libxcb libxkbcommon pango seatd wayland wayland-protocols libxcb-cursor xwayland libXcursor libwebp"
PKG_LONGDESC="Reference implementation of a Wayland compositor"
PKG_PATCH_DIRS+="${DEVICE}"

PKG_BUILD_FLAGS="-ndebug"

if [ "${PIPEWIRE_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" pipewire"
  PKG_MESON_OPTS_TARGET+=" -Dpipewire=true -Dbackend-pipewire=true"
else
  PKG_MESON_OPTS_TARGET+=" -Dpipewire=false -Dbackend-pipewire=false"
fi

PKG_MESON_OPTS_TARGET+=" -Dbackend-drm=true \
                         -Dbackend-headless=false \
                         -Dbackend-rdp=false \
                         -Dbackend-vnc=false \
                         -Dbackend-wayland=true \
                         -Dbackend-x11=false \
                         -Dbackend-default=drm \
                         -Drenderer-gl=true \
                         -Drenderer-vulkan=false \
                         -Dxwayland=true \
                         -Dsystemd=true \
                         -Dremoting=false \
                         -Dshell-desktop=true \
                         -Dshell-ivi=false \
                         -Dshell-kiosk=true \
                         -Dshell-lua=false \
                         -Ddesktop-shell-client-default=weston-desktop-shell \
                         -Dcolor-management-lcms=false \
                         -Dimage-jpeg=true \
                         -Dimage-webp=true \
                         -Dtools=['terminal','debug','info'] \
                         -Ddemo-clients=true \
                         -Dsimple-clients=[] \
                         -Dresize-pool=false \
                         -Dwcap-decode=true \
                         -Dtest-junit-xml=false \
                         -Dtest-skip-is-failure=false \
                         -Ddoc=false \
                         -Ddeprecated-screenshare=false \
                         -Ddeprecated-shell-fullscreen=false \
                         -Ddeprecated-backend-drm-screencast-vaapi=false"

post_makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/weston
    cp ${PKG_DIR}/scripts/weston-config ${INSTALL}/usr/lib/weston

  mkdir -p ${INSTALL}/usr/share/weston
    cp ${PKG_DIR}/config/*ini ${INSTALL}/usr/share/weston 2>/dev/null || \
      cp ${PKG_DIR}/config/weston.ini ${INSTALL}/usr/share/weston

  safe_remove ${INSTALL}/usr/share/wayland-sessions

  for configfile in weston.ini kiosk.ini
  do
    [ -f ${INSTALL}/usr/share/weston/${configfile} ] && \
      sed -i -e "s|@WESTONFONTSIZE@|${WESTONFONTSIZE}|g" ${INSTALL}/usr/share/weston/${configfile}
  done

  if [ "${EMULATION_DEVICE}" = "yes" ] && \
     [ ! "${BASE_ONLY}" == true ]
  then
    cat <<EOF >>${INSTALL}/usr/share/weston/weston.ini

[launcher]
path=/usr/bin/start_es.sh
icon=/usr/config/emulationstation/resources/window_icon_24.png
EOF
  fi
}

post_install() {
  # NextOS Amlogic-no (Valhall): Weston é o modo Wayland opt-in.
  # O service tem ConditionPathExists=/storage/.config/weston-enabled,
  # então é seguro deixar enable — só sobe quando a flag existe.
  if [ "${DEVICE}" = "Amlogic-no" ]; then
    enable_service weston.service
  fi
}
