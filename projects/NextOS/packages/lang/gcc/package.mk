# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="gcc"
PKG_VERSION="16.1.0"
PKG_SHA256="50efb4d94c3397aff3b0d61a5abd748b4dd31d9d3f2ab7be05b171d36a510f79"
PKG_LICENSE="GPL-2.0-or-later"
PKG_SITE="https://gcc.gnu.org/"
PKG_URL="https://mirrors.kernel.org/gnu/gcc/${PKG_NAME}-${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_BOOTSTRAP="ccache:host autoconf:host binutils:host gmp:host mpfr:host mpc:host zstd:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_DEPENDS_HOST="ccache:host autoconf:host binutils:host gmp:host mpfr:host mpc:host zstd:host glibc libxcrypt"
PKG_DEPENDS_INIT="toolchain"
PKG_LONGDESC="This package contains the GNU Compiler Collection."

if [ "${MOLD_SUPPORT}" = "yes" ]; then
  PKG_DEPENDS_HOST+=" mold:host"
fi

case ${TARGET_ARCH} in
  arm | riscv64)
    OPTS_LIBATOMIC="--enable-libatomic"
    ;;
  *)
    OPTS_LIBATOMIC="--disable-libatomic"
    ;;
esac

GCC_COMMON_CONFIGURE_OPTS="--target=${TARGET_NAME} \
                           --with-sysroot=${SYSROOT_PREFIX} \
                           --with-gmp=${TOOLCHAIN} \
                           --with-mpfr=${TOOLCHAIN} \
                           --with-mpc=${TOOLCHAIN} \
                           --with-zstd=${TOOLCHAIN} \
                           --with-gnu-as \
                           --with-gnu-ld \
                           --enable-plugin \
                           --enable-lto \
                           --enable-gold \
                           --enable-ld=default \
                           --with-linker-hash-style=gnu \
                           --disable-multilib \
                           --disable-nls \
                           --enable-checking=release \
                           --without-ppl \
                           --without-cloog \
                           --disable-libada \
                           --disable-libmudflap \
                           --disable-libitm \
                           --disable-libquadmath \
                           --disable-libgomp \
                           --disable-libmpx \
                           --disable-libssp \
                           --enable-__cxa_atexit"

PKG_CONFIGURE_OPTS_BOOTSTRAP="${GCC_COMMON_CONFIGURE_OPTS} \
                              --enable-cloog-backend=isl \
                              --disable-decimal-float \
                              --disable-gcov \
                              --enable-languages=c \
                              --disable-libatomic \
                              --disable-libgomp \
                              --disable-libsanitizer \
                              --disable-shared \
                              --disable-threads \
                              --without-headers \
                              --with-newlib \
                              ${TARGET_ARCH_GCC_OPTS}"

PKG_CONFIGURE_OPTS_HOST="${GCC_COMMON_CONFIGURE_OPTS} \
                         --enable-languages=c,c++ \
                         ${OPTS_LIBATOMIC} \
                         --enable-decimal-float \
                         --enable-tls \
                         --enable-shared \
                         --disable-static \
                         --enable-long-long \
                         --enable-threads=posix \
                         --disable-libstdcxx-pch \
                         --enable-libstdcxx-time \
                         --enable-clocale=gnu \
                         ${TARGET_ARCH_GCC_OPTS}"

_apply_char8_t_fix() {
  # GCC 15.1.0 libcody usa u8"..." literals que com GCC 16 host (Arch Linux)
  # viram char8_t[] (C++20 default). std::string(const char*) não aceita →
  # netclient.o / packet.o / client.o falham em libcody/cody.hh:113.
  # Plus: GCC 16 libsanitizer/libbacktrace cp-demangle.c usa free() sem
  # include <stdlib.h> → -Werror=implicit-function-declaration. Adicionar
  # -Wno-error pra build passar.
  echo ">>> $1: aplicando -fno-char8_t + -Wno-error pra GCC 16 host"
  export CXX="${CXX:-g++} -fno-char8_t"
  export CXXFLAGS="${CXXFLAGS} -fno-char8_t -Wno-error"
  export CXXFLAGS_FOR_BUILD="${CXXFLAGS_FOR_BUILD} -fno-char8_t -Wno-error"
  export CXXFLAGS_FOR_HOST="${CXXFLAGS_FOR_HOST} -fno-char8_t -Wno-error"
  export CFLAGS="${CFLAGS} -Wno-error -Wno-error=implicit-function-declaration"
  export CFLAGS_FOR_BUILD="${CFLAGS_FOR_BUILD} -Wno-error -Wno-error=implicit-function-declaration"
  export CFLAGS_FOR_TARGET="${CFLAGS_FOR_TARGET} -Wno-error -Wno-error=implicit-function-declaration"
}

