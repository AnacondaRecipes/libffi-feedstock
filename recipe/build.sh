#!/usr/bin/env bash

set -e -x
shopt -s extglob

export CFLAGS="${CFLAGS//-fvisibility=+([! ])/}"
export CXXFLAGS="${CXXFLAGS//-fvisibility=+([! ])/}"

configure_args=(
    --disable-debug
    --disable-dependency-tracking
    --prefix="${PREFIX}"
    --includedir="${PREFIX}/include"
)

if [[ "$target_platform" == osx-arm64 ]]; then
  configure_args+=(--build=aarch64-apple-darwin20.0.0 --host=$HOST)
elif [["$target_platform" == osx-*  ]]; then
  echo "osx ..."
elif [["$target_platform" == linux-*  ]]; then
  echo "linux ..."
else  # windows case
  configure_args+=(--disable-static)
  export CPPFLAGS="${CPPFLAGS} -DFFI_BUILDING_DLL"
  export CFLAGS="${CFLAGS} -DFFI_BUILDING_DLL"
fi

if [[ "$target_platform" == osx-* ]]; then
  export CFLAGS="${CFLAGS} -Wno-deprecated-declarations"
  export CXXFLAGS="${CXXFLAGS} -Wno-deprecated-declarations"
  export CPP="${CC} -E"
  export CXXCPP="${CXX} -E"
else
 autoreconf -vfi
fi

if [[ "$target_platform" == linux* ]]; then
  # this changes the install dir from ${PREFIX}/lib64 to ${PREFIX}/lib
  sed -i 's:@toolexeclibdir@:$(libdir):g' Makefile.in */Makefile.in
  sed -i 's:@toolexeclibdir@:${libdir}:g' libffi.pc.in
fi

./configure "${configure_args[@]}" || { cat config.log; exit 1;}
if [[ "$target_platform" == win-64 ]]; then
  pushd x86_64-pc-mingw64
    patch_libtool
    sed -i.bak 's/|-fuse-ld/|-Xclang|-fuse-ld/g' libtool
  popd
fi

make -j${CPU_COUNT} ${VERBOSE_AT}
make check
make install

# This overlaps with libgcc-ng:
rm -rf ${PREFIX}/share/info/dir

if [[ "$target_platform" == win-64 ]]; then
  mv $PREFIX/lib/ffi.dll.lib $PREFIX/lib/libffi.dll.lib
fi
