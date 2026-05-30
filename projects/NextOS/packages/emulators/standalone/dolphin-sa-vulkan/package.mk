# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)
#
# Dolphin "Vulkan" — variante SEPARADA do dolphin-sa (GL/EGL), só p/ Amlogic-no.
# Renderer Vulkan direto no KMS/DRM (sem compositor) via PR dolphin-emu #13222,
# usando a combinação do EmuELEC GBM_VULKAN (dolphin 3c4d4fcd + patch 003).
# Binário instalado como dolphin-emu-nogui-vulkan p/ coexistir com o dolphin-sa GL.
#
# STATUS 2026-05-30: DESTRAVADO via PONTE DRM/KMS + GBM-import (patch 006), a MESMA
# receita que fez o ppsspp-sa-vulkan rodar Metal Slug XX no blob Mali Valhall. Em vez
# de usar o WSI display_swapchain (stub no blob), bypassamos o swapchain: Dolphin
# renderiza em imagens NORMAIS optimal -> vkCmdCopyImage -> buffer LINEAR GBM importado
# -> KMS pageflip. 3 chaves: queue sem present (patch 004 ja fazia), backbuffer
# finalLayout GENERAL (nao PRESENT_SRC_KHR, que crasha o Mali em img nao-swapchain), e
# render->copy->linear (render direto nao aterrissa no dma_buf). Patches 003/004/005
# (WSI) ficam inertes (o bridge nao cria surface). Helper novo VKDrmPresent.{h,cpp}.
# ⚠️ COMPILA (todos os .o); falta verificar LINK no build do pacote + TESTAR no device
# (iteracoes de debug esperadas, como o ppsspp levou). NAO wired no ES ate testar.
# Ver receita: nextos s905x5/28-PPSSPP-VULKAN-MALI-BRIDGE-BREAKTHROUGH.md (+ doc 14).

PKG_NAME="dolphin-sa-vulkan"
PKG_VERSION="3c4d4fcd09173ea070dc812ab5d64ca3a3af5f29"
PKG_ARCH="aarch64"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/dolphin-emu/dolphin"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain libevdev libdrm mesa ffmpeg zlib libpng lzo libusb zstd ecm openal-soft pulseaudio alsa-lib libfmt hidapi curl vulkan-loader vulkan-headers"
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
