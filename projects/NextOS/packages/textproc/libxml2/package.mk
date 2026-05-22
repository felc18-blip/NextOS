# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/textproc/libxml2/package.mk

PKG_DEPENDS_HOST="${PKG_DEPENDS_HOST} doxygen:host"

PKG_CMAKE_OPTS_ALL="-DBUILD_SHARED_LIBS=ON \
                    -DLIBXML2_WITH_ICONV=OFF \
                    -DLIBXML2_WITH_ICU=OFF \
                    -DLIBXML2_WITH_LZMA=OFF \
                    -DLIBXML2_WITH_TESTS=OFF \
                    -DLIBXML2_WITH_THREADS=ON \
                    -DLIBXML2_WITH_ZLIB=ON"

PKG_CMAKE_OPTS_HOST="${PKG_CMAKE_OPTS_ALL} \
                     -DLIBXML2_WITH_PYTHON=ON"

PKG_CMAKE_OPTS_TARGET="${PKG_CMAKE_OPTS_ALL} \
                       -DLIBXML2_WITH_PYTHON=OFF"
