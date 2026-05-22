# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

# Use base e2fsprogs without disabling libblkid/libuuid (causes link errors with GCC 15)
. ${ROOT}/packages/sysutils/e2fsprogs/package.mk

# GCC 16 strict: blkid_* funcs em lib/support/plausible.c sem header → implicit-function-declaration
pre_configure_host() {
  export HOST_CFLAGS="${HOST_CFLAGS} -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration"
  export CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration"
}

pre_configure_target() {
  export TARGET_CFLAGS="${TARGET_CFLAGS} -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration"
}