pre_make_bootstrap() {
  _apply_char8_t_fix pre_make_bootstrap
  PKG_MAKE_OPTS_BOOTSTRAP="${PKG_MAKE_OPTS_BOOTSTRAP} CXXFLAGS_FOR_BUILD=-fno-char8_t CXXFLAGS=-fno-char8_t"
}

pre_make_host() {
  _apply_char8_t_fix pre_make_host
  PKG_MAKE_OPTS_HOST="${PKG_MAKE_OPTS_HOST} CXXFLAGS_FOR_BUILD=-fno-char8_t CXXFLAGS=-fno-char8_t"
}

post_makeinstall_bootstrap() {
  GCC_VERSION=$(${TOOLCHAIN}/bin/${TARGET_NAME}-gcc -dumpversion)
  DATE="0401$(echo ${GCC_VERSION} | sed 's/\./0/g')"
  CROSS_CC=${TARGET_PREFIX}gcc-${GCC_VERSION}

  rm -f ${TARGET_PREFIX}gcc

  cat >${TARGET_PREFIX}gcc <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${CROSS_CC} "\$@"
EOF

  chmod +x ${TARGET_PREFIX}gcc

  # To avoid cache trashing
  touch -c -t ${DATE} ${CROSS_CC}

  # install lto plugin for binutils
  mkdir -p ${TOOLCHAIN}/lib/bfd-plugins
    ln -sf ../gcc/${TARGET_NAME}/${GCC_VERSION}/liblto_plugin.so ${TOOLCHAIN}/lib/bfd-plugins
}

pre_configure_host() {
  unset CPP
  _apply_char8_t_fix pre_configure_host
}

post_make_host() {
  # fix wrong link
  rm -rf ${TARGET_NAME}/libgcc/libgcc_s.so
  ln -sf libgcc_s.so.1 ${TARGET_NAME}/libgcc/libgcc_s.so

  if [ ! "${BUILD_WITH_DEBUG}" = "yes" ]; then
    ${TARGET_PREFIX}strip ${TARGET_NAME}/libgcc/libgcc_s.so*
    ${TARGET_PREFIX}strip ${TARGET_NAME}/libstdc++-v3/src/.libs/libstdc++.so*
  fi
}

post_makeinstall_host() {
  cp -PR ${TARGET_NAME}/libstdc++-v3/src/.libs/libstdc++.so* ${SYSROOT_PREFIX}/usr/lib

  GCC_VERSION=$(${TOOLCHAIN}/bin/${TARGET_NAME}-gcc -dumpversion)
  DATE="0501$(echo ${GCC_VERSION} | sed 's/\./0/g')"
  CROSS_CC=${TARGET_PREFIX}gcc-${GCC_VERSION}
  CROSS_CXX=${TARGET_PREFIX}g++-${GCC_VERSION}

  rm -f ${TARGET_PREFIX}gcc

  cat >${TARGET_PREFIX}gcc <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${CROSS_CC} "\$@"
EOF

  chmod +x ${TARGET_PREFIX}gcc

  # To avoid cache trashing
  touch -c -t ${DATE} ${CROSS_CC}

  [ ! -f "${CROSS_CXX}" ] && mv ${TARGET_PREFIX}g++ ${CROSS_CXX}

  cat >${TARGET_PREFIX}g++ <<EOF
#!/bin/sh
${TOOLCHAIN}/bin/ccache ${CROSS_CXX} "\$@"
EOF

  chmod +x ${TARGET_PREFIX}g++

  # To avoid cache trashing
  touch -c -t ${DATE} ${CROSS_CXX}

  # install lto plugin for binutils
  mkdir -p ${TOOLCHAIN}/lib/bfd-plugins
    ln -sf ../gcc/${TARGET_NAME}/${GCC_VERSION}/liblto_plugin.so ${TOOLCHAIN}/lib/bfd-plugins
}

configure_target() {
  : # reuse configure_host()
}

make_target() {
  : # reuse make_host()
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
    cp -P ${PKG_BUILD}/.${HOST_NAME}/${TARGET_NAME}/libgcc/libgcc_s.so* ${INSTALL}/usr/lib
    cp -P ${PKG_BUILD}/.${HOST_NAME}/${TARGET_NAME}/libstdc++-v3/src/.libs/libstdc++.so* ${INSTALL}/usr/lib
    if [ "${OPTS_LIBATOMIC}" = "--enable-libatomic" ]; then
      cp -P ${PKG_BUILD}/.${HOST_NAME}/${TARGET_NAME}/libatomic/.libs/libatomic.so* ${INSTALL}/usr/lib
    fi
}

configure_init() {
  : # reuse configure_host()
}

make_init() {
  : # reuse make_host()
}

makeinstall_init() {
  mkdir -p ${INSTALL}/usr/lib
    cp -P ${PKG_BUILD}/.${HOST_NAME}/${TARGET_NAME}/libgcc/libgcc_s.so* ${INSTALL}/usr/lib
}
