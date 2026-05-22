# NextOS

Distro LibreELEC-derived (fork de [Arch-R](https://github.com/archr-linux/Arch-R)) focada em retro gaming nas TV boxes Amlogic Valhall.

## Hardware suportado

NextOS atende **somente** Amlogic Valhall:

- **S905X5** (sc2 / s6)
- **S905X5M** (s7d)
- **S928X** (s5)
- Odroid C5 (subdevice nativo)

**Fora de escopo:**
- S905X4 (sc2 Bifrost Mali-G31): a stack `meson-drm 5.15.196 + libmali g24p0 + kbase r54p2` não fecha o triângulo (GPU fault hardware no primeiro draw em Wayland; KMSDRM tem o mesmo fault). X4 continua na rom Elite Edition antiga.
- S905W e demais Mali-450/T820 antigos: cobertos por outros projects (`Amlogic-old`, `Amlogic-nxtos`).

## Stack gráfica

- **Compositor**: `sway` (wlroots 0.17.4, GLES2 renderer)
- **Frontend**: `EmulationStation` via `essway.service` (Wayland client, `SDL_VIDEODRIVER=wayland`)
- **Driver Mali**: blob CoreELEC `libMali.valhall.{g310,g57}.so` (wayland-drm-dmaheap r44p0) + `mali_kbase` r54p2 / r52p0
- **Kernel**: amlogic-5.15.196
- **DRM modifier policy**: `MALI_WAYLAND_AFBC=0` (força LINEAR alloc no plane primário do meson-drm)

Wayland é fluxo natural: sway é DRM master, ES é cliente Wayland. Sem patches `EE_KMSDRM_RELEASE_DRM` ou wrappers libgbm dlopen — o blob libMali Valhall tem suporte Wayland EGL nativo (`eglBindWaylandDisplayWL`, `EGL_WL_bind_wayland_display`).

## Upstream

Manter sincronia com `archr-linux/Arch-R` via remote `upstream`:

```bash
git fetch upstream
git merge upstream/master
```
