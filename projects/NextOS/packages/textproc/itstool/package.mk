# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

. ${ROOT}/packages/textproc/itstool/package.mk

pre_configure_host() {
  export PYTHONPATH="${TOOLCHAIN}/python:${PYTHONPATH}"
}
