# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026-present NextOS-Retro-Elite-Edition
#
# Per-device override for Amlogic-no (S905X4/X5/X5-M family).
# Adds generation of *_env text files alongside the binary u-boot scripts.
# The newer Amlogic u-boots (S7D / S905X5-M, Ugoos AM9, X88 Pro X5M, Xiaomi
# 3rd gen TV box) call `env import -t` on cfgload_env via aml_autoscript —
# the binary cfgload alone fails to boot on those chips. This generates the
# missing cfgload_env text file that the bootloader/mkimage already expects.
#
# Diff vs global packages/tools/u-boot-script/package.mk: only adds the
# inner cfgload-detect block after the mkimage call. Old/ng/nxtos devices
# don't have this override and continue using the unchanged global package.

PKG_NAME="u-boot-script"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_DEPENDS_TARGET="u-boot-tools:host"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Compile scripts for u-boot environment (Amlogic-no with X5M cfgload_env)."

PKG_NEED_UNPACK="${PROJECT_DIR}/${PROJECT}/bootloader"
[ -n "${DEVICE}" ] && PKG_NEED_UNPACK+=" ${PROJECT_DIR}/${PROJECT}/devices/${DEVICE}/bootloader"

make_target() {
  if find_dir_path bootloader/scripts; then
    for src in ${FOUND_PATH}/*.src; do
      base=$(basename ${src} .src)
      mkimage -A ${TARGET_KERNEL_ARCH} -O linux -T script -C none -d "${src}" "${base}"
      # S905X5-M compat: also emit text-format *_env consumable by env import
      if echo "${base}" | grep -q cfgload; then
        echo "u-boot-script (Amlogic-no): generating ${base}_env (X5M boot fix)"
        printf 'ceboot=' > "${base}_env"
        sed -e 's/^[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "${src}" \
          | awk 'NR>1{printf "; \\\n"}{printf "%s",$0}' >> "${base}_env"
      fi
    done
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader
    cp -a ${PKG_BUILD}/* ${INSTALL}/usr/share/bootloader/
}
