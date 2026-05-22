# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/web/curl/package.mk

PKG_CMAKE_OPTS_TARGET="${PKG_CMAKE_OPTS_TARGET//\/run\/libreelec\/cacert.pem/\/run\/nextos\/cacert.pem}"
