#!/bin/bash
#
# Build script for the PyNEC module. 
#
# Author. Tim Molteno.
#
# First have to do git submodule init
git submodule update --init
ln -sf ../necpp_src .
DIR=`pwd`
cd ../necpp_src
make -f Makefile.git
# Build with ATLAS-flavored LAPACK/BLAS. On Debian/Ubuntu the headers
# (clapack.h, cblas.h) live in a multiarch include dir, and the .so files
# live in the matching multiarch lib dir. libatlas-base-dev provides them.
MULTIARCH=$(gcc -print-multiarch 2>/dev/null || echo x86_64-linux-gnu)
CPPFLAGS="-I/usr/include/${MULTIARCH}" \
  LDFLAGS="-L/usr/lib/${MULTIARCH}" \
  ./configure --with-lapack
cd ${DIR}

# Build PyNEC
swig -Wall -v -c++ -python PyNEC.i
python3 setup.py build
