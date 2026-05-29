# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS 2026-05-28: pcsx2-d0-sa = d0min8t0r/pcsx2-aarch64.
# Fork PCSX2 era wxWidgets (GPL+LGPL = assinatura pre-Qt) portado pra arm64.
# 15.708 commits. Diferente do MrPurple666 (leak parcial), aqui o source é
# completo — tem chance de gerar binario rodavel SEM Qt6.
#
# Sem Qt6 propositalmente. Frontend = wxWidgets do sistema (Arch-R ja tem).
# Build compile-only pra validar viabilidade no Arch-R Amlogic-no aarch64.

PKG_NAME="pcsx2-d0-sa"
PKG_VERSION="2ab27ef42a36483daec0edecad64b0a2f95e8c07"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL-3.0+ LGPL-3.0+"
PKG_SITE="https://github.com/d0min8t0r/pcsx2-aarch64"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="master"
PKG_GIT_CLONE_SUBMODULES="yes"
PKG_DEPENDS_TARGET="toolchain SDL2 zlib libpng libwebp ffmpeg libxml2 zstd vulkan-loader libpcap openssl wxwidgets"
PKG_LONGDESC="d0min8t0r/pcsx2-aarch64 — fork PCSX2 wxWidgets-era portado pra arm64"
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS+="${DEVICE}"

PKG_CMAKE_OPTS_TARGET=" \
  -DCMAKE_BUILD_TYPE=Release \
  -DQT_BUILD=OFF \
  -DDISABLE_PCSX2_WRAPPER=ON \
  -DNO_TRANSLATION=ON \
  -DACTUALLY_ENABLE_TESTS=OFF \
  -DPACKAGE_MODE=OFF \
  -DwxWidgets_CONFIG_EXECUTABLE=${SYSROOT_PREFIX}/usr/bin/wx-config \
"

pre_configure_target() {
  export CXXFLAGS="${CXXFLAGS} -Wno-error -Wno-error=array-bounds -Wno-error=stringop-overflow"
  export CFLAGS="${CFLAGS} -Wno-error"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin ${INSTALL}/usr/share/pcsx2-d0-sa
  # tenta pegar binarios principais se gerados
  for b in pcsx2 PCSX2 pcsx2-qt; do
    [ -f ${PKG_BUILD}/.${TARGET_NAME}/pcsx2/${b} ] && cp -p ${PKG_BUILD}/.${TARGET_NAME}/pcsx2/${b} ${INSTALL}/usr/bin/ && chmod +x ${INSTALL}/usr/bin/${b}
    [ -f ${PKG_BUILD}/.${TARGET_NAME}/bin/${b}    ] && cp -p ${PKG_BUILD}/.${TARGET_NAME}/bin/${b}    ${INSTALL}/usr/bin/ && chmod +x ${INSTALL}/usr/bin/${b}
  done
  # coleta libs estaticas/dinamicas geradas pra inspecao
  find ${PKG_BUILD}/.${TARGET_NAME} -maxdepth 4 \( -name "libpcsx2*" -o -name "*.so" -o -name "*.a" \) -exec cp -p {} ${INSTALL}/usr/share/pcsx2-d0-sa/ \; 2>/dev/null || true
  echo "d0min8t0r/pcsx2-aarch64 @ ${PKG_VERSION} — headless build $(date -u)" > ${INSTALL}/usr/share/pcsx2-d0-sa/BUILD_INFO
}
