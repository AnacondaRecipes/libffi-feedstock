#!/bin/bash

set -ex

export CFLAGS="${CFLAGS//-fvisibility=+([! ])/}"
export CXXFLAGS="${CXXFLAGS//-fvisibility=+([! ])/}"

if [[ $(uname) == "Linux" ]]; then
  # this changes the install dir from ${PREFIX}/lib64 to ${PREFIX}/lib
  sed -i 's:@toolexeclibdir@:$(libdir):g' Makefile.in */Makefile.in
  sed -i 's:@toolexeclibdir@:${libdir}:g' libffi.pc.in
fi

configure_args=(
    --disable-debug
    --disable-dependency-tracking
    --prefix="${PREFIX}"
    --includedir="${PREFIX}/include"
)

if [[ $(uname) == MINGW* ]]; then
  if [[ ${ARCH} == 32 ]]; then
    HOST_BUILD="i686-w64-mingw32"
  else
    HOST_BUILD="x86_64-w64-mingw32"
  fi
  configure_args+=(--build=$HOST_BUILD --host=$HOST_BUILD)
else
  # configure_args+=(--disable-static)
  configure_args+=(--build=$BUILD --host=$HOST)
  export CPPFLAGS="$CPPFLAGS -DFFI_BUILDING_DLL"
fi

echo "configuring ..."
./configure "${configure_args[@]}" \
  || { cat config.log; exit 1;}

echo "building ..."
make -j${CPU_COUNT} ${VERBOSE_AT}

if [[ -n "${QEMU_LD_PREFIX}" ]] && [[ "${HOST}" != "${BUILD}" ]]; then
  # Yuck. Dejagnu should instead pass '-Wl,-rpath=\$ORIGIN/../.libs' when building
  # tests or at least provide a way for us to pass that. In non-cross scenarios it
  # sets LD_LIBRARY_PATH (see set_ld_library_path_env_vars), and has no provisions
  # for QEMU at all.
  QEMU_SET_ENV="LD_LIBRARY_PATH=${SRC_DIR}/${HOST}/.libs" make check
else
  echo "do checking ..."
  make check
fi

echo "do install ..."
make install

# This overlaps with libgcc-ng:
rm -rf ${PREFIX}/share/info/dir

# libffi 3.3 is ABI compatible with libffi 3.2.x but changed SONAMEs (.6->.7).
# For compatibility with packages which do not have corrected dependency
# information, include a libffi.so.6/libffi.6.dylib symlink.
if [[ $(uname) == "Linux" ]]; then
    ln -s ${PREFIX}/lib/libffi.so.7 ${PREFIX}/lib/libffi.so.6
elif [[ $(uname) == MINGW* ]]; then
  mkdir -p $LIBRARY_INC
  mv $PREFIX/include/* $LIBRARY_INC/.
  mv $PREFIX/bin/libffi* $LIBRARY_BIN/.
  mv $PREFIX/lib/libffi* $LIBRARY_LIB/.
  echo "mingw build done ..."
else
    ln -s ${PREFIX}/lib/libffi.7.dylib ${PREFIX}/lib/libffi.6.dylib
fi

