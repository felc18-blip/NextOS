# Comparação Arch-R/NextOS vs CoreELEC

## Sumário

- **Total pacotes locais**: 1071 (697 Arch-R + 477 NextOS, NextOS override)
- **Total pacotes CoreELEC**: 1000
- **Comuns**: 688
- **Versão diferente**: 134
- **Só local**: 383 (custom/forks)
- **Só CoreELEC**: 312 (Amlogic-specific)
- **Blacklist**: systemd, usb-modeswitch (NÃO bumpar)

## Bumps semver — 70 pacotes

### MAJOR bumps (10) — review cuidadoso

| Pacote | Origem | Local | CoreELEC |
|---|---|---|---|
| `btrfs-progs` | nextos | `6.14` | `7.0` |
| `connman` | nextos | `1.43` | `2.0` |
| `gettext` | nextos | `0.24` | `1.0` |
| `glslang` | nextos | `15.1.0` | `16.3.0` |
| `gnupg` | nextos | `1.4.23` | `2.5.20` |
| `icu` | nextos | `74.1` | `78.3` |
| `nasm` | nextos | `2.16.01` | `3.01` |
| `openssh` | nextos | `9.8p1` | `10.3p1` |
| `spirv-llvm-translator` | nextos | `20.1.5` | `22.1.2` |
| `weston` | nextos | `14.0.2` | `15.0.1` |

### MINOR bumps (30)

| Pacote | Origem | Local | CoreELEC |
|---|---|---|---|
| `at-spi2-core` | nextos | `2.45.1` | `2.60.4` |
| `bluez` | nextos | `5.83` | `5.86` |
| `boost` | nextos | `1.86.0` | `1.91.0` |
| `busybox` | nextos | `1.36.1` | `1.38.0` |
| `cairo` | nextos | `1.17.8` | `1.18.4` |
| `fakeroot` | archr | `1.37.2` | `1.38.1` |
| `fcft` | nextos | `3.1.9` | `3.3.3` |
| `flashrom` | archr | `1.5.1` | `1.7.0` |
| `foot` | nextos | `1.19.0` | `1.27.0` |
| `gdk-pixbuf` | nextos | `2.42.10` | `2.44.6` |
| `glew` | nextos | `2.2.0` | `2.3.1` |
| `glib` | archr | `2.88.1` | `2.89.0` |
| `go` | nextos | `1.21.4` | `1.26.3` |
| `gpgme` | nextos | `2.0.0` | `2.1.0` |
| `i2c-tools` | nextos | `4.3` | `4.4` |
| `libgpg-error` | nextos | `1.55` | `1.61` |
| `libinput` | nextos | `1.26.2` | `1.31.2` |
| `libjpeg-turbo` | nextos | `3.0.1` | `3.1.4.1` |
| `libxkbcommon` | nextos | `1.6.0` | `1.13.1` |
| `miniupnpc` | nextos | `2.2.5` | `2.3.3` |
| `ncurses` | nextos | `6.4` | `6.6` |
| `nfs-utils` | nextos | `2.6.4` | `2.9.1` |
| `openssl` | nextos | `3.3.2` | `3.6.2` |
| `rust` | nextos | `1.94.1` | `1.95.0` |
| `sed` | nextos | `4.9` | `4.10` |
| `swig` | nextos | `4.1.1` | `4.4.1` |
| `syncthing` | nextos | `2.0.13` | `2.1.0` |
| `utfcpp` | archr | `4.0.9` | `4.1.1` |
| `vim` | nextos | `9.1.0` | `9.2.0` |
| `wlr-randr` | nextos | `0.4.1` | `0.5.0` |

### PATCH bumps (30)

