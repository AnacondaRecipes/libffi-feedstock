set MSYSTEM=MINGW%ARCH%
set MSYS2_PATH_TYPE=inherit
set CHERE_INVOKING=1
FOR /F "delims=" %%i in ('cygpath.exe -u "LIBRARY_PREFIX"') DO set "PREFIX=%%i"
FOR /F "delims=" %%i in ('cygpath.exe -u "BUILD_PREFIX"') DO set "BUILD_PREFIX=%%i"
FOR /F "delims=" %%i in ('cygpath.exe -u "SRC_DIR"') DO set "SRC_DIR=%%i"
FOR /F "delims=" %%i in ('cygpath.exe -u "RECIPE_DIR"') DO set "RECIPE_DIR=%%i"
bash -lce build.sh
if %ERRORLEVEL% neq 0 exit 1
copy %LIBRARY_LIB%\libffi.lib %LIBRARY_LIB%\ffi.lib
