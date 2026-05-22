/* libgbm.so wrapper — V14.1 Amlogic-no per-device
 *
 * Resolve o problema de libSDL3.so V13/V14 ter NEEDED gbm_* symbols não
 * resolvíveis em SoCs Bifrost fbdev (S905X4/Y4 sc2/s4, S905X2/Y2 g12a,
 * VIM4 t7, Odroid N2 g12b) cujos blobs libMali.{dvalin,gondul,gondul.g12b}.so
 * NÃO exportam gbm_* (são variants fbdev, sem suporte wayland-drm).
 *
 * Em SoCs Valhall (s5/s6/s7d) o blob libMali.valhall.{g310,g57}.so exporta os
 * 39 gbm_*; em SoCs Bifrost o blob não exporta nenhum.
 *
 * Strategy: cada gbm_* aqui é um wrapper que faz dlopen("/var/lib/libMali.so")
 * no constructor da lib, e em cada chamada faz dlsym(handle, "gbm_*"). Se
 * libMali tem o símbolo (Valhall), delega. Senão (Bifrost), retorna NULL/0,
 * que faz SDL3 KMSDRM init detectar gbm_create_device==NULL e cair pra MALI
 * fbdev driver (que esses chips suportam nativamente).
 *
 * 1 binário, comportamento per-SoC automático em runtime via libmali-overlay-setup
 * chain (que já symlinka /var/lib/libMali.so pro blob correto baseado em
 * /proc/device-tree/compatible).
 *
 * Build per-device opengl-meson cross-compile aarch64-libreelec-linux-gnu-gcc.
 * Não toca código global SDL3 nem master opengl-meson.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>
#include <stdint.h>

static void* mali_handle = NULL;

__attribute__((constructor))
static void libgbm_stub_init(void)
{
    /* Tenta /var/lib/libMali.so primeiro (symlink criado por libmali-overlay-setup
     * baseado no SoC detectado). Fallback pro path absoluto do blob caso o
     * symlink ainda não exista (boot order race, embora improvável). */
    mali_handle = dlopen("/var/lib/libMali.so", RTLD_NOW | RTLD_GLOBAL);
    if (!mali_handle)
        mali_handle = dlopen("/usr/lib/libMali.so", RTLD_NOW | RTLD_GLOBAL);
    /* Falha silenciosa: se nem libMali existe, todos os wrappers retornam NULL
     * e o consumer (SDL3) trata como GBM indisponível. */
}

/* Macro pra reduzir boilerplate — declara wrapper que faz dlsym lazy + cache */
#define WRAP_RET(name, ret_type, args_decl, args_call, fail_val) \
    ret_type name args_decl { \
        static ret_type (*fn) args_decl = NULL; \
        if (!fn && mali_handle) \
            fn = dlsym(mali_handle, #name); \
        return fn ? fn args_call : fail_val; \
    }

#define WRAP_VOID(name, args_decl, args_call) \
    void name args_decl { \
        static void (*fn) args_decl = NULL; \
        if (!fn && mali_handle) \
            fn = dlsym(mali_handle, #name); \
        if (fn) fn args_call; \
    }

/* 23 wrappers — exatos os símbolos undefined em libSDL3.so V14 KMSDRM driver */

WRAP_RET(gbm_create_device, void*, (int fd), (fd), NULL)
WRAP_VOID(gbm_device_destroy, (void* dev), (dev))
WRAP_RET(gbm_device_is_format_supported, int, (void* dev, uint32_t format, uint32_t usage), (dev, format, usage), 0)

WRAP_RET(gbm_surface_create, void*, (void* dev, uint32_t w, uint32_t h, uint32_t format, uint32_t flags), (dev, w, h, format, flags), NULL)
WRAP_VOID(gbm_surface_destroy, (void* surf), (surf))
WRAP_RET(gbm_surface_lock_front_buffer, void*, (void* surf), (surf), NULL)
WRAP_VOID(gbm_surface_release_buffer, (void* surf, void* bo), (surf, bo))

WRAP_RET(gbm_bo_create, void*, (void* dev, uint32_t w, uint32_t h, uint32_t format, uint32_t flags), (dev, w, h, format, flags), NULL)
WRAP_VOID(gbm_bo_destroy, (void* bo), (bo))
WRAP_RET(gbm_bo_get_device, void*, (void* bo), (bo), NULL)
WRAP_RET(gbm_bo_get_format, uint32_t, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_handle, uint32_t, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_handle_for_plane, uint32_t, (void* bo, int plane), (bo, plane), 0)
WRAP_RET(gbm_bo_get_height, uint32_t, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_modifier, uint64_t, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_offset, uint32_t, (void* bo, int plane), (bo, plane), 0)
WRAP_RET(gbm_bo_get_plane_count, int, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_stride, uint32_t, (void* bo), (bo), 0)
WRAP_RET(gbm_bo_get_stride_for_plane, uint32_t, (void* bo, int plane), (bo, plane), 0)
WRAP_RET(gbm_bo_get_user_data, void*, (void* bo), (bo), NULL)
WRAP_RET(gbm_bo_get_width, uint32_t, (void* bo), (bo), 0)
WRAP_VOID(gbm_bo_set_user_data, (void* bo, void* data, void* destroy_cb), (bo, data, destroy_cb))
WRAP_RET(gbm_bo_write, int, (void* bo, const void* buf, size_t count), (bo, buf, count), -1)