| Pacote | Origem | Local | CoreELEC |
|---|---|---|---|
| `alsa-lib` | nextos | `1.2.14` | `1.2.15.3` |
| `alsa-ucm-conf` | nextos | `1.2.13` | `1.2.15.3` |
| `alsa-utils` | nextos | `1.2.14` | `1.2.15.2` |
| `bemenu` | nextos | `0.6.15` | `0.6.23` |
| `containerd` | archr | `2.3.0` | `2.3.1` |
| `gtk3` | nextos | `3.24.42` | `3.24.52` |
| `json-glib` | nextos | `1.10.0` | `1.10.8` |
| `libXcursor` | nextos | `1.2.1` | `1.2.3` |
| `libXft` | nextos | `2.3.8` | `2.3.9` |
| `libXi` | archr | `1.8.2` | `1.8.3` |
| `libpcap` | nextos | `1.10.4` | `1.10.6` |
| `libpng` | nextos | `1.6.40` | `1.6.58` |
| `libzip` | nextos | `1.11.1` | `1.11.4` |
| `lua54` | nextos | `5.4.6` | `5.4.8` |
| `lxml` | archr | `6.1.0` | `6.1.1` |
| `m4` | nextos | `1.4.19` | `1.4.21` |
| `mariadb-connector-c` | archr | `3.4.8` | `3.4.9` |
| `mpg123` | nextos | `1.33.0` | `1.33.5` |
| `mtdev` | nextos | `1.1.6` | `1.1.7` |
| `rsync` | archr | `3.4.2` | `3.4.3` |
| `seatd` | nextos | `0.9.0` | `0.9.3` |
| `swaybg` | nextos | `1.2.1` | `1.2.2` |
| `trove-classifiers` | archr | `2026.5.7.17` | `2026.5.22.10` |
| `valgrind` | archr | `3.27.0` | `3.27.1` |
| `vulkan-headers` | nextos | `1.4.347` | `1.4.352` |
| `vulkan-loader` | nextos | `1.4.347` | `1.4.352` |
| `vulkan-tools` | nextos | `1.4.347` | `1.4.352` |
| `waylandpp` | nextos | `1.0.0` | `1.0.1` |
| `wireplumber` | nextos | `0.5.7` | `0.5.14` |
| `xz` | nextos | `5.8.1` | `5.8.3` |

## Commit hash diffs (60) — comparar manual

