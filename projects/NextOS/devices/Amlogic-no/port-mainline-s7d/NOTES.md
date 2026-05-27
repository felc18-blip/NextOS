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

## Próximo passo concreto — port ADITIVO do meson_clk_pll_v4_ops pro mainline clk-pll
(Descoberta: NÃO substituir o clk-pll do mainline pelo vendor — o vendor usa a API ANTIGA
`round_rate` em 5 ops; o mainline 7.1 usa `determine_rate`. MAS o `meson_clk_pll_v4_ops`
— o ÚNICO que o s7d usa — JÁ usa `determine_rate` ✓. Então porta-se SÓ o v4 subset,
ADITIVO ao clk-pll do mainline que já tem a API certa.)

Fonte: `common_drivers-*/drivers/clk/meson/clk-pll.c` (vendor). Alvo: mainline `clk-pll.{c,h}`.
1. **clk-pll.h** (mainline): adicionar em `struct meson_clk_pll_data` os campos
   `struct parm l_rst; struct parm od; unsigned int smc_id; u8 secid; u8 secid_disable;`
   (+ `th`/`fl` se as macros referenciarem). Adicionar macro `PLL_PARAMS_v4(_m,_n,_od)`,
   flag `CLK_MESON_PLL_POWER_OF_TWO BIT(3)`, e campo `od` no `struct pll_params_table`.
2. **clk-pll.c** (mainline): APPEND as funções v4 do vendor (já são determine_rate-API):
   - `meson_clk_pll_is_enabled` (vendor linha 574)
   - bloco v4 vendor linhas ~1190–1600: `meson_clk_pll_v4_recalc_rate`,
     `meson_clk_pll_v4_get_range_m`, `meson_clk_pll_v4_get_params`,
     `meson_clk_pll_v4_determine_rate`, `meson_clk_pll_v4_init`,
     `meson_clk_pll_v4_enable`, `meson_clk_pll_v4_disable`, `meson_clk_pll_v4_set_rate`
   - exportar `const struct clk_ops meson_clk_pll_v4_ops` (EXPORT_SYMBOL_GPL)
   - resolver `bypass_clk_disable` (1 ref — definir/portar do vendor)
   - `#include "clk-secure.h"` (já trazido) + `<linux/arm-smccc.h>` pros secure PLLs
3. Recompilar `s7d.o` + `clk-pll.o` até zero erros.
4. Depois: DT nodes (clkc s7d + eMMC `amlogic,meson-axg-mmc` + ethernet dwmac-meson) → **boot-to-SSH**.

clk-secure.h JÁ copiado pro mainline (`drivers/clk/meson/clk-secure.h`, 46 linhas, defines SMC).
s7d.c JÁ adaptado (em port-mainline-s7d/clk/s7d.c — incluir no patch final).

### REFINAMENTO (2026-05-27, após tentativa): port piecemeal do v4_ops NÃO basta
Tentei adicionar só o bloco v4 (1192-1613) + alguns campos ao clk-pll do mainline → o v4
puxa QUASE TODO o framework estendido do vendor: campos `od_max`/`fixed_n`/`pll_range`/`fl`/`th`,
flags `FIXED_N`/`FIXED_EN0P5`/`FIXED_FRAC_WEIGHT_PRECISION`/`READ_ONLY`/`IGNORE_INIT`/`RSTN`,
tipo `struct pll_rate_range`, helper `meson_clk_pll_params_to_rate`. Restaurado o mainline.

**PLANO CERTO (wholesale + trim):**
1. **clk-pll.h** ← usar o do VENDOR inteiro (`clk/vendor-ref/clk-pll.h.vendor`) — tem todos os
   campos/flags/macros/tipos. Substitui o do mainline.
2. **clk-pll.c** ← usar o do VENDOR (`clk/vendor-ref/clk-pll.c.vendor`, 1626 linhas) MAS:
   - REMOVER/stubar os 4 ops que usam `round_rate` (API velha, quebra no 7.1):
     `meson_clk_pll_ops`, `meson_clk_pll_ro_ops`, `meson_clk_pll_v3_ops`, `meson_clk_pcie_pll_ops`
     (o s7d só usa `meson_clk_pll_v4_ops`, que já é determine_rate ✓)
   - definir `static bool bypass_clk_disable;`
   - já inclui clk-secure.h + arm-smccc
3. **DESABILITAR os outros SoC clock drivers meson** no .config do Amlogic-no (usam a API do
   mainline clk-pll, quebram com o do vendor): a1/axg/c3/g12a/gxbb/gxl/s4/t7/meson8/sm1 —
   o Amlogic-no SÓ precisa do s7d (COMMON_CLK_S7D). Manter infra (regmap/mpll/dualdiv/phase/...).
4. Recompilar clk-pll.o + s7d.o → zero erros.
5. DT nodes (clkc + eMMC `amlogic,meson-axg-mmc` + ethernet dwmac-meson) → boot-to-SSH.

⚠️ TESTE: sem UART/serial no X5M não dá pra validar boot (sem display ainda, sem SSH até ethernet
funcionar). Felipe vai providenciar serial ("precisamos"). Bring-up de kernel exige serial.

## Refs (no build, vendor = fonte de verdade)
- Vendor clk: `build.NextOS-Amlogic-no.aarch64/build/common_drivers-*/drivers/clk/meson/{s7d.c,clk-pll.c,clk-pll.h}`
- Mainline kernel workspace: `build.NextOS-Amlogic-nxtos.aarch64/build/linux-7.1-rc4/`
- Vendor display (milestone 2): `common_drivers-*/drivers/drm/meson_*.c`
- Device X5M SSH root@192.168.31.103 senha nextos. **Precisa UART/serial pro bring-up.**
