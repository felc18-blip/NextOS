<p align="center">
  <strong>NextOS — distro retro gaming para TV boxes Amlogic Valhall.</strong>
</p>

<p align="center">
  <a href="https://github.com/felc18-blip/NextOS/releases/latest"><img src="https://img.shields.io/github/release/felc18-blip/NextOS.svg?color=0080FF&label=latest&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/felc18-blip/NextOS/commits"><img src="https://img.shields.io/github/commit-activity/m/felc18-blip/NextOS?color=0080FF&style=flat-square" alt="Activity"></a>
</p>

---

NextOS é uma distro Linux derivada de [Arch-R](https://github.com/archr-linux/Arch-R) (que por sua vez vem de ROCKNIX/JELOS/LibreELEC), focada em **TV boxes Amlogic** com GPU Mali Valhall. Roda EmulationStation sobre **sway + Wayland nativo** usando o blob libMali Valhall da CoreELEC (com suporte EGL Wayland direto via `eglBindWaylandDisplayWL`).

## Hardware suportado

NextOS atende **exclusivamente** TV boxes com SoC Amlogic Valhall:

| SoC | DT family | GPU | Exemplo de board |
|-----|-----------|-----|------------------|
| **S905X5** | sc2 / s6 | Mali-G310 (Valhall, CSF) | Vontar X5, X96 X5 |
| **S905X5M** | s7d | Mali-G310 (Valhall, CSF) | Odroid C5, Vontar X5M |
| **S928X** | s5 | Mali-G57 (Valhall, JM) | X96 X10 Pro, Ugoos AM8 |

**Fora de escopo:**
- **S905X4** (sc2 Bifrost Mali-G31): meson-drm 5.15 + libmali g24p0 + kbase 5.15 não fecha em Wayland nem KMSDRM (GPU fault no primeiro draw). Continua na rom Elite Edition antiga.
- **S905W / S905X3 / antigos**: cobertos por outros projects do mesmo fork (`Amlogic-old`, `Amlogic-nxtos`).

## Stack técnica

- **Kernel**: amlogic-5.15.196 (BSP CoreELEC) com patches NextOS
- **Driver kernel Mali**: `mali_kbase` vendor Amlogic (gpu-aml) — builda 3 .ko: bifrost (X4 boot fallback), valhall_csf (X5/X5M), valhall_jm (S928X)
- **Userspace GPU**: blob `libMali.valhall.{g310,g57}.so` r44p0 wayland-drm-dmaheap (CoreELEC)
- **Compositor**: `sway` (wlroots 0.17.4, GLES2 renderer)
- **Frontend**: EmulationStation via `essway.service` (Wayland client, `SDL_VIDEODRIVER=wayland`)
- **Audio**: PipeWire
- **Splash boot**: `nextos-splash` (binário escreve logo NextOS em `/dev/fb0` via libm, sem libdrm)
- **Bootloader**: u-boot vendor Amlogic + `aml_autoscript` / `cfgload` (TV box path)

`MALI_WAYLAND_AFBC=0` é setado nos quirks pra forçar alocação LINEAR no plane primário (meson-drm rejeita modifiers AFBC no atomic commit).

## Quick start

Download da última release em [Releases](https://github.com/felc18-blip/NextOS/releases/latest).

**Grava em microSD ≥ 8 GB:**

```bash
gunzip -c NextOS-Amlogic-no.aarch64-*-Generic.img.gz | \
  sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

**Troca o DTB pro seu board** (default Generic é S905X5-M 4GB 1Gbit; substitua se necessário):

```bash
sudo mount /dev/sdX1 /mnt/boot
sudo cp /mnt/boot/device_trees/<seu-board>.dtb /mnt/boot/dtb.img
sudo umount /mnt/boot
```

DTBs disponíveis em `/mnt/boot/device_trees/`. Procura por prefixo `sc2_`, `s7d_`, `s5_` conforme seu SoC.

Plug a microSD, liga a box. Splash NextOS aparece, kernel boota, sway sobe e ES carrega.

## Build a partir do source

Requisitos: Linux + Docker (recomendado) ou nativo, ~40 GB livres, ~8 GB RAM.

```bash
git clone https://github.com/felc18-blip/NextOS.git
cd NextOS
git remote add upstream https://github.com/archr-linux/Arch-R.git   # opcional

PROJECT=NextOS DEVICE=Amlogic-no ARCH=aarch64 make image
```

Imagens geradas em `target/`:
- `NextOS-Amlogic-no.aarch64-<data>-Generic.img.gz` — TV boxes via aml_autoscript + cfgload
- `NextOS-Amlogic-no.aarch64-<data>-Odroid_C5.img.gz` — Odroid C5 board (boot.ini)

Subdevices configurados em `projects/NextOS/devices/Amlogic-no/options` (`SUBDEVICES="Odroid_C5 Generic"`).

## Estrutura do projeto

```
projects/NextOS/
├── devices/
│   ├── Amlogic-no/      # S905X5/X5M/S928X (alvo principal desta distro)
│   ├── Amlogic-nxtos/   # S905W mainline 7.x + Mesa Lima (carro-chefe handheld)
│   └── Amlogic-old/     # Mali-450 antigo
└── packages/
    ├── hardware/quirks/platforms/Amlogic-no/   # 090-ui_service Wayland
    ├── tools/nextos-splash/                    # logo boot fb0
    └── wayland/compositor/sway/                # sway service+config
```

## Sync com upstream

```bash
git fetch upstream
git merge upstream/master
```

## Licença

NextOS é fork de Arch-R que é fork de ROCKNIX/JELOS/LibreELEC/CoreELEC. Todas as licenças upstream se aplicam (GPLv2 majoritariamente). Blob `libMali` é proprietário ARM, redistribuído conforme termos CoreELEC.

## Créditos

- [Arch-R](https://github.com/archr-linux/Arch-R) — distro pai, build system
- [ROCKNIX](https://github.com/ROCKNIX/distribution) — base
- [JELOS](https://github.com/JustEnoughLinuxOS) — fork inicial
- [CoreELEC](https://coreelec.org) — kernel BSP Amlogic + blobs Mali
- [Mali](https://developer.arm.com) — driver kbase ARM + blob userspace
- [sway](https://swaywm.org) / [wlroots](https://gitlab.freedesktop.org/wlroots/wlroots)
- [EmulationStation](https://github.com/RetroPie/EmulationStation) — frontend
- [RetroArch / Libretro](https://www.libretro.com) — emuladores
