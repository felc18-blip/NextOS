# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="portmaster"
PKG_VERSION="2026.04.01-1426"
PKG_ARCH="arm aarch64"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/PortsMaster/PortMaster-GUI"
PKG_URL="https://github.com/PortsMaster/PortMaster-GUI/releases/download/${PKG_VERSION}/PortMaster.zip"
PKG_DEPENDS_TARGET="toolchain nextos-hotkey gamecontrollerdb oga_controls control-gen xmlstarlet list-guid gst-plugins-base Python3 xz portmaster-compat-libs"
PKG_LONGDESC="Portmaster - a simple tool that allows you to download various game ports"
PKG_TOOLCHAIN="manual"

COMPAT_URL="https://github.com/felc18-blip/nextos-packages/raw/main/compat.zip"

makeinstall_target() {
  export STRIP=true

  mkdir -p ${INSTALL}/usr/config/PortMaster
    cp -a ${PKG_DIR}/sources/* ${INSTALL}/usr/config/PortMaster

  mkdir -p ${INSTALL}/usr/bin
    cp -a ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

  mkdir -p ${INSTALL}/usr/config/PortMaster/release
    curl -Lo ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip ${PKG_URL}

  ### Register NextOS as a known PortMaster platform.
  ### PortMaster's HM_PLATFORMS dict doesn't recognize 'nextos' (set from
  ### /etc/os-release NAME), so it falls back to PlatformBase whose
  ### gamelist_file() returns None — gamelist_add() then skips silently and
  ### installed ports show without <image>/<desc>. Adding PlatformNextOS
  ### (inherits PlatformEmuELEC for gamelist_file, drops MOVE_PM_BASH so
  ### .sh launchers stay in /storage/roms/ports/) fixes this.
  PMTMP=$(mktemp -d)
  unzip -qq ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip -d ${PMTMP}
  PYLIBS_ZIP="${PMTMP}/PortMaster/pylibs.zip"
  PYLIBS_DIR="${PMTMP}/pylibs-extracted"
  if [ -f "${PYLIBS_ZIP}" ]; then
    mkdir -p "${PYLIBS_DIR}"
    unzip -qq "${PYLIBS_ZIP}" -d "${PYLIBS_DIR}"
    PL_PY="${PYLIBS_DIR}/pylibs/harbourmaster/platform.py"
    if [ -f "${PL_PY}" ] && ! grep -q "class PlatformNextOS" "${PL_PY}"; then
      python3 - "${PL_PY}" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
cls = '''class PlatformNextOS(PlatformEmuELEC):
    # Inherits gamelist_file() = scripts_dir/gamelist.xml so images/desc
    # land in the right XML, but disables MOVE_PM_BASH so .sh launchers
    # stay in ports/ (NextOS does not have /emuelec/scripts/).
    MOVE_PM_BASH = False
    ES_NAME = "emulationstation"


'''
needle = "HM_PLATFORMS = {"
if cls.split("\n")[0] not in s:
    s = s.replace(needle, cls + needle)
    s = s.replace("'emuelec':   PlatformEmuELEC,",
                  "'emuelec':   PlatformEmuELEC,\n    'nextos':    PlatformNextOS,")
    open(p, "w").write(s)
    print("[pylibs.zip] platform.py: PlatformNextOS registered")
PY
    fi
    ( cd "${PYLIBS_DIR}" && zip -qq -r "${PYLIBS_ZIP}.new" . )
    mv "${PYLIBS_ZIP}.new" "${PYLIBS_ZIP}"
    rm -rf "${PYLIBS_DIR}"
  fi
  ( cd ${PMTMP} && zip -qq -r PortMaster.zip PortMaster )
  mv ${PMTMP}/PortMaster.zip ${INSTALL}/usr/config/PortMaster/release/PortMaster.zip
  rm -rf ${PMTMP}

  mkdir -p ${INSTALL}/usr/lib/compat
    curl -Lo ${PKG_BUILD}/compat.zip ${COMPAT_URL}
    unzip -qq ${PKG_BUILD}/compat.zip -d ${INSTALL}/usr/lib/compat

    # libcodec2.so.0.9, libx264.so.160 e libx265.so.192 (SONAMEs do
    # Debian 11 listados no PortMaster_CFW.md) sao instaladas como
    # arquivos reais pelo pacote portmaster-compat-libs (dependencia).
}
