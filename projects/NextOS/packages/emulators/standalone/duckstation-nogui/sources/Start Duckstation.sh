#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ArchR (https://github.com/archr-linux/Arch-R)
#
# duckstation-nogui launcher (felc18-blip/duckstation-nextos fork).
# Replaces the upstream duckstation-sa (Qt) on Mali-450 / GLES2 boards,
# since duckstation-sa requires desktop OpenGL which the Mali-450 lacks.
# NoGUI uses SDL2 + EGL Wayland (USE_WAYLAND=ON build) -> renders via
# Mesa lima KMSDRM -> works on S905W/G12 mainline.

. /etc/profile
set_kill set "-9 duckstation-nogui"

# Filesystem vars
IMMUTABLE_CONF_DIR="/usr/config/duckstation"
IMMUTABLE_CONF_FILE="${IMMUTABLE_CONF_DIR}/settings.ini"
CONF_DIR="/storage/.config/duckstation"
CONF_FILE="${CONF_DIR}/settings.ini"
# Fork hardcodes "/emuelec/configs/duckstation" — keep symlink for compat.
EMUELEC_LINK="/emuelec/configs/duckstation"

# Init config dir on first run
[ ! -d "${CONF_DIR}" ] && cp -r "${IMMUTABLE_CONF_DIR}" /storage/.config
[ ! -f "${CONF_FILE}" ] && cp "${IMMUTABLE_CONF_FILE}" "${CONF_FILE}"

# Symlink for fork's hardcoded path
mkdir -p /emuelec/configs
[ ! -L "${EMUELEC_LINK}" ] && ln -sfn "${CONF_DIR}" "${EMUELEC_LINK}"

# Link gamecontrollerdb.txt
ln -sf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt "${CONF_DIR}/gamecontrollerdb.txt"

# Ensure resources/database/etc are reachable from CONF_DIR (immutable backups)
for d in resources database inputprofiles shaders; do
  if [ ! -e "${CONF_DIR}/${d}" ] && [ -d "${IMMUTABLE_CONF_DIR}/${d}" ]; then
    cp -r "${IMMUTABLE_CONF_DIR}/${d}" "${CONF_DIR}/"
  fi
done

# Launch (ROM passed as $1 from ES Scripts entry or game launcher)
if [ -n "${1}" ]; then
  /usr/bin/duckstation-nogui -fullscreen -settings "${CONF_FILE}" -- "${1}"
else
  /usr/bin/duckstation-nogui -fullscreen -settings "${CONF_FILE}"
fi
