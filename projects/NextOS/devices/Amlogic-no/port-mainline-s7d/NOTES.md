# Port mainline 7.1 + Panthor pro Amlogic-no (S905X5M / s7d)

Objetivo: rodar o X5M no kernel **mainline 7.1-rc4** (que já tem **panthor** + esqueleto
s7d) pra habilitar GL **32-bit E 64-bit** open-source via **Mesa Panthor**, sem o blob
proprietário da ARM (que só existe em 64-bit r44p0). Branch: `port-mainline-s7d-panthor`.
Revert: tag `estado-r44p0-kmsdrm-funcionando` / `base-pre-port-mainline`.

## Por que (resumo)
- Blob Mali Valhall 32-bit r44p0 NÃO existe (ARM só shipou 64-bit). Ver
  [[project_archr_no_x5m_32bit_gl_blob_wall]].
- Mainline 7.1 tem `panthor.ko` (driver CSF do G310) + DT esqueleto `amlogic-s7d-s905x5m-bm202.dts`.
- Mas o esqueleto mainline só tem CPU/UART/pinctrl/power — falta clocks, storage, ethernet, **display**, GPU node.

## Milestones
1. **Boot-to-SSH** (clocks + eMMC + ethernet) — sem display, acessa por SSH e itera. ← ATUAL
2. **Display KMS** (s7d no meson-drm) — o mais difícil.
3. **GPU panthor + Mesa** (32+64 bit).

## Progresso (clocks — a fundação)
- ✅ Driver `s7d.c` (2154 linhas, do vendor common_drivers) copiado + adaptado pro mainline:
  - removido `<linux/arm-smccc.h>` (não usado) e `<linux/amlogic/cpu_version.h>` (vendor)
  - `is_meson_rev_a()` → `0` (X5M é revB+, fclk_div3=div3 design intent)
  - Makefile (`Makefile.add`) + Kconfig (`Kconfig.add`) wirados (COMMON_CLK_S7D)
- ❌ **BLOQUEIO ATUAL — clk-pll API gap:** o s7d usa extensões VENDOR do framework clk-pll
  que o mainline não tem:
  - `meson_clk_pll_data` vendor tem `od`, `smc_id`, `secid`, `secid_disable`, `l_rst`;
    mainline tem só en/m/n/frac/l/rst/current_en/l_detect/init_regs/table/range/frac_max/flags
  - **13 PLLs do s7d são SEGUROS** (`smc_id` — setados via SMC/secure-monitor, não reg direto)
  - macros faltando: `PLL_PARAMS_v4`, flag `CLK_MESON_PLL_POWER_OF_TWO`
  - Compile para em: `s7d.c:522 PLL_PARAMS_v4`, `s7d.c:297 meson_clk_pll_data has no member l_rst/od/smc_id/secid`

## Próximo passo concreto
Portar as extensões secure-PLL do clk-pll vendor pro mainline `drivers/clk/meson/clk-pll.{c,h}`:
1. Adicionar campos `od`, `smc_id`, `secid`, `secid_disable`, `l_rst` em `meson_clk_pll_data`
2. Adicionar caminho SMC (arm_smccc_smc) no set_rate/enable quando `smc_id` setado (copiar do vendor clk-pll.c)
3. Adicionar `PLL_PARAMS_v4` macro + `CLK_MESON_PLL_POWER_OF_TWO` flag
4. Recompilar `s7d.o` até zero erros
5. Depois: DT nodes (clkc, eMMC meson-gx-mmc, ethernet dwmac) → boot-to-SSH

## Refs (no build, vendor = fonte de verdade)
- Vendor clk: `build.NextOS-Amlogic-no.aarch64/build/common_drivers-*/drivers/clk/meson/{s7d.c,clk-pll.c,clk-pll.h}`
- Mainline kernel workspace: `build.NextOS-Amlogic-nxtos.aarch64/build/linux-7.1-rc4/`
- Vendor display (milestone 2): `common_drivers-*/drivers/drm/meson_*.c`
- Device X5M SSH root@192.168.31.103 senha nextos. **Precisa UART/serial pro bring-up.**
