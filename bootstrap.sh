#! /bin/sh -e
CFLAGS=" -Os -I../src "
LDFLAGS=" -lpthread"
LDFLAGS_ldpreload=" -fpic -shared -ldl "

if [ $OSTYPE != "linux-gnu" ]; then
    CFLAGS+=" -DTUP_NO_MONITOR -DTUP_NO_TOUCH "
fi

if [[ $OSTYPE == solaris* ]]; then
    CFLAGS+=" -DTUP_NO_READLINKAT "
    LDFLAGS+=" -lsocket "
    LDFLAGS_ldpreload+=" -lsocket "
    # Solaris needs a tup.config with these options for tup to self-host.
    echo CONFIG_TUP_NO_MONITOR=y >>tup.config
    echo CONFIG_TUP_NO_READLINKAT=y >>tup.config
    echo CONFIG_TUP_NO_TOUCH=y >>tup.config
    echo CONFIG_TUP_SOCKET_LIBRARY=y >>tup.config
fi

rm -rf build
echo "  mkdir build"
mkdir -p build
mkdir -p build/ldpreload
echo "  cd build"
cd build

for i in ../src/linux/*.c ../src/tup/*.c ../src/tup/tup/main.c; do
	echo "  bootstrap CC $i"
	gcc $CFLAGS -c $i
done

echo "  bootstrap CC ../src/sqlite3/sqlite3.c"
gcc -Os -c ../src/sqlite3/sqlite3.c -DSQLITE_TEMP_STORE=2 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION

echo "  bootstrap CC ../src/ldpreload/ldpreload.c"
gcc -Os -c ../src/ldpreload/ldpreload.c -o ldpreload/ldpreload.o -fpic -I../src

echo "  bootstrap LD.so tup-ldpreload.so"
gcc -o tup-ldpreload.so ldpreload/ldpreload.o $LDFLAGS_ldpreload

echo "  bootstrap LD tup"
echo "const char *tup_version(void) {return \"bootstrap\";}" | gcc -x c -c - -o tup_version.o
gcc *.o -o tup $LDFLAGS

cd ..
./build/tup init
./build/tup upd
echo "Build complete. If ./tup works, you can remove the 'build' directory."
