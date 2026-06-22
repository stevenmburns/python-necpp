/*
 * msvc_compat.h — compatibility shims for building NEC2++ (necpp_src) with
 * MSVC. Force-included on the Windows build via /FImsvc_compat.h (see the
 * win32 branch of PyNEC/setup.py). Not used on GCC/Clang builds.
 */
#ifndef PYNEC_MSVC_COMPAT_H
#define PYNEC_MSVC_COMPAT_H

#if defined(_MSC_VER)

/*
 * NEC2++ marks some thread-local definitions with the GCC-only
 * __attribute__((tls_model("initial-exec"))) (see c_ggrid.cpp / nec_context.cpp).
 * MSVC does not understand __attribute__; tls_model is purely a TLS-access
 * optimization hint, so expand __attribute__(...) to nothing.
 */
#ifndef __attribute__
#define __attribute__(x)
#endif

#endif /* _MSC_VER */

#endif /* PYNEC_MSVC_COMPAT_H */
