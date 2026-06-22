#!/usr/bin/env bash
#
# Generate the un-committed build prerequisites for the _PyNEC extension:
#   - necpp_src/config.h    via autoconf (make -f Makefile.git && ./configure)
#   - PyNEC/necpp_src        symlink to ../necpp_src, so setup.py's relative
#                            glob of necpp_src/src/*.cpp resolves
#   - PyNEC/PyNEC_wrap.cxx   the SWIG C++ -> Python wrapper
#
# None of these are committed (config.h is an autoconf artifact, the wrapper is
# SWIG-generated), so a fresh checkout needs this before building. Used by both
# the test CI and the cibuildwheel before-build hook.
#
# Requires on PATH: autoconf automake libtool m4 (for config.h) and swig.
set -euo pipefail

PYNEC_DIR="$(cd "$(dirname "$0")" && pwd)"
NECPP_SRC="$(cd "$PYNEC_DIR/../necpp_src" && pwd)"

# config.h via autoconf. --without-lapack always passes (it needs no BLAS at
# configure time); PyNEC/setup.py turns the LAPACK/LAPACKE code path on via
# -DLAPACK=1 -DLAPACKE=1 regardless of what config.h records, and selects the
# BLAS implementation at link time from PYNEC_BACKEND.
if [ ! -f "$NECPP_SRC/config.h" ]; then
    ( cd "$NECPP_SRC" && make -f Makefile.git && ./configure --without-lapack )
fi

# setup.py globs necpp_src/src/*.cpp relative to PyNEC/.
ln -sf ../necpp_src "$PYNEC_DIR/necpp_src"

# SWIG wrapper (PyNEC.i -> PyNEC_wrap.cxx + PyNEC.py).
( cd "$PYNEC_DIR" && swig -Wall -c++ -python PyNEC.i )

echo "OK — generated config.h, necpp_src symlink, and PyNEC_wrap.cxx"
