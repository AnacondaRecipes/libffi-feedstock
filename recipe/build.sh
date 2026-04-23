#!/bin/bash

set -ex
shopt -s extglob

cd $SRC_DIR

export CFLAGS="${CFLAGS//-fvisibility=+([! ])/}"
export CXXFLAGS="${CXXFLAGS//-fvisibility=+([! ])/}"

if [[ "$target_platform" == osx-* ]]; then
  export CFLAGS="${CFLAGS} -Wno-deprecated-declarations"
  export CXXFLAGS="${CXXFLAGS} -Wno-deprecated-declarations"
fi

configure_args=(
    --disable-debug
    --disable-dependency-tracking
    # The non-PIC build of src/aarch64/sysv.S fails with
    # "invalid CFI advance_loc expression" on the libtool static-object pass
    # under newer clang on osx-arm64. Consumers of libffi (Python, glib, ...)
    # only need the shared library, so skip the static build entirely.
    --disable-static
    --prefix="${PREFIX}"
    --includedir="${PREFIX}/include"
    --build=$BUILD
    --host=$HOST
)

autoreconf -vfi

if [[ "$target_platform" == linux* ]]; then
  # this changes the install dir from ${PREFIX}/lib64 to ${PREFIX}/lib
  sed -i 's:@toolexeclibdir@:$(libdir):g' Makefile.in */Makefile.in
  sed -i 's:@toolexeclibdir@:${libdir}:g' libffi.pc.in
fi

# Build out-of-tree to avoid libffi's auto-builddir feature, which re-execs
# configure into a per-host subdir and races against our parallel make,
# causing spurious CFI errors when assembling src/aarch64/sysv.S.
mkdir -p _build
cd _build

../configure "${configure_args[@]}" || { cat config.log; exit 1;}

echo "===== STEP: configure done, starting make ====="
make -j1 V=1
echo "===== STEP: make done, starting make install ====="
# make check
make V=1 install
echo "===== STEP: make install done ====="

cd ..

echo "===== STEP: listing PREFIX/lib ====="
ls -la "${PREFIX}/lib" || true

# This overlaps with libgcc-ng:
rm -rf ${PREFIX}/share/info/dir

# Make sure we provide old variant.  As in 3.4 no API change was introduced in coparison to 3.3
# we will go with the assumption of being backward compatible.
pushd $PREFIX/lib
# make sure we address also <lib>.so<.number>, and don't produce dead links
if [[ -f libffi${SHLIB_EXT}.8 ]]; then
  ln -s libffi${SHLIB_EXT}.8 libffi${SHLIB_EXT}.7
  if [[ ! -f libffi.8{SHLIB_EXT} ]]; then
    ln -s libffi${SHLIB_EXT}.8 libffi.8${SHLIB_EXT}
  fi
fi
ln -s -f libffi.8${SHLIB_EXT} libffi.7${SHLIB_EXT}
popd

