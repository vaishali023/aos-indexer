CC ?= $(EMCC)       # Emscripten compiler will be set by emmake
AR ?= $(EMAR)       # emar will be set by emmake
CFLAGS= -sMEMORY64=1 -Wno-experimental -O3
LUA_LIB= /opt/homebrew/Cellar/lua/5.4.7/lib/liblua.a 
LUA_INC= -I/opt/homebrew/Cellar/lua/5.4.7/include/lua

COMMIT=$(shell git rev-parse HEAD)
VERSION=$(shell cat VERSION)
DATE=$(shell date +'%FT%TZ%z')

all: libsqlite.so

libsqlitevec.so: sqlite-vec.o lsqlite3.o sqlite3.o
	$(AR) rcs libsqlitevec.so sqlite-vec.o lsqlite3.o sqlite3.o $(LUA_LIB)
	rm *.o

sqlite-vec.o: sqlite-vec.c
	$(CC) $(CFLAGS) -o sqlite-vec.o -c sqlite-vec.c -DSQLITE_CORE

lsqlite3.o: lsqlite3.c
	$(CC) $(CFLAGS) -o lsqlite3.o -c lsqlite3.c ${LUA_INC} -DSQLITE_CORE

sqlite3.o: sqlite3.c
	$(CC) $(CFLAGS) -o sqlite3.o -c sqlite3.c

clean:
	rm -f *.o *.so
