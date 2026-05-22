<p align="center">
  <strong>NextOS</strong>
</p>

<p align="center">
  <em>Distro Linux de retro gaming para TV boxes Amlogic.</em><br/>
  <em>Wayland nativo · sway · EmulationStation</em>
</p>

<p align="center">
  <a href="https://github.com/felc18-blip/NextOS"><img src="https://img.shields.io/github/last-commit/felc18-blip/NextOS?color=0080FF&label=last%20commit&style=flat-square" alt="Last Commit"></a>
  <a href="https://github.com/felc18-blip/NextOS/commits"><img src="https://img.shields.io/github/commit-activity/m/felc18-blip/NextOS?color=0080FF&style=flat-square" alt="Activity"></a>
  <img src="https://img.shields.io/badge/status-em%20desenvolvimento-orange?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/license-GPLv2-blue?style=flat-square" alt="License">
</p>

---

## Sobre

NextOS é uma distro Linux focada em **retro gaming em TV boxes Amlogic**, construída em cima do ecossistema LibreELEC (via Arch-R / ROCKNIX / JELOS).

O diferencial: enquanto a maioria das roms de TV box Amlogic ainda vive em **KMSDRM puro** ou compositores legados, NextOS aposta inteiramente em **Wayland nativo** com `sway` como compositor — moderno, estável e com gerenciamento de DRM master correto entre o frontend (EmulationStation) e os emuladores.

---

## Arquitetura

NextOS suporta duas linhas de hardware, cada uma com sua stack de GPU:

### 1. Amlogic-nxtos — alvo principal

> **S905W L / D / M**, GPU **Mali-450** (Utgard)

A linha **carro-chefe** do projeto. Aqui rodamos a stack **100% open-source upstream**:

| Camada              | Tecnologia                                                              |
| ------------------- | ----------------------------------------------------------------------- |
| **Kernel**          | mainline Linux 7.x (sem BSP vendor)                                     |
| **Driver kernel**   | `lima` (open, mainline)                                                 |
| **Driver userspace**| `Mesa` (Lima driver) — GBM, EGL, GLES2                                  |
| **Compositor**      | `sway` (wlroots, Wayland nativo)                                        |
| **Frontend**        | EmulationStation (cliente Wayland, SDL2)                                |
| **Audio**           | PipeWire                                                                |

Sem blobs proprietários, sem drivers vendor, sem patches kbase ARM. Tudo o que roda foi mergeado no mainline do kernel/Mesa.

### 2. Amlogic-no — bônus

> **S905X5 / S905X5M / S928X**, GPU **Mali Valhall** (G310 / G57)

Linha **secundária**, adicionada porque essas TV boxes têm hardware muito mais potente (Cortex-A55/A76, 4–8 GB RAM, USB 3.0, Gigabit Ethernet) mas ainda não tem suporte mainline pra Mali Valhall em kernel atual. Solução: usar o blob proprietário ARM (vendor) num kernel BSP CoreELEC.

| Camada              | Tecnologia                                                              |
| ------------------- | ----------------------------------------------------------------------- |
| **Kernel**          | amlogic-5.15.196 (BSP CoreELEC + patches NextOS)                        |
| **Driver kernel**   | `mali_kbase` vendor Amlogic (gpu-aml)                                   |
| **Driver userspace**| Blob proprietário `libMali.valhall.{g310,g57}.so` r44p0 wayland-drm     |
| **Compositor**      | `sway` (igual ao nxtos)                                                 |
| **Frontend**        | EmulationStation (igual ao nxtos)                                       |
| **Audio**           | PipeWire                                                                |

| SoC      | DT family | GPU                            | Exemplo de board       |
| -------- | --------- | ------------------------------ | ---------------------- |
| S905X5   | sc2 / s6  | Mali-G310 (Valhall, CSF)       | Vontar X5, X96 X5      |
| S905X5M  | s7d       | Mali-G310 (Valhall, CSF)       | Odroid C5, Vontar X5M  |
| S928X    | s5        | Mali-G57 (Valhall, JM)         | X96 X10 Pro, Ugoos AM8 |

Mesmo compositor, mesmo frontend, mesmo splash — o que muda é só a camada gráfica de baixo nível (blob vs mesa).

---

## O que NextOS compartilha entre as duas linhas

Independente do hardware, todo dispositivo NextOS roda:

- **`nextos-splash`** — logo customizado da distro renderizado direto no `/dev/fb0` durante o boot (binário em C ~50 KB, sem dependência de libdrm/libpng)
- **`sway` + `essway.service`** — compositor único pra todos os devices
- **EmulationStation** patched pra integração Wayland
- **PipeWire** pra áudio
- **Same overlays runtime** — quirks per-platform aplicam config específica do SoC sem fork de service

---

## Fora de escopo

- **S905X4 (sc2 Bifrost Mali-G31)** — meson-drm 5.15 + libmali g24p0 + kbase r54p2 não fecha em Wayland nem KMSDRM (GPU faulta no primeiro draw, independente da config). Esse SoC continua na rom Elite Edition antiga, separada do NextOS.
- **Mali-450 fora do S905W** — outros chips com Utgard antigo não cobertos.

---

## Estrutura do projeto

```
projects/NextOS/
├── devices/
│   ├── Amlogic-nxtos/      ← S905W L/D/M, mainline 7.x + Lima  (principal)
│   └── Amlogic-no/         ← S905X5/X5M/S928X, BSP 5.15 + libMali  (bonus)
└── packages/
    ├── tools/nextos-splash/                    ← logo boot /dev/fb0
    ├── wayland/compositor/sway/                ← sway service + config
    └── hardware/quirks/platforms/
        ├── Amlogic-nxtos/                      ← quirks Lima Mali-450
        └── Amlogic-no/                         ← quirks libMali Valhall
```

---

## Status

Em desenvolvimento ativo. **Sem release pública ainda.**

Linha Amlogic-nxtos é a alvo de estabilidade primária; Amlogic-no segue em paralelo conforme o blob Valhall + sway compositor amadurece.

---

## Licenças

NextOS é fork de [Arch-R](https://github.com/archr-linux/Arch-R), que vem de [ROCKNIX](https://github.com/ROCKNIX/distribution) → [JELOS](https://github.com/JustEnoughLinuxOS) → [LibreELEC](https://libreelec.tv) / [CoreELEC](https://coreelec.org).

Código sob **GNU GPL v2** na maior parte. Componentes individuais mantém suas próprias licenças.

O blob `libMali` (linha Amlogic-no apenas) é proprietário ARM, redistribuído conforme os termos definidos pelo CoreELEC.

---

## Créditos

Esta distro só existe graças ao trabalho coletivo de:

- **[Arch-R](https://github.com/archr-linux/Arch-R)** — distro pai, sistema de build
- **[ROCKNIX](https://github.com/ROCKNIX/distribution)** — base estável fork da JELOS
- **[JELOS](https://github.com/JustEnoughLinuxOS)** — fork inicial focado em emulação
- **[CoreELEC](https://coreelec.org)** — kernel BSP Amlogic + blobs Mali vendor
- **[Mesa](https://www.mesa3d.org)** — driver Lima open-source (linha nxtos)
- **[sway](https://swaywm.org)** + **[wlroots](https://gitlab.freedesktop.org/wlroots/wlroots)** — compositor
- **[EmulationStation](https://github.com/RetroPie/EmulationStation)** — frontend
- **[RetroArch / Libretro](https://www.libretro.com)** — emuladores e cores
- **[PipeWire](https://pipewire.org)** — stack de áudio
- Toda a comunidade open-source que torna isso possível
