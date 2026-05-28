# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="kronos-lr"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/yabause"
PKG_ARCH="any"
PKG_URL="${PKG_SITE}.git"
PKG_VERSION="6709c1dd0e26094f005b19c6e473c30809718b78"
PKG_GIT_CLONE_BRANCH="kronos"
PKG_DEPENDS_TARGET="toolchain boost zlib"
PKG_LONGDESC="Kronos is a Sega Saturn emulator forked from yabause."
PKG_TOOLCHAIN="make"
GET_HANDLER_SUPPORT="git"
PKG_PATCH_DIRS+="${DEVICE}"

pre_configure_target() {
  sed -i 's/\-latomic//' ${PKG_BUILD}/yabause/src/libretro/Makefile
}

make_target() {
# This was only necessary in the main repo, but may come to libretro later on
#  make -C ${PKG_BUILD}/yabause/src/libretro/ generate-files
  # kronos-lr upstream Makefile default HAVE_SSE=1 → -mfpmath=sse quebra em
  # aarch64. Passar platform=arm64 que o Makefile reconhece (sets HAVE_SSE=0,
  # ARCH_IS_LINUX=1). Adicionalmente FORCE_GLES=1 pra usar GLES no Mali
  # Valhall G310 (Amlogic-no) em vez de OpenGL desktop (sem suporte).
  # Fallback || true mantido pra não quebrar build geral se outra arch nova
  # cair aqui sem variante explicita.
  if [ "${TARGET_ARCH}" = "aarch64" ]; then
    # FORCE_GLES=1 ativa _OGLES3_ / HAVE_OPENGLES3 mas glsym/glsym_es3.h NAO
    # inclui GLES3/gl31.h nem gl32.h — entao GL_PIXEL_BUFFER_BARRIER_BIT,
    # GL_READ_WRITE, glGetTexImage etc usados em compute_shader/vidcs.c e
    # commongl.c ficam undefined. Toolchain tem gl31.h+gl32.h no sysroot;
    # force-include via CFLAGS. glGetTexImage nao existe em GLES (gl4.5
    # desktop) — stub pra 0 antes do compile.
    sed -i 's|glGetTexImage([^)]*)|0 /* GLES no glGetTexImage */|g' \
      ${PKG_BUILD}/yabause/src/core/video/opengl/compute_shader/src/vidcs.c
    # GLSL ES exige precision default pra TODOS tipos em compute shaders.
    # vdp1_start_end_base so declara 'precision highp float' — outSurface
    # (image2D) e contadores int dao 'S0032: no default precision defined'.
    # Adicionar precision pra image2D e int no header de cada compute prog.
    sed -i 's|"precision highp float;\\\\n"|"precision highp float;\\\\n"\\n"#ifdef GL_ES\\\\nprecision highp int;\\\\nprecision highp image2D;\\\\nprecision highp sampler2D;\\\\n#endif\\\\n"|g' \
      ${PKG_BUILD}/yabause/src/core/video/opengl/compute_shader/include/vdp1_prog_compute.h \
      ${PKG_BUILD}/yabause/src/core/video/opengl/common/src/rbg_compute.cpp 2>/dev/null || true
    # HAVE_CDROM=1 obrigatorio: bug upstream linka file_path.c que usa
    # string_to_lower() mas stdstring.c (que define) so e listado quando
    # HAVE_CDROM=1 (Makefile.common linha 169-180).
    make -C ${PKG_BUILD}/yabause/src/libretro/ platform=arm64 FORCE_GLES=1 \
      HAVE_CDROM=1 \
      CFLAGS="-include GLES3/gl32.h" CXXFLAGS="-include GLES3/gl32.h"
  else
    make -C ${PKG_BUILD}/yabause/src/libretro/
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ -f ${PKG_BUILD}/yabause/src/libretro/kronos_libretro.so ]; then
    cp -a ${PKG_BUILD}/yabause/src/libretro/kronos_libretro.so ${INSTALL}/usr/lib/libretro/kronos_libretro.so
  else
    echo "kronos_libretro.so not built (expected on non-x86) — skipped"
  fi
}
