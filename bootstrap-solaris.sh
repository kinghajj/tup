# edited to make this script work on my OpenSolaris box.
# your results may vary; please inform us if you have problems.

#! /bin/sh -e
rm -rf build
echo "  mkdir build"
mkdir -p build
mkdir -p build/ldpreload
echo "  cd build"
cd build
for i in ../src/linux/*.c ../src/tup/*.c ../src/tup/tup/main.c; do
	echo "  bootstrap CC $i"
	gcc -Os -c $i -I../src -DTUP_NO_COLORS -DTUP_NO_MONITOR -DTUP_NO_TOUCH -DTUP_NO_READLINKAT
done

echo "  bootstrap CC ../src/sqlite3/sqlite3.c"
gcc -Os -c ../src/sqlite3/sqlite3.c -DSQLITE_TEMP_STORE=2 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION

echo "  bootstrap CC ../src/ldpreload/ldpreload.c"
gcc -Os -c ../src/ldpreload/ldpreload.c -o ldpreload/ldpreload.o -fpic -I../src

echo "  bootstrap LD.so tup-ldpreload.so"
gcc -fpic -shared -o tup-ldpreload.so ldpreload/ldpreload.o -ldl -lsocket

echo "  bootstrap LD tup"
echo "const char *tup_version(void) {return \"bootstrap\";}" | gcc -x c -c - -o tup_version.o
gcc *.o -o tup -lpthread -lsocket

cd ..

# Solaris needs a tup.config with these options for tup to self-host.
echo CONFIG_TUP_NO_MONITOR=y >>tup.config
echo CONFIG_TUP_NO_READLINKAT=y >>tup.config
echo CONFIG_TUP_NO_TOUCH=y >>tup.config
echo CONFIG_TUP_SOCKET_LIBRARY=y >>tup.config

./build/tup init
./build/tup upd
echo "Build complete. If ./tup works, you can remove the 'build' directory."
