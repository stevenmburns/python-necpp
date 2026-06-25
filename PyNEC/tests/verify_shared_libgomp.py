"""Linux wheel guard: confirm pynec-accel shares the *system* OpenMP runtime.

Run as part of the cibuildwheel Linux test-command. It asserts that importing
_PyNEC loads the system ``libgomp.so.1`` and does NOT load a private libgomp
bundled under ``pynec_accel.libs/``. This catches a silent regression where the
``auditwheel repair --exclude libgomp.so.1`` step stops taking effect and the
wheel goes back to vendoring its own OpenMP runtime — which collides (initial-
exec static TLS, late dlopen) with the system libgomp used by other accelerated
extensions in the same process (e.g. momwire._accelerators), silently disabling
their fast paths.

Reads /proc/self/maps after import, so it is Linux-only by construction.
"""

import pathlib
import sys

import _PyNEC  # noqa: F401  (import is the point — it dlopens libgomp)

maps = pathlib.Path("/proc/self/maps").read_text()

# A bundled copy lives under the auditwheel libs dir with a mangled soname
# (e.g. pynec_accel.libs/libgomp-<hash>.so.1.0.0). There must be none.
if "pynec_accel.libs/libgomp" in maps:
    bundled = sorted(
        {ln.split()[-1] for ln in maps.splitlines() if "pynec_accel.libs/libgomp" in ln}
    )
    sys.exit(f"FAIL: a bundled libgomp is loaded (exclude did not take effect): {bundled}")

# The system runtime is libgomp.so.1 (or its .1.0.0 realpath); both contain the
# substring "/libgomp.so.1". The mangled bundled name ("/libgomp-<hash>...")
# does not, so this only matches a genuine system libgomp.
if "/libgomp.so.1" not in maps:
    sys.exit("FAIL: system libgomp.so.1 is not loaded after importing _PyNEC")

print("OK: _PyNEC shares the system libgomp.so.1 (no bundled OpenMP runtime)")
