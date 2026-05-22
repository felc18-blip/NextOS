# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present NextOS (https://github.com/felc18-blip/NextOS)

CXX ?= gcc
CCFLAGS = -W -Wall -std=c++11 `sdl2-config --cflags`

BINARY = list-guid
LIBRARIES = -lSDL2
SOURCES = "list-guid.cpp"

all:
	$(CXX) $(CFLAGS) $(SOURCES) -o $(BINARY) $(LIBRARIES)

clean:
	rm -f $(BINARY)
