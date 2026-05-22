# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)
# Copyright (C) 2024-present Arch R

PKG_NAME="nextos"
PKG_VERSION=""
PKG_LICENSE="GPLv2"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain autostart gl4es love"
PKG_LONGDESC="Arch R Meta Package"
PKG_TOOLCHAIN="make"

make_target() {
  :
}

makeinstall_target() {

  mkdir -p ${INSTALL}/usr/config/
  rsync -av ${PKG_DIR}/config/* ${INSTALL}/usr/config/
  ln -sf /storage/.config/system ${INSTALL}/system
  find ${INSTALL}/usr/config/system/ -type f -exec chmod o+x {} \;

  mkdir -p ${INSTALL}/usr/bin/

  ### Compatibility links for ports
  ln -s /storage/roms ${INSTALL}/roms

  ### Add some quality of life customizations for hardworking devs.
  if [ -n "${LOCAL_SSH_KEYS_FILE}" ]
  then
    mkdir -p ${INSTALL}/usr/config/ssh
    cp ${LOCAL_SSH_KEYS_FILE} ${INSTALL}/usr/config/ssh/authorized_keys
  fi

  if [ -n "${LOCAL_WIFI_SSID}" ]
  then
    sed -i "s#wifi.enabled=0#wifi.enabled=1#g" ${INSTALL}/usr/config/system/configs/system.cfg
    mkdir -p ${INSTALL}/usr/config/iwd
    cat <<EOF >> ${INSTALL}/usr/config/iwd/${LOCAL_WIFI_SSID}.psk
[Security]
Passphrase=${LOCAL_WIFI_KEY}
EOF
  fi
  # Always install the update script
  mkdir -p $INSTALL/usr/share/bootloader
  find_file_path bootloader/update.sh && cp -av ${FOUND_PATH} ${INSTALL}/usr/share/bootloader
}

post_install() {
  ln -sf nextos.target ${INSTALL}/usr/lib/systemd/system/default.target

  if [ ! -d "${INSTALL}/usr/share" ]
  then
    mkdir "${INSTALL}/usr/share"
  fi
  cp ${PKG_DIR}/sources/post-update ${INSTALL}/usr/share
  chmod 755 ${INSTALL}/usr/share/post-update

  # Issue banner (no ASCII art - nextos-splash handles the graphical logo)
  cat <<EOF >> ${INSTALL}/etc/issue

... Version: ${OS_VERSION} (${OS_BUILD})
... Built: ${BUILD_DATE}

EOF
  cp ${PKG_DIR}/sources/motd ${INSTALL}/etc
  cat ${INSTALL}/etc/issue >> ${INSTALL}/etc/motd

  cp ${PKG_DIR}/sources/scripts/* ${INSTALL}/usr/bin
  chmod 0755 ${INSTALL}/usr/bin/* 2>/dev/null ||:

  ### Fix and migrate to autostart package
  enable_service nextos-autostart.service

  ### ZRAM/Swap and Memory Manager Service
  enable_service nextos-memory-manager.service

  ### Take a backup of the system configuration on shutdown
  enable_service save-sysconfig.service

  sed -i "s#@DEVICENAME@#${DEVICE}#g" ${INSTALL}/usr/config/system/configs/system.cfg

  ### Force libEGL/libGLESv2 symlinks to Mesa direct (bypass libglvnd)
  ### ONLY when no Mali blob (MALI_FAMILY empty) — devices like Amlogic-no
  ### use libMali.so as libEGL.so and would break if we redirect to Mesa.
  ### Reason: libglvnd installs libEGL.so.1.1.0 and overrides Mesa's libEGL.so.1
  ### symlink, but no JSON ICD vendor is provided in /usr/share/glvnd/egl_vendor.d/
  ### → ES/SDL3 can't initialize EGL ("Could not get EGL display"). 2026-05-19.
  if [ -z "${MALI_FAMILY}" ]; then
    for libdir in usr/lib usr/lib32; do
      if [ -f "${INSTALL}/${libdir}/libEGL.so.1.0.0" ]; then
        ln -sf libEGL.so.1.0.0 "${INSTALL}/${libdir}/libEGL.so.1"
      fi
      if [ -f "${INSTALL}/${libdir}/libGLESv2.so.2.0.0" ]; then
        ln -sf libGLESv2.so.2.0.0 "${INSTALL}/${libdir}/libGLESv2.so.2"
      fi
    done
  fi

  ### Compat symlinks archr-* → nextos-* (ES binary has hardcoded archr-config etc
  ### in ApiSystem.cpp via popen; rebuilding ES is heavy, symlinks bridge until
  ### ES source is patched. 2026-05-19.)
  for cmd in config update scraper bluetooth info systems settings; do
    if [ -f "${INSTALL}/usr/bin/nextos-${cmd}" ] && [ ! -e "${INSTALL}/usr/bin/archr-${cmd}" ]; then
      ln -sf "nextos-${cmd}" "${INSTALL}/usr/bin/archr-${cmd}"
    fi
  done

  ### Defaults for non-main builds.
  BUILD_BRANCH="$(git branch --show-current)"
  if [ ! "${BUILD_BRANCH}" = "main" ]
  then
    sed -i "s#samba.enabled=0#samba.enabled=1#g" ${INSTALL}/usr/config/system/configs/system.cfg
    sed -i "s#ssh.enabled=0#ssh.enabled=1#g" ${INSTALL}/usr/config/system/configs/system.cfg
    sed -i "s#wifi.enabled=0#wifi.enabled=1#g" ${INSTALL}/usr/config/system/configs/system.cfg
    sed -i "s#system.loglevel=none#system.loglevel=verbose#g" ${INSTALL}/usr/config/system/configs/system.cfg
  fi

}
