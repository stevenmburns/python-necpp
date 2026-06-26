"""macOS wheel guard: confirm pynec-accel shares ONE external OpenMP runtime.

Run as part of the cibuildwheel macOS test-command — the Apple-Silicon mirror of
``verify_shared_libgomp.py``. It asserts that importing ``_PyNEC`` loads an
external ``libomp.dylib`` (Homebrew's, by its absolute install-name) and does
NOT load a private copy bundled under ``pynec_accel.dylibs/``. This catches a
silent regression where the ``delocate-wheel --exclude libomp`` step stops
taking effect and the wheel goes back to vendoring its own OpenMP runtime —
which is a *second* libomp image in any process that also loads momwire's
accelerator. Two live OpenMP runtimes abort with ``OMP: Error #15`` (or, with
``KMP_DUPLICATE_LIB_OK``, deadlock), so the shared external copy is what keeps
both backends multithreaded with no env-var workarounds.

macOS has no ``/proc``, so the loaded images are read from dyld directly via the
``_dyld_*`` APIs in libSystem.
"""

import ctypes
import sys

import _PyNEC  # noqa: F401  (import is the point — it dlopens libomp)

# dyld image list: the macOS equivalent of /proc/self/maps for loaded mach-O.
_libc = ctypes.CDLL(None)
_libc._dyld_image_count.restype = ctypes.c_uint32
_libc._dyld_get_image_name.restype = ctypes.c_char_p
_libc._dyld_get_image_name.argtypes = [ctypes.c_uint32]

images = [
    _libc._dyld_get_image_name(i).decode() for i in range(_libc._dyld_image_count())
]

# A bundled copy lives under the delocate dylibs dir (pynec_accel.dylibs/
# libomp.dylib). There must be none.
bundled = [p for p in images if "pynec_accel.dylibs/libomp" in p]
if bundled:
    sys.exit(f"FAIL: a bundled libomp is loaded (exclude did not take effect): {bundled}")

# Some libomp must be loaded (the extension uses OpenMP), and it must be the
# external/shared one — i.e. not under any wheel's vendored dylibs dir.
libomp = [p for p in images if "/libomp.dylib" in p]
if not libomp:
    sys.exit("FAIL: no libomp.dylib loaded after importing _PyNEC")
if not any(".dylibs/" not in p for p in libomp):
    sys.exit(f"FAIL: libomp is loaded only from a vendored dir, not shared: {libomp}")

print(f"OK: _PyNEC shares an external libomp (no bundled OpenMP runtime): {libomp}")
