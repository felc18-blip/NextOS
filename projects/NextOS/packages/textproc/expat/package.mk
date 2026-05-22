# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/textproc/expat/package.mk

PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
PKG_CMAKE_OPTS_HOST=" -DCMAKE_POLICY_VERSION_MINIMUM=3.5"
