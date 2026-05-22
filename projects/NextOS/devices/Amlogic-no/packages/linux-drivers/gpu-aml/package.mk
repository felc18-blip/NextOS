# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)
# Copyright (C) 2026-present NextOS-Retro-Elite-Edition
#
# Per-device override pra Amlogic-no — alinhamento com CE-22 oficial
# (22.0-Piers_alpha3). Builda 2 .ko: valhall_csf (G310 do S905X5/X5M) e
# valhall_jm (G57 do S5). Sem isso, nosso valhall.ko genérico tem alias
# só "arm,mali-valhall" mas o DTB do S905X5-M tem "arm,mali-valhall-csf"
# → kernel não bind → GPU morta → tela preta.
#
# X4 Bifrost (S905X4) NÃO está nessa lista — Amlogic-no atende somente
# Valhall (X5/X5M/S928X). X4 ficou na rom Elite Edition antiga.
#
# Patches NextOS aplicados em pre_make_target (kernel 5.15.196 conflicts):
#   1. -Wall -Werror → -Wall -Wno-error em Makefiles
#   2. in_range() rename (kernel backportou 3-arg macro vs função local 4-arg)
#   3. <linux/devfreq.h> include em platform_gx.c (kernel 5.15 não forwarda)
#   4. devfreq_cooling_power stubs (get_static/dynamic_power viraram get_real_power)

PKG_NAME="gpu-aml"
PKG_VERSION="999551068944c32e5664cb4b5d5b5236fbfaa5ab"
PKG_SHA256=""
PKG_LICENSE="GPL"
PKG_SITE="https://coreelec.org"
PKG_URL="https://github.com/CoreELEC/gpu-aml/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="gpu-aml: Linux drivers for Mali GPUs found in Amlogic Meson SoCs"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

# Lista alinhada com CE-22 oficial — driver:devfreq:csf:front_end
GPU_DRIVERS_LIST="valhall/r44p0:y:n:jm valhall/r44p0:y:y:csf"

pre_make_target() {
  # Aplicar fixes NextOS em todos os dirs r44p0 (compartilhados entre csf/jm)
  for entry in ${GPU_DRIVERS_LIST}; do
    dar=$(echo "${entry}" | awk -F ":" '{print $1}')
    # Remove -Werror em Makefiles
    find ${PKG_BUILD}/${dar} -name "Makefile" -exec sed -i 's|-Wall -Werror|-Wall -Wno-error|g' {} \; 2>/dev/null
    # Rename in_range pra mali_kbase_in_range (kernel 5.15.196 backportou macro)
    f=${PKG_BUILD}/${dar}/kernel/drivers/gpu/arm/midgard/mali_kbase_dummy_job_wa.c
    if [ -f "$f" ] && ! grep -q "mali_kbase_in_range" "$f"; then
      sed -i 's|\bin_range\b|mali_kbase_in_range|g' "$f"
    fi
    # <linux/devfreq.h> include
    pf=${PKG_BUILD}/${dar}/kernel/drivers/gpu/arm/midgard/platform/devicetree/platform_gx.c
    if [ -f "$pf" ] && ! grep -q "<linux/devfreq.h>" "$pf"; then
      sed -i '/^#include <linux\/platform_device.h>/a #include <linux/devfreq.h>' "$pf"
    fi
    # devfreq_cooling_power stubs
    cf=${PKG_BUILD}/${dar}/kernel/drivers/gpu/arm/midgard/platform/devicetree/mali_kbase_config_devicetree.c
    if [ -f "$cf" ] && ! grep -q "NextOS-COOLING-fix" "$cf"; then
      sed -i 's|\.get_static_power = t83x_static_power,|/* NextOS-COOLING-fix: kernel 5.15 unificou em get_real_power *//*\.get_static_power = t83x_static_power,*/|' "$cf"
      sed -i 's|\.get_dynamic_power = t83x_dynamic_power,|/*\.get_dynamic_power = t83x_dynamic_power,*/|' "$cf"
    fi
  done
  true
}

make_target() {
  for driver_arch_rev in ${GPU_DRIVERS_LIST}; do
    driver_version=$(echo "${driver_arch_rev}" | awk -F ":" '{ print $1 }')
    CONFIG_MALI_DEVFREQ="CONFIG_MALI_DEVFREQ=$(echo "${driver_arch_rev}" | awk -F ":" '{ print $2 }')"
    CONFIG_MALI_CSF_SUPPORT="CONFIG_MALI_CSF_SUPPORT=$(echo "${driver_arch_rev}" | awk -F ":" '{ print $3 }')"
    front_end=$(echo "${driver_arch_rev}" | awk -F ":" '{ print $4 }')
    architecture=$(echo "${driver_version}" | awk -F "/" '{ print $1 }')
    echo
    echo "building ${driver_version} (${CONFIG_MALI_CSF_SUPPORT}, front_end=${front_end})"

    kernel_make -C ${PKG_BUILD}/${driver_version}/kernel/drivers/gpu/arm \
      KERNEL_SRC=$(kernel_path) \
      clean

    if [ -n "${front_end}" ]; then
      echo "replace compatible for correct GPU front end (${front_end})"
      sed -i "s|.compatible = \"arm,mali-${architecture}.*\"|.compatible = \"arm,mali-${architecture}-${front_end}\"|" \
        ${PKG_BUILD}/${driver_version}/kernel/drivers/gpu/arm/midgard/mali_kbase_core_linux.c
    fi

    kernel_make -C ${PKG_BUILD}/${driver_version}/kernel/drivers/gpu/arm \
      KERNEL_SRC=$(kernel_path) \
      ${CONFIG_MALI_DEVFREQ} \
      ${CONFIG_MALI_CSF_SUPPORT} \
      KCFLAGS=" -DCONFIG_MALI_LOW_MEM=0"

    kernel_make -C ${PKG_BUILD}/${driver_version}/kernel/drivers/gpu/arm \
      KERNEL_SRC=$(kernel_path) \
      INSTALL_MOD_PATH=${INSTALL}/$(get_kernel_overlay_dir) INSTALL_MOD_STRIP=1 DEPMOD=: \
      modules_install

    [ -n "${front_end}" ] && module_name="mali_kbase_${architecture}_${front_end}.ko" || module_name="mali_kbase_${architecture}.ko"
    mv ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/$(get_module_dir)/extra/midgard/mali_kbase.ko \
       ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/$(get_module_dir)/extra/midgard/${module_name}
  done
}
