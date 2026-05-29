# SPDX-License-Identifier: GPL-2.0-or-later
# NextOS 2026-05-28: aethersx2-mp-sa = MrPurple666/AetherSX2 (leak LGPL 2021,
# libemucore parcial — base que os gamesticks ANBERNIC etc rodam). Build
# compile-only headless (QT_BUILD=OFF) pra validar viabilidade no aarch64
# Arch-R Amlogic-no. Não conflita com aethersx2-sa (AppImage RetroGFX).
#
# Sem Qt6 propositalmente — só o core. Sem binario rodavel; objetivo eh
# provar que linka aarch64 + descobrir blockers reais. Se compilar, vira
# base pra port libretro ou frontend SDL2.

PKG_NAME="aethersx2-mp-sa"
PKG_VERSION="1a5ebd1a8e74e73ee91e96b36faf78650c12b766"
PKG_ARCH="aarch64"
PKG_LICENSE="LGPL-3.0+"
PKG_SITE="https://github.com/MrPurple666/AetherSX2"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="main"
PKG_GIT_CLONE_SUBMODULES="yes"
PKG_DEPENDS_TARGET="toolchain SDL2 zlib libpng libwebp ffmpeg libxml2 zstd vulkan-loader libpcap openssl wxwidgets"
PKG_LONGDESC="MrPurple666/AetherSX2 — leak LGPL 2021, build headless aarch64 (sem Qt6, sem GUI)"
PKG_TOOLCHAIN="cmake"
PKG_PATCH_DIRS+="${DEVICE}"

PKG_CMAKE_OPTS_TARGET=" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=20 \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DPCSX2_CORE=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_fmt=ON \
  -DQT_BUILD=OFF \
  -DDISABLE_PCSX2_WRAPPER=ON \
  -DNO_TRANSLATION=ON \
  -DACTUALLY_ENABLE_TESTS=OFF \
  -DPACKAGE_MODE=OFF \
  -DwxWidgets_CONFIG_EXECUTABLE=${SYSROOT_PREFIX}/usr/bin/wx-config \
"

