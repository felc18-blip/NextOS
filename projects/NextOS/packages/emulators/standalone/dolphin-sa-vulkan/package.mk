# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
#
# Dolphin "Vulkan" — variante SEPARADA do dolphin-sa (GL/EGL), só p/ Amlogic-no.
# Renderer Vulkan direto no KMS/DRM (sem compositor) via PR dolphin-emu #13222,
# usando a combinação do EmuELEC GBM_VULKAN (dolphin 3c4d4fcd + patch 003).
# Binário instalado como dolphin-emu-nogui-vulkan p/ coexistir com o dolphin-sa GL.
#
# ⚠️ STATUS 2026-05-29: BLOQUEADO no blob atual. Compila e inicializa o device
# Vulkan, mas o blob `libMali.valhall.g310 r44p0` (CoreELEC/opengl-meson, mesmo
# que o EmuELEC usa) NAO expoe `VK_KHR_display_swapchain` -> vkCreateSwapchainKHR
# na display surface falha com VK_ERROR_EXTENSION_NOT_PRESENT. Patches 004/005
# contornam present-queue + queries de surface, mas o swapchain em si e' limite
# do driver. Pronto pra um blob futuro (r51p0+) que inclua display_swapchain.
# NAO esta wired no ES (dormiente). Solucao em producao = dolphin-sa (GL/EGL).
# Ver receita: nextos s905x5/14-DOLPHIN-DRM-EGL-VULKAN-KMS-RECEITA.md

PKG_NAME="dolphin-sa-vulkan"
PKG_VERSION="3c4d4fcd09173ea070dc812ab5d64ca3a3af5f29"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/dolphin-emu/dolphin"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libevdev libdrm ffmpeg zlib libpng lzo libusb zstd ecm openal-soft pulseaudio alsa-lib libfmt hidapi curl vulkan-loader vulkan-headers"
PKG_LONGDESC="Dolphin (GC/Wii) — build Vulkan KMS/DRM (PR #13222 / EmuELEC GBM_VULKAN) para Amlogic-no"
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS="Amlogic-no"

if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
elif [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
fi

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release \
                           -DMBEDTLS_FATAL_WARNINGS=OFF \
                           -DDISTRIBUTOR=NextOS \
                           -DENABLE_NOGUI=ON \
                           -DENABLE_QT=OFF \
                           -DENABLE_EGL=ON \
                           -DENABLE_X11=OFF \
                           -DENABLE_DRM=ON \
                           -DENABLE_VULKAN=ON \
                           -DENABLE_EVDEV=ON \
                           -DUSE_DISCORD_PRESENCE=OFF \
                           -DBUILD_SHARED_LIBS=OFF \
                           -DLINUX_LOCAL_DEV=OFF \
                           -DENABLE_PULSEAUDIO=ON \
                           -DENABLE_ALSA=ON \
                           -DENABLE_TESTS=OFF \
                           -DENABLE_LLVM=OFF \
                           -DENABLE_ANALYTICS=OFF \
                           -DENABLE_LTO=ON \
                           -DENCODE_FRAMEDUMPS=OFF \
                           -DENABLE_AUTOUPDATE=OFF \
                           -DUSE_MGBA=OFF \
                           -DENABLE_CLI_TOOL=OFF \
                           -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

  # workaround VMA cstdint (se a versão precisar)
  VMA=${PKG_BUILD}/Externals/VulkanMemoryAllocator/include/vk_mem_alloc.h
  [ -f "${VMA}" ] && sed -i 's~#include <cstdlib>~#include <cstdlib>\n#include <cstdint>~g' "${VMA}"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  # binário renomeado p/ NÃO conflitar com o dolphin-sa (GL)
  cp -f ${PKG_BUILD}/.${TARGET_NAME}/Binaries/dolphin-emu-nogui ${INSTALL}/usr/bin/dolphin-emu-nogui-vulkan
  cp -rf ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin 2>/dev/null || true
  chmod +x ${INSTALL}/usr/bin/*
}
