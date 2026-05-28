# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 NextOS (felipe)

PKG_NAME="wlroots"
# 2026-05-27: Amlogic-no usa o fork rocknix/rockchip-wlroots ("-rk"). Apesar do
# nome "rk", esta versao tem os HACKS de interop libmali que o blob Mali precisa:
#  - "Extract dmabuf from mali shared EGL wl_buffer" + EGL_WL_bind_wayland_display
#    -> o compositor consegue IMPORTAR/EXIBIR os buffers wayland dos clientes Mali
#    (ES, emuladores). Sem isso (wlroots vanilla) o cliente roda mas a tela fica
#    no fundo do compositor (buffer nao aparece).
#  - patches/libmali/001-...-allow-zero-stride.patch (o blob produz stride 0).
#  - "drm: Fallback to the first possible crtc" (robustez no caminho legado meson).
# 0.17.4-rk = compativel com sway 1.9. Combinamos com WLR_DRM_NO_ATOMIC=1 +
# MALI_WAYLAND_AFBC=0 (vendor kernel 5.15: atomic do meson rejeita / sem AFBC).
PKG_VERSION="0.17.4-rk"
PKG_SHA256="e9e1e14966c6272ca595307fa817fd0fefae96b13fe36c8084b3a7a55fed20d1"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/rocknix/rockchip-wlroots"
PKG_URL="https://github.com/rocknix/rockchip-wlroots/archive/refs/tags/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain hwdata libdisplay-info libinput libxkbcommon pixman libdrm wayland wayland-protocols seatd"
PKG_LONGDESC="A modular Wayland compositor library (rocknix -rk fork: libmali EGL wl_buffer interop)"
PKG_TOOLCHAIN="meson"
PKG_PATCH_DIRS+=" libmali"

configure_package() {
  # OpenGLES Support
  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_DEPENDS_TARGET+=" ${OPENGLES}"
  fi
}

# xwayland disabled: Arch-R é PROIBIDO x11/Xwayland (só wayland nativo / kmsdrm).
PKG_MESON_OPTS_TARGET="-Dxcb-errors=disabled \
                       -Dxwayland=disabled \
                       -Dbackends=drm,libinput \
                       -Dexamples=false \
                       -Drenderers=gles2"

unpack() {
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.gz -C ${PKG_BUILD}
}

pre_configure_target() {
  # wlroots does not build without -Wno flags as all warnings being treated as errors
  export TARGET_CFLAGS=$(echo "${TARGET_CFLAGS} -Wno-unused-variable -Wno-unused-but-set-variable -Wno-unused-function -Wno-return-type")
}
# Patch de cursor non-fatal: patches/001-nextos-meson-cursor-nonfatal.patch
# (meson nao tem cursor plane; sem isso o backend legado aborta o modeset).
