# Changes in this fork

This is a fork of [tmolteno/python-necpp](https://github.com/tmolteno/python-necpp),
the Python (SWIG) wrappers for the NEC2++ antenna-simulation engine. Both these
wrappers and the underlying NEC2++ C++ engine are licensed under the **GNU
General Public License, version 2 or later** (see [`LICENSE.txt`](LICENSE.txt)
and `necpp_src/COPYING`). The modifications described below are part of that
GPL-covered work and are likewise distributed under **GPL-2.0-or-later**.

This file records, per **section 2(a) of the GPL**, that the files in this fork
have been changed relative to upstream, and when. The authoritative, dated
record of individual changes is this repository's git history.

## Source availability

The complete corresponding source for the binary wheels published on this
repository's GitHub Releases is:

- **Python wrappers + build glue:** this repository
  (`stevenmburns/python-necpp`, branch `accelerated`), at the release tag the
  wheels were built from (e.g. `v1.7.4-accel.1`).
- **NEC2++ C++ engine:** [`stevenmburns/necpp`](https://github.com/stevenmburns/necpp),
  referenced here as the `necpp_src` submodule.

Both repositories are public; the matching tags are kept available for as long
as the corresponding wheels are distributed.

## Modifications (2026)

Relative to `tmolteno/python-necpp`:

- **Redistributable cross-platform wheels.** Added cibuildwheel GitHub Actions
  (`.github/workflows/wheels.yml`) that build self-contained manylinux and
  Windows (MSVC) wheels for CPython 3.10–3.14, plus a Linux test workflow
  (`.github/workflows/ci.yml`).
- **OpenBLAS LAPACK backend.** `PyNEC/setup.py` gained a `scipy-openblas32`
  backend (LP64 OpenBLAS + LAPACKE, with the ABI-prefixed symbols remapped),
  alongside reference-LAPACKE and Intel MKL backends, selected via the
  `PYNEC_BACKEND` environment variable. The vendored OpenBLAS makes the wheels
  self-contained — no system BLAS is needed at install time.
- **Windows / MSVC build support.** `PyNEC/msvc_compat.h` neutralises GCC-only
  `__attribute__` usage so MSVC can compile the engine; `PyNEC/windows_repair.py`
  runs delvewheel to vendor the OpenBLAS DLL into the Windows wheel.
- **Build prerequisites.** `PyNEC/build_prereqs.sh` generates the un-committed
  build inputs (the autoconf `config.h`, the SWIG wrapper, and a vendored
  `necpp_src` tree for the cibuildwheel package directory).
- **Runtime dependency declaration.** `PyNEC/setup.py` declares its numpy
  runtime dependency via `install_requires`.
- **C++ engine fork.** The `necpp_src` submodule is repointed to
  [`stevenmburns/necpp`](https://github.com/stevenmburns/necpp), a fork of the
  NEC2++ engine that adds OpenMP parallelisation of the NEC2 matrix fill and the
  MSVC build fixes. See that repository for its own change record.
- **De-vendored the OpenMP runtime (Linux wheels, 1.7.4.post1).** The Linux
  `auditwheel repair` now passes `--exclude libgomp.so.1`, so the wheel binds the
  *system* `libgomp.so.1` instead of bundling a private copy with a mangled
  soname. A bundled second libgomp collides with the system libgomp loaded by
  other accelerated extensions in the same process (initial-exec static TLS +
  late `dlopen` exhausts glibc's static-TLS surplus), which made co-loaded
  extensions silently fall back to slower code paths. The wheel now requires a
  system libgomp at runtime (universally present on glibc Linux — it is the GCC
  OpenMP runtime). OpenBLAS and libgfortran remain vendored.

- **Optional wire-intersection check (1.7.5).** Wrapped the new
  `c_geometry::set_intersection_check(bool)` knob (added in the `stevenmburns/necpp`
  engine fork) into the Python interface (`PyNEC/interface_files/c_geometry.i`).
  NEC2++ fatally rejects a deck whose wires pass within a radius-sum of one
  another — a mid-segment crossing, or a segment midpoint landing on a
  neighbouring wire — a validation the NEC-2 kernel and `nec2c` do not perform.
  Real decks with closely-spaced, touching, or crossing wires (car-body grids,
  collinear feed stubs, dense airframe meshes) therefore raised on geometry NEC-2
  solves fine. Call `geometry.set_intersection_check(False)` before
  `geometry_complete()` to restore that permissiveness. Default is unchanged
  (check enabled).

- **Sommerfeld gn 2 near-ground fix (1.7.6).** Picked up the engine fix for
  the `c_ggrid::interpolate()` (NEC-2 INTRP) control-flow inversion
  (`stevenmburns/necpp#5`): downward grid-region crossings extrapolated stale
  cubic-interpolation coefficients outside their valid cell, corrupting gn 2
  Sommerfeld solves for conductors near the ground that don't touch it, and a
  thread's cache could survive into later solves (order-dependent results).
  The cache now self-invalidates via a per-grid generation stamp. Fixes
  `stevenmburns/python-necpp#15` (antennaknobs#448): near-ground gn 2 decks
  now match nec2c/nec2dxs/momwire to 4 digits, and repeat solves in one
  process are bit-identical.

These changes do not alter the license: the modified work as a whole remains
under GPL-2.0-or-later, and the original copyright notices are retained.