pre_configure_target() {
  # Desabilita -Werror em arquitetura nao-x86 (PCSX2 e cheio de warning arm)
  # E suprime conflitos GCC 16 vs PCSX2 leak antigo.
  # -fPIC obrigatório pra todos os .o (pra depois extrair libPCSX2.a usável em .so).
  # Sem isso: R_AARCH64_ADR_PREL_PG_HI21 contra std::_Sp_make_shared_tag::__tag
  # ao linkar System.cpp.o/GS.cpp.o/GSTextureCache.cpp.o em pcsx2_libretro.so.
  # -fno-pie no FINAL pra anular -fPIE injetado por HARDENING_SUPPORT do Arch-R
  # (config/optimize:60). GCC respeita o ÚLTIMO flag — -fno-pie + -fPIC depois
  # garante .o PIC-pure pra .so. Sem isso: R_AARCH64_ADR_PREL_PG_HI21 nas refs
  # std::_Sp_make_shared_tag::__tag em System.cpp.o/GS.cpp.o/GSTextureCache.cpp.o.
  export CXXFLAGS="${CXXFLAGS} -fPIC -Wno-error -Wno-error=array-bounds -Wno-error=stringop-overflow -Wno-template-body -Wno-error=template-body -Wno-error=deprecated-enum-enum-conversion -I${PKG_BUILD}/3rdparty/soundtouch/soundtouch -I${PKG_BUILD}/3rdparty/soundtouch/soundtouch/include -I${SYSROOT_PREFIX}/usr/include/harfbuzz -DCONSTINIT= -fno-pie -fPIC"
  export CFLAGS="${CFLAGS} -fPIC -Wno-error -fno-pie -fPIC"

  # Copia headers gui/ (stripados do leak MrPurple666) extraidos do PCSX2
  # publico v1.7.2007 (mesma era LGPL wxWidgets). Necessario pra que .cpp do
  # pcsx2/ (Counters, Elfheader, GameDatabase, MTGS, etc) que ainda referem
  # gui/*.h compilem. Sem isso, build trava em fatal error: gui/*.h.
  if [ -d "${PKG_DIR}/files/gui_full/gui" ]; then
    # copia recursivamente todos os headers gui/ (43 .h em subpastas Dialogs/, Panels/, Debugger/, IPC/, etc)
    mkdir -p "${PKG_BUILD}/pcsx2/gui"
    cp -rH "${PKG_DIR}/files/gui_full/gui/"* "${PKG_BUILD}/pcsx2/gui/" 2>/dev/null || true
  elif [ -d "${PKG_DIR}/files/gui" ]; then
    # fallback legacy
    mkdir -p "${PKG_BUILD}/pcsx2/gui/Dialogs"
    cp -p ${PKG_DIR}/files/gui/*.h ${PKG_BUILD}/pcsx2/gui/
    cp -p ${PKG_DIR}/files/gui/Dialogs/*.h ${PKG_BUILD}/pcsx2/gui/Dialogs/
  fi

  # soundtouch_config.h normalmente gerado por CMake do bundled — stub minimal
  if [ -f "${PKG_DIR}/files/soundtouch_config.h" ]; then
    cp -p "${PKG_DIR}/files/soundtouch_config.h" "${PKG_BUILD}/3rdparty/soundtouch/soundtouch/"
  fi

  # Stubs in-place pra tipos do leak que ficaram com refs órfãs após strip.
  # Não criamos patches separados pq esses arquivos podem mudar quando a gente
  # atualiza o source. Aplicação via sed após unpack do build.
  F1="${PKG_BUILD}/pcsx2/GS/Renderers/HW/GSRendererHW.h"
  if [ -f "$F1" ] && ! grep -q "AccBlendLevel : int" "$F1"; then
    sed -i '/^#pragma once$/a\\nenum class AccBlendLevel : int { Off=0, Basic=1, Medium=2, High=3, Full=4, Ultra=5 };' "$F1"
  fi
  F2="${PKG_BUILD}/pcsx2/GS/Renderers/OpenGL/GSDeviceOGL.h"
  if [ -f "$F2" ] && ! grep -q "struct VSConstantBuffer" "$F2"; then
    sed -i '/^class GSDeviceOGL.*: public GSDevice/a\public:\n\tstruct VSConstantBuffer { char _pad[256]; };\n\tstruct PSConstantBuffer { char _pad[256]; };' "$F2"
  fi
  F3="${PKG_BUILD}/pcsx2/gui/AppConfig.h"
  if [ -f "$F3" ] && ! grep -q "bool DevMode" "$F3"; then
    sed -i '/^class AppConfig$/a\public:\n\tbool DevMode = false;' "$F3"
  fi

  # === wx 3.0 BUNDLED patches pra GCC 16 / C++23 compat ===
  # PCSX2 leak assume layout wxString 3.0; sysroot tem 3.2 incompativel.
  # Em vez de forcar sysroot, patchar bundled pra compilar.

  # operator<<(ostream&, const wchar_t*) foi deletado em C++23 GCC 16.
  # SO afeta wxScopedWCharBuffer overload — fazer via wxString::utf8_str().
  F5="${PKG_BUILD}/3rdparty/wxwidgets3.0/src/common/string.cpp"
  if [ -f "$F5" ] && ! grep -q "GCC16 fix" "$F5"; then
    python3 -c "
fn = '$F5'
src = open(fn).read()
old = '''wxSTD ostream& operator<<(wxSTD ostream& os, const wxScopedWCharBuffer& str)
{
    return os << str.data();
}'''
new = '''wxSTD ostream& operator<<(wxSTD ostream& os, const wxScopedWCharBuffer& str)
{
    // GCC16 fix: operator<<(ostream&, const wchar_t*) deletado em C++23.
    return os << wxString(str.data()).utf8_str().data();
}'''
if old in src:
    open(fn, 'w').write(src.replace(old, new))
    print('wx3.0 string.cpp patched')
"
  fi
}

post_configure_target() {
  # Após CMake gerar build.ninja, patchear -fPIE → -fPIC nas FLAGS.
  # Belt-and-suspenders: env var no pre_configure não vence pq CMake adiciona
  # -fPIE/PIC seleciveis pelo target type. Sed direto no build.ninja garante.
  BNINJA="${PKG_BUILD}/.${TARGET_NAME}/build.ninja"
  if [ -f "$BNINJA" ]; then
    sed -i 's/-fPIE/-fPIC/g' "$BNINJA"
    echo "[aethersx2-mp-sa] patched -fPIE → -fPIC in build.ninja"
  fi
}

makeinstall_target() {
  # Build compile-only: so coletamos os artefatos gerados pra inspecao.
  mkdir -p ${INSTALL}/usr/share/aethersx2-mp-sa
  # libs estaticas/dinamicas do core, se cmake gerou alguma
  find ${PKG_BUILD}/.${TARGET_NAME} -maxdepth 4 \( -name "*.a" -o -name "libpcsx2*" -o -name "libemucore*" \) -exec cp -p {} ${INSTALL}/usr/share/aethersx2-mp-sa/ \; 2>/dev/null || true
  # marcador
  echo "MrPurple666/AetherSX2 @ ${PKG_VERSION} — headless build $(date -u)" > ${INSTALL}/usr/share/aethersx2-mp-sa/BUILD_INFO
}
