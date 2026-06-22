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

# setup.py globs necpp_src/src/*.cpp relative to PyNEC/. Two layouts:
#   default              -> symlink PyNEC/necpp_src -> ../necpp_src (dev / test CI)
#   PYNEC_VENDOR_NECPP=1  -> copy ../necpp_src into PyNEC/necpp_src, making the
#                           build tree self-contained. cibuildwheel only mounts
#                           the package dir (PyNEC/), so the sibling ../necpp_src
#                           would be invisible inside the build container.
if [ "${PYNEC_VENDOR_NECPP:-0}" = "1" ]; then
    rm -rf "$PYNEC_DIR/necpp_src"
    # Exclude .git (necpp_src is a submodule) — the build needs only the tree.
    cp -a "$NECPP_SRC" "$PYNEC_DIR/necpp_src"
    rm -rf "$PYNEC_DIR/necpp_src/.git"
    BUILD_NECPP="$PYNEC_DIR/necpp_src"
else
    ln -sf ../necpp_src "$PYNEC_DIR/necpp_src"
    BUILD_NECPP="$NECPP_SRC"
fi

# config.h via autoconf. --without-lapack always passes (it needs no BLAS at
# configure time); PyNEC/setup.py turns the LAPACK/LAPACKE code path on via
# -DLAPACK=1 -DLAPACKE=1 regardless of what config.h records, and selects the
# BLAS implementation at link time from PYNEC_BACKEND.
if [ ! -f "$BUILD_NECPP/config.h" ]; then
    ( cd "$BUILD_NECPP" && make -f Makefile.git && ./configure --without-lapack )
fi

# SWIG wrapper (PyNEC.i -> PyNEC_wrap.cxx + PyNEC.py).
( cd "$PYNEC_DIR" && swig -Wall -c++ -python PyNEC.i )

echo "OK — generated config.h, the necpp_src tree, and PyNEC_wrap.cxx"