| Pacote | Origem | Local | CoreELEC |
|---|---|---|---|
| `configtools` | archr | `system` | `28ea239c53a2` |
| `dvblast` | archr | `405917e77f0f` | `3.5` |
| `enet` | nextos | `v1.3.18` | `8d69c5abe4b6` |
| `ffmpeg` | nextos | `272ffca8790f` | `8.1.1` |
| `file` | nextos | `c5eb6d6` | `5.47` |
| `iwlwifi-firmware` | nextos | `6faef0d76cff` | `4faf001a0b3a` |
| `kmsxx` | archr | `403c756c958c` | `73a82c3afb9a` |
| `libimobiledevice` | archr | `73b6fd183872` | `1.4.0` |
| `libnfs` | archr | `6.0.2` | `20971deebdf0` |
| `libretro-81` | archr | `ffc99f27f092` | `fa7094910d04` |
| `libretro-beetle-bsnes` | archr | `f7bfa217cf71` | `e2b7694d12c4` |
| `libretro-beetle-ngp` | archr | `139fe34c8dfc` | `0c81ce8991a4` |
| `libretro-beetle-pce` | archr | `af28fb0385d0` | `ae99235c2139` |
| `libretro-beetle-pce-fast` | archr | `931586f05126` | `9ba79648d6ec` |
| `libretro-beetle-pcfx` | archr | `dd04cef93552` | `650c30ea2203` |
| `libretro-beetle-psx` | archr | `80d3eba272cf` | `42ab8d9943b6` |
| `libretro-beetle-supergrafx` | archr | `a776133c34ae` | `3c6fcd3deded` |
| `libretro-bluemsx` | archr | `572c91856a52` | `0b23b79f6b8c` |
| `libretro-cannonball` | archr | `5137a791d229` | `98cb31638e00` |
| `libretro-cap32` | archr | `dbfa1aa2dc13` | `4abfb8be233b` |
| `libretro-common` | archr | `50c15a88eb74` | `5b5a830baa6c` |
| `libretro-dosbox` | archr | `b7b24262c282` | `4024bf0048c2` |
| `libretro-dosbox-pure` | archr | `64600697f562` | `42485508b705` |
| `libretro-fbneo` | archr | `6ff5e47def71` | `3eeec034f9c7` |
| `libretro-fceumm` | archr | `449db5de6b56` | `3a84a6fd0ba2` |
| `libretro-fuse` | archr | `cad85b7b1b86` | `bce196fb7748` |
| `libretro-gw` | archr | `435e5cfd4bf6` | `91d599b951e7` |
| `libretro-hatari` | archr | `7008194d3f95` | `6aa7c7079b31` |
| `libretro-mesen-s` | archr | `d4fca31a6004` | `1d475abd174d` |
| `libretro-mgba` | archr | `747362c02d2e` | `6dce57eef127` |
| `libretro-mrboom` | archr | `256caa125cdb` | `0e52349c6748` |
| `libretro-nestopia` | archr | `e7b65504ffc7` | `b0fd87dd07e3` |
| `libretro-opera` | archr | `67a29e60a4d1` | `4c4ca6bf741c` |
| `libretro-picodrive` | archr | `d96dd4cd7657` | `cb818111ef2e` |
| `libretro-prboom` | archr | `d25ccfb97390` | `01b7411dab3b` |
| `libretro-prosystem` | archr | `acae250da8d9` | `3f465db9c82f` |
| `libretro-quicknes` | archr | `dbf19f73e3eb` | `7848e1ac22b1` |
| `libretro-sameboy` | archr | `51433012a871` | `06c184f0b186` |
| `libretro-snes9x2002` | archr | `a0709ec7dcd6` | `39e0d8c6daf4` |
| `libretro-snes9x2010` | archr | `f9ae8fd28b13` | `d9cba8a41b34` |
| `libretro-supafaust` | archr | `e25f66765938` | `2b93c0d7dff5` |
| `libretro-tyrquake` | archr | `5486f35371ba` | `0920dec3082d` |
| `libretro-uae` | archr | `c60e42ef9ad4` | `20e019d4405e` |
| `libretro-vbam` | archr | `e8494b56d122` | `c6a055ed2800` |
| `libretro-vecx` | archr | `841229a6a81a` | `8f671cc9d737` |
| `libretro-yabause` | archr | `c35712c5ed33` | `7cb15b8f9eea` |
| `libsndfile` | nextos | `e486f20` | `1.2.2` |
| `libvpx` | nextos | `df655cf4fb6c` | `1.16.0` |
| `misc-firmware` | archr | `868fb584096c` | `3b4bacd07ca8` |
| `ngrep` | archr | `b2e3ba3c5a59` | `1.49.0` |
| `populatefs` | archr | `1.0` | `fa7279f8e6af` |
| `rkbin` | archr | `b0c100f1a260` | `74213af1e952` |
| `snapcast` | archr | `8b7ac6986f2b` | `0.35.0` |
| `udevil` | archr | `f2b715d1d821` | `666e443c3618` |
| `vdr-plugin-epgfixer` | archr | `e88b67b9e9c8` | `9bbf438eb031` |
| `vdr-plugin-iptv` | archr | `f80cd7438957` | `2.6.13` |
| `vdr-plugin-restfulapi` | archr | `be8a3a60af7e` | `92762bb5a9d9` |
| `vdr-plugin-vnsiserver` | archr | `65bfc62b16ff` | `1.8.4` |
| `wayland` | nextos | `c072ae6f5f5b` | `1.25.0` |
| `x264` | archr | `ff620d0c3c4f` | `0480cb05fa18` |

## Diffs anômalos (1)

| Pacote | Origem | Local | CoreELEC |
|---|---|---|---|
| `qt6` | nextos | `${PKG_VERSION_MAJOR}.1` | `6.11.0` |

## Local AHEAD de CoreELEC (3) — NÃO bumpar

| Pacote | Origem | Local (ahead) | CoreELEC (behind) |
|---|---|---|---|
| `grub` | nextos | `2.14-rc1` | `2.14` |
| `sway` | archr | `1.12-rc3` | `1.12` |
| `zlib` | archr | `2.2.4` | `1.3.2` |