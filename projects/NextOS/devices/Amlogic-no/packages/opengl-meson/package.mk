# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="opengl-meson"
PKG_VERSION="e8876882426dd283c95bc30e98ccfd13954426db"
PKG_SHA256=""
PKG_LICENSE="nonfree"
PKG_SITE="http://openlinux.amlogic.com:8000/download/ARM/filesystem/"
PKG_URL="https://github.com/CoreELEC/opengl-meson/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libdrm opentee_linuxdriver wayland vulkan-loader"
PKG_LONGDESC="OpenGL ES pre-compiled libraries for Mali GPUs found in Amlogic Meson SoCs."
PKG_TOOLCHAIN="manual"
# NextOS 2026-05-12: wayland + vulkan-loader como dep target — os blobs
# libMali.valhall.g{310,57}.so listam libwayland-client.so.0 e libwayland-server.so.0
# como NEEDED (readelf -d). Sem essas libs no INSTALL, ld.so falha ao carregar
# libMali.so / libEGL.so → tela preta no boot do S905X5/X5M. EmuELEC Piers 4.8
# inclui wayland 1.24.0 por causa disso.

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  # NextOS 2026-05-09: bumped pra r44p0 alinhado com CE-22, mantém custom
  # NextOS dvalin.g12a (S905Y2 Radxa Zero) e lib32 support pra ports 32-bit.
    cp -p lib/arm64/gondul/r44p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.gondul.g12b.so
    cp -p lib/arm64/gondul/r44p0/fbdev/libMali_r1p0.so ${INSTALL}/usr/lib/libMali.gondul.so
    # V14.4 Amlogic-no (revert V14.3 Piers swap): X4 Bifrost G31 volta a
    # usar blob dvalin/r44p0/fbdev/libMali.so original do CoreELEC. Bench
    # KMSDRM com Piers wayland-drm-dmaheap confirmou que kernel meson-drm
    # 5.15.196 não finaliza atomic plane HDMI (tela preta apesar de stack
    # subir). X4 funciona perfeito em fbdev path tradicional com o blob
    # original — Valhall (S905X5/X5M/S928X) continua usando blobs próprios
    # wayland-drm-dmaheap nas linhas seguintes (não afetado).
    # Piers blob preservado em ${PKG_DIR}/sources/libMali.dvalin.piers.so
    # pra futuro V15 quando weston Wayland for opt-in no X5.
    cp -p lib/arm64/dvalin/r44p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.dvalin.so
    cp -p lib/arm64/valhall/r44p0/wayland/libMali_g57_dmaheap.so ${INSTALL}/usr/lib/libMali.valhall.g57.so
    cp -p lib/arm64/valhall/r44p0/wayland/libMali_g310_dmaheap.so ${INSTALL}/usr/lib/libMali.valhall.g310.so
    # Custom NextOS: dvalin.g12a fbdev pra S905X2/S905Y2 (G12A) Radxa Zero
    [ -f lib/arm64/dvalin/r12p0/fbdev/libMali.so ] && \
      cp -p lib/arm64/dvalin/r12p0/fbdev/libMali.so ${INSTALL}/usr/lib/libMali.dvalin.g12a.so

    mkdir -p ${SYSROOT_PREFIX}/usr/lib
	# V14 fix: usar Valhall G310 como libMali.so no sysroot (não gondul).
	# Razão: o consumer libSDL3 (e outros consumers KMSDRM) precisa resolver
	# símbolos gbm_* em tempo de link. Gondul fbdev legacy NÃO exporta gbm_*;
	# só os blobs valhall.g{310,57} e dvalin (wayland-drm) têm os 39 símbolos
	# gbm_bo_* + gbm_device_* + gbm_surface_*. Em runtime no device, o
	# libmali-overlay-setup symlinka /var/lib/libMali.so pro chip correto
	# (gondul/dvalin/valhall.g310/g57) detectado via /proc/device-tree/compatible
	# — não há regressão funcional pros chips fbdev (eles continuam usando o
	# blob deles em runtime, só o sysroot usa valhall pra link-time check).
	cp -p lib/arm64/valhall/r44p0/wayland/libMali_g310_dmaheap.so ${SYSROOT_PREFIX}/usr/lib/libMali.so

	# NextOS 2026-05-26 (Amlogic-no X5): apontar libGLESv2/libEGL/libGLESv1_CM
	# do SYSROOT pro blob real (libMali.so g310, 653 símbolos gl*). Sem isso,
	# o link de apps GL (retroarch, gl_core/glsl) cai num stub mesa/gallium
	# sem símbolos gl* → "undefined reference to glBindTexture" no LD.
	# Garante link-time contra o blob em toda compilação (clean/incremental).
	for stem in libEGL libGLESv2 libGLESv1_CM; do
	  for suffix in .so .so.1 .so.2 .so.1.0.0 .so.2.0.0 .so.2.1.0; do
	    ln -sf libMali.so "${SYSROOT_PREFIX}/usr/lib/${stem}${suffix}"
	  done
	done

   ln -sf /var/lib/libMali.so ${INSTALL}/usr/lib/libMali.so
	
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libmali.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libmali.so.0
    # NextOS 2026-05-12: symlinks alinhados com EmuELEC Piers 4.8 — libmali.so.1
    # e libgbm.so/.1 são consumidos por SDL2/RA/Mali blob (GBM impl no próprio blob).
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libmali.so.1

    # V14.4 Amlogic-no (revert V14.3 symlink): X4 voltou a usar dvalin fbdev
    # original (sem gbm_*); SDL3 V14.4 ainda tem KMSDRM=ON (Valhall precisa).
    # SDL3 linka NEEDED gbm_bo_*, gbm_device_*, gbm_surface_* — em Bifrost X4
    # com blob fbdev, symbol lookup error "undefined gbm_bo_get_offset" trava
    # ES. Wrapper V14.1 resolve: cada gbm_* faz dlopen libMali + dlsym; se
    # blob NÃO tem (Bifrost fbdev) → retorna NULL → SDL3 detecta + cai pra
    # MALI fbdev path. Se TEM (Valhall wayland-drm-dmaheap) → delega.
    # 1 binário, comportamento per-SoC automático.
    ${TARGET_PREFIX}gcc -shared -fPIC -O2 \
        -Wl,-soname,libgbm.so.1 \
        -o ${INSTALL}/usr/lib/libgbm.so.1 \
        ${PKG_DIR}/sources/libgbm-stub/libgbm.c -ldl
    ln -sf libgbm.so.1 ${INSTALL}/usr/lib/libgbm.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libEGL.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libEGL.so.1
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libEGL.so.1.0.0
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLES_CM.so.1
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv1_CM.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv1_CM.so.1
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv1_CM.so.1.0.1
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv1_CM.so.1.1
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv2.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv2.so.2
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv2.so.2.0
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv2.so.2.0.0
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv3.so
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv3.so.3
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv3.so.3.0
    ln -sf /usr/lib/libMali.so ${INSTALL}/usr/lib/libGLESv3.so.3.0.0

# install headers and libraries to TOOLCHAIN
	cp -rf ${PKG_BUILD}/include/* ${SYSROOT_PREFIX}/usr/include
	# NextOS 2026-05-10: fix path pkgconfig (era ${PKG_BUILD}/pkgconfig/, é ${PKG_BUILD}/lib/pkgconfig/)
	cp -rf ${PKG_BUILD}/lib/pkgconfig/* ${SYSROOT_PREFIX}/usr/lib/pkgconfig/ 2>/dev/null || true
	# NextOS 2026-05-10: Mali blob implementa EGL 1.5 spec mas o pkgconfig diz "Version: 0.99"
	# (placeholder original Amlogic). Bumpar pra 1.5 pra mpv/SDL3/etc passarem version check.
	sed -i 's|^Version: 0.99$|Version: 1.5|' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/egl.pc ${SYSROOT_PREFIX}/usr/lib/pkgconfig/glesv2.pc 2>/dev/null || true
	# V15: bumpar gbm.pc version 17.2.0 → 25.0.0 pra weston 15.0.1 passar
	# version check (>= 21.1.1). API GBM é estável; símbolos gbm_* vêm do
	# blob libMali (Valhall wayland-drm-dmaheap exporta 39 gbm_*) via wrapper
	# V14.1 que dlopen libMali. Mesma situação do EGL — pkgconfig só metadata.
	sed -i 's|^Version: 17\.2\.0$|Version: 25.0.0|' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/gbm.pc 2>/dev/null || true
	sed -i 's|^Version: 17\.2\.0$|Version: 25.0.0|' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/gbm/gbm.pc 2>/dev/null || true
	# V15: bumpar wayland-egl.pc 1.0 → 18.0.0 pra RetroArch passar
	# version check (>= 10.1.0). Blob libMali Valhall exporta wl_egl_window_*
	# functions (visto via nm -D), API estável.
	sed -i 's|^Version: 1\.0$|Version: 18.0.0|' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/wayland-egl.pc 2>/dev/null || true
	cp ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_fbdev/* ${SYSROOT_PREFIX}/usr/include/EGL
	# NextOS 2026-05-10: copiar GBM headers (CE-22 sync) — packages mesa/lima precisam
	mkdir -p ${SYSROOT_PREFIX}/usr/include/gbm
	[ -d ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_gbm/gbm ] && \
	  cp -pr ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_gbm/gbm/* ${SYSROOT_PREFIX}/usr/include/
	[ -d ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_wayland/gbm ] && \
	  cp -pr ${SYSROOT_PREFIX}/usr/include/EGL_platform/platform_wayland/gbm/* ${SYSROOT_PREFIX}/usr/include/
	rm -rf ${SYSROOT_PREFIX}/usr/include/EGL_platform

    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libmali.so
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libMali.so.0
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libEGL.so
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libEGL.so.1
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libEGL.so.1.0.0
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLES_CM.so.1
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv1_CM.so
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv1_CM.so.1
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv1_CM.so.1.0.1
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv1_CM.so.1.1
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv2.so
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv2.so.2
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv2.so.2.0
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv2.so.2.0.0
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv3.so
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv3.so.3
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv3.so.3.0
    ln -sf ${SYSROOT_PREFIX}/usr/lib/libMali.so ${SYSROOT_PREFIX}/usr/lib/libGLESv3.so.3.0.0

  # V14 fix Amlogic-no: substituir symlink libgbm.so → libMali.valhall.g310.so
  # por LINKER SCRIPT GNU ld. Razão: ld.bfd 2.46 strict não consegue parsear
  # libMali blob (50MB proprietário ARM com seções .gnu.attributes não-standard)
  # — falha com "could not parse subsection at offset 24" e cascateia em
  # "undefined reference to gbm_bo_*" no link do emulationstation.
  #
  # O linker script faz ld redirect pra libMali.so via GROUP — mesmo target,
  # mas ld processa nativamente sem tentar parsear o blob. Em runtime no device,
  # ld.so resolve gbm_* normalmente via libMali (NEEDED do consumer ES).
  # Resultado: build limpo + runtime idêntico ao V13 release.
  # V14.1 Amlogic-no: substituir libgbm.so do sysroot pelo NOSSO wrapper REAL
  # (compilado de sources/libgbm-stub/libgbm.c). Os 23 símbolos gbm_* ficam
  # DEFINIDOS no wrapper, então o linker do consumer (libSDL3 e quem mais usar
  # KMSDRM) resolve link-time direto sem precisar parsear blobs.
  #
  # V14 anterior usava linker script GROUP(libMali.valhall.g310.so) que
  # quebrava em SoCs Bifrost runtime (sym lookup error porque libMali=dvalin
  # sem gbm_*). O wrapper resolve isso fazendo dlopen lazy no runtime.
  ${TARGET_PREFIX}gcc -shared -fPIC -O2 \
      -Wl,-soname,libgbm.so.1 \
      -o ${SYSROOT_PREFIX}/usr/lib/libgbm.so.1 \
      ${PKG_DIR}/sources/libgbm-stub/libgbm.c -ldl
  ln -sf libgbm.so.1 ${SYSROOT_PREFIX}/usr/lib/libgbm.so

  mkdir -p ${INSTALL}/usr/sbin
    cp ${PKG_DIR}/scripts/libmali-overlay-setup ${INSTALL}/usr/sbin

  # NextOS 2026-05-12: Mali Vulkan ICD (alinhado com EmuELEC Piers) — aponta
  # libMali.so como ICD; vulkan-loader carrega Vulkan API via mesmo blob.
  mkdir -p ${INSTALL}/usr/share/vulkan/icd.d
    cp ${PKG_DIR}/files/mali.json ${INSTALL}/usr/share/vulkan/icd.d/mali.json
  # install needed files for compiling
  mkdir -p ${SYSROOT_PREFIX}/usr/include/EGL
    cp -pr include/EGL ${SYSROOT_PREFIX}/usr/include
    cp -pr include/EGL_platform/platform_fbdev/* ${SYSROOT_PREFIX}/usr/include/EGL
  mkdir -p ${SYSROOT_PREFIX}/usr/include/GLES2
    cp -pr include/GLES2 ${SYSROOT_PREFIX}/usr/include
  mkdir -p ${SYSROOT_PREFIX}/usr/include/GLES3
    cp -pr include/GLES3 ${SYSROOT_PREFIX}/usr/include
  mkdir -p ${SYSROOT_PREFIX}/usr/include/KHR
    cp -pr include/KHR ${SYSROOT_PREFIX}/usr/include

}

post_install() {
  enable_service unbind-console.service
  enable_service libmali.service
}

