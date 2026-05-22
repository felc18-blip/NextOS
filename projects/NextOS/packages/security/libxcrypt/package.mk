# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/security/libxcrypt/package.mk

# GCC 16 ficou strict: -Wdiscarded-qualifiers em crypt-{sm3,gost}-yescrypt.c
# libxcrypt 4.5.2 (último release) usa -Werror; disable.
PKG_CONFIGURE_OPTS_TARGET="${PKG_CONFIGURE_OPTS_TARGET} --disable-werror"
