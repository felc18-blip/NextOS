# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2024-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="pyyaml"
PKG_VERSION="6.0.3"
PKG_SHA256="d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
PKG_LICENSE="MIT"
PKG_SITE="https://pypi.org/project/PyYAML/"
PKG_URL="https://files.pythonhosted.org/packages/source/${PKG_NAME:0:1}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="Python3:host setuptools:host"
PKG_LONGDESC="YAML parser and emitter for Python"
PKG_TOOLCHAIN="python"

# NextOS 2026-05-11: PyYAML 6.0.3 dropou _yaml.c pre-gerado upstream — agora
# precisa de Cython instalado pra processar _yaml.pyx -> _yaml.c. Sem Cython
# host, fail com "cc1: fatal error: yaml/_yaml.c: No such file or directory".
# Fix: PYYAML_FORCE_LIBYAML=0 skip a extension C (PyYAML usa pure-python).
# Pure-python e mais lento mas funciona universalmente.
export PYYAML_FORCE_LIBYAML=0
