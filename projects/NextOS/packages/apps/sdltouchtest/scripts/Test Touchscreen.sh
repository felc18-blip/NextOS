#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024 NextOS (https://github.com/nextos-linux/NextOS)

source /etc/profile

set_kill set "-9 sdltouchtest"

/usr/bin/sdltouchtest
