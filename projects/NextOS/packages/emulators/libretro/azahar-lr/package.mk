# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2022-present UnofficialOS (https://github.com/RetroGFX/UnofficialOS)

PKG_NAME="azahar-lr"
PKG_VERSION="b2faa299d5890a65ff979fcb379d2b20d0ca36fc"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/azahar-emu/azahar"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Azahar (Nintendo 3DS) Libretro Core"
PKG_TOOLCHAIN="cmake"

if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  AZAHAR_ENABLE_OPENGL="ON"
  AZAHAR_USE_GLES="yes"
elif [ "${OPENGL_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${OPENGL} glu libglvnd"
  AZAHAR_ENABLE_OPENGL="ON"
else
  AZAHAR_ENABLE_OPENGL="OFF"
fi

if [ "${VULKAN_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_TARGET+=" ${VULKAN}"
  AZAHAR_ENABLE_VULKAN="ON"
else
  AZAHAR_ENABLE_VULKAN="OFF"
fi

PKG_CMAKE_OPTS_TARGET+=" -DBUILD_SHARED_LIBS=OFF \
                         -DENABLE_LIBRETRO=ON \
                         -DENABLE_QT=OFF \
                         -DENABLE_SDL2=OFF \
                         -DENABLE_WEB_SERVICE=OFF \
                         -DENABLE_SCRIPTING=OFF \
                         -DENABLE_OPENAL=OFF \
                         -DENABLE_CUBEB=OFF \
                         -DENABLE_LIBUSB=OFF \
                         -DENABLE_ROOM=OFF \
                         -DENABLE_ROOM_STANDALONE=OFF \
                         -DENABLE_TESTS=OFF \
                         -DUSE_DISCORD_PRESENCE=OFF \
                         -DCITRA_WARNINGS_AS_ERRORS=OFF \
                         -DENABLE_OPENGL=${AZAHAR_ENABLE_OPENGL} \
                         -DENABLE_VULKAN=${AZAHAR_ENABLE_VULKAN} \
                         -DENABLE_SOFTWARE_RENDERER=OFF \
                         -DCMAKE_BUILD_TYPE=Release"

pre_configure_target() {
  # Submodules aninhados (dynarmic -> mcl/tsl-robin-map/oaknut, soundtouch...)
  # nao sao inicializados recursivamente pelo get handler -> CMake reclama
  # "Could NOT find mcl/..." + erro no soundtouch. Inicializa todos.
  ( cd ${PKG_BUILD} && git submodule update --init --recursive 2>/dev/null ) || true

  # GLES FIX (Amlogic-no Mali G310 / qualquer device GLES sem GL desktop):
  # src/citra_libretro/CMakeLists.txt SO define a macro USING_GLES dentro do bloco
  # `if(ANDROID)` (nao ha else). Em build Linux ARM (NAO Android) USING_GLES fica
  # indefinida -> citra_libretro.cpp:559 `#if defined(USING_GLES)` cai no #else ->
  # pede RETRO_HW_CONTEXT_OPENGL_CORE (GL 4.3 desktop) e o RetroArch GLES recusa
  # ("compiled against OpenGLES. Cannot use HW context"). Fix: injetar USING_GLES
  # em ESCOPO GLOBAL (fora de qualquer if), logo apos a ancora global
  # `target_compile_definitions(azahar_libretro PRIVATE HAVE_LIBRETRO)`.
  # (NAO mirar nas linhas USING_GLES HAVE_LIBRETRO_VFS: estao dentro do if ANDROID
  # que nunca executa aqui.) Confirmado: core pede RETRO_HW_CONTEXT_OPENGLES3 e
  # EMULA (NSMB2 na TV, GL_RENDERER Mali-G310, OpenGL ES 3.2, CPU sustentada).
  if [ "${AZAHAR_USE_GLES}" = "yes" ]; then
    sed -i '/^target_compile_definitions(azahar_libretro PRIVATE HAVE_LIBRETRO)$/a target_compile_definitions(azahar_libretro PRIVATE USING_GLES)\ntarget_compile_definitions(azahar_libretro_common PRIVATE USING_GLES)' \
      ${PKG_BUILD}/src/citra_libretro/CMakeLists.txt
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp -v ${PKG_BUILD}/.${TARGET_NAME}/bin/Release/azahar_libretro.so \
    ${INSTALL}/usr/lib/libretro/azahar_libretro.so
}
