# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026-present NextOS (https://github.com/felc18-blip/NextOS)

PKG_NAME="doxygen"
PKG_VERSION="1.13.2"
PKG_SHA256="3a25e3386c26ea5494c784e946327225debfbc5dbfa8b13549010a315aace66d"
PKG_LICENSE="GPL-2.0"
PKG_SITE="https://www.doxygen.nl"
PKG_URL="https://www.doxygen.nl/files/${PKG_NAME}-${PKG_VERSION}.src.tar.gz"
PKG_DEPENDS_HOST="cmake:host flex:host bison:host Python3:host"
PKG_LONGDESC="Doxygen is a documentation system for C++, C, Java, IDL and others"
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-cfg-libs:host -gold"

PKG_CMAKE_OPTS_HOST="-DCMAKE_INSTALL_PREFIX=${TOOLCHAIN} \
                     -Dbuild_app=OFF \
                     -Dbuild_search=OFF \
                     -Dbuild_doc=OFF \
                     -Dbuild_xmlparser=OFF"
