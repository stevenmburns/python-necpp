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

These changes do not alter the license: the modified work as a whole remains
under GPL-2.0-or-later, and the original copyright notices are retained.
