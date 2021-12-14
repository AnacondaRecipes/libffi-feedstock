set -ex
test -e $PREFIX/lib/libffi${SHLIB_EXT}
test -e $PREFIX/lib/libffi.a
test -e $PREFIX/include/ffi.h
test -e $PREFIX/include/ffitarget.h
cd $PWD/testsuite/libffi.bhaible
echo "Triggering libffi tests"
make prefix=$PREFIX
echo "completed triggering the tests"
