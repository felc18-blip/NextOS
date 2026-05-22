// LD_PRELOAD shim 32-bit pra Amlogic-nxtos (mesa lima Mali-450 GLES2):
// converte glFramebufferRenderbuffer(GL_DEPTH_STENCIL_ATTACHMENT) em duas
// chamadas separadas (GL_DEPTH_ATTACHMENT + GL_STENCIL_ATTACHMENT).
//
// Mali-450 mesa lima e GLES2-only; o enum combinado GL_DEPTH_STENCIL_ATTACHMENT
// e GLES3+ e da GL_INVALID_ENUM aqui. Mali blob fbdev (Amlogic-old) aceita.
//
// Cores afetados detectados ate agora: morpheuscast_xtreme_32b (Dreamcast,
// pre-built UnofficialOSAddOns). Outros 32b cores open-source nao precisam.
//
// Build:
//   armv8a-emuelec-linux-gnueabihf-gcc -shared -fPIC -O2 \
//       -o libfb-shim.so libfb-shim.c -ldl
//
// Aplicado condicionalmente em emuelecRunEmu.sh (case CORE) - ver
// filesystem/usr/bin/emuelecRunEmu.sh, branch BIT32="yes".

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>

typedef unsigned int GLenum;
typedef unsigned int GLuint;
#define GL_DEPTH_ATTACHMENT 0x8D00
#define GL_STENCIL_ATTACHMENT 0x8D20
#define GL_DEPTH_STENCIL_ATTACHMENT 0x821A

void glFramebufferRenderbuffer(GLenum target, GLenum attachment,
                                GLenum rbtarget, GLuint rb) {
    static void (*real)(GLenum, GLenum, GLenum, GLuint) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "glFramebufferRenderbuffer");
    if (attachment == GL_DEPTH_STENCIL_ATTACHMENT) {
        real(target, GL_DEPTH_ATTACHMENT, rbtarget, rb);
        real(target, GL_STENCIL_ATTACHMENT, rbtarget, rb);
    } else {
        real(target, attachment, rbtarget, rb);
    }
}
