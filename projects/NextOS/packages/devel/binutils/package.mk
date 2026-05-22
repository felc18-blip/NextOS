# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/devel/binutils/package.mk

# gprofng fails to build with GCC 15 / glibc _Generic conflict
PKG_CONFIGURE_OPTS_HOST="${PKG_CONFIGURE_OPTS_HOST} --disable-gprofng"
