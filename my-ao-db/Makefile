CC ?= $(EMCC)       # Emscripten compiler will be set by emmake
AR ?= $(EMAR)       # emar will be set by emmake
CFLAGS= -sMEMORY64=1 -Wno-experimental -O3
LUA_INC= -I/opt/homebrew/Cellar/lua/5.4.7/include/lua
AO_IMAGE="p3rmaw3b/ao:0.1.4"

AOS_GITHUB_COMMIT=958aeeb41aa4f6b7dc17f89bfd3be2d7a22a908a

LIB_SQLITE_VEC_DIR=src/lib/sqlite-vec
LIB_SQLITE3_DIR=src/lib/lsqlite

EMXX_CFLAGS=-s MEMORY64=1
SRC_PROCESS_DIR=src/process

VENDOR_DIR=vendor/
VENDOR_SQLITE_DIR=vendor/sqlite
VENDOR_AOS_DIR=vendor/aos
BUILD_DIR = .build

DOCKER = docker run --platform linux/amd64

SQLITE_VEC_DEPENDENCY=${LIB_SQLITE_VEC_DIR}/sqlite-vec.c ${BUILD_DIR}

SQLITE_VEC_EMCC_OPTION=$(CFLAGS) -o sqlite-vec.o -c ${LIB_SQLITE_VEC_DIR}/sqlite-vec.c -I${VENDOR_SQLITE_DIR} -DSQLITE_CORE

LSQLITE3_DEPENDENCY=${LIB_SQLITE3_DIR}/lsqlite3.c ${LIB_SQLITE_VEC_DIR}/sqlite-vec.h

LSQLITE3_EMCC_OPTION=$(CFLAGS) -o lsqlite3.o -c ${LIB_SQLITE3_DIR}/lsqlite3.c ${LUA_INC} -I${VENDOR_SQLITE_DIR} \
                     -I${LIB_SQLITE_VEC_DIR} -DSQLITE_CORE

SQLITE3_EMCC_OPTION=$(CFLAGS) -o sqlite3.o -c ${VENDOR_SQLITE_DIR}/sqlite3.c 

SQLITE_DEPENDENCY=${VENDOR_SQLITE_DIR}
SQLITE_EMCC_OPTION=

all: ${BUILD_DIR}/process.js ${BUILD_DIR}/process.wasm

${BUILD_DIR}/process.js ${BUILD_DIR}/process.wasm: ${BUILD_DIR}/sqlite/libsqlite.so ${BUILD_DIR}
	rm -rf ${VENDOR_AOS_DIR}/process/libs && mkdir -p ${VENDOR_AOS_DIR}/process/libs
	cp ${SRC_PROCESS_DIR}/config.yml ${VENDOR_AOS_DIR}/process/
	cp ${SRC_PROCESS_DIR}/config.yml ${VENDOR_AOS_DIR}/
	cp -r ${BUILD_DIR}/* ${VENDOR_AOS_DIR}/process/libs/
	${DOCKER} -e DEBUG=1 --platform linux/amd64 -v ./${VENDOR_AOS_DIR}/process:/src ${AO_IMAGE} ao-build-module
	rm -rf test/process.js && mv ${VENDOR_AOS_DIR}/process/process.js test/
	rm -rf test/process.wasm && mv ${VENDOR_AOS_DIR}/process/process.wasm test/

${BUILD_DIR}/sqlite/libsqlite.so: ${BUILD_DIR}/lsqlite3.o ${BUILD_DIR}/sqlite-vec.o ${BUILD_DIR}/sqlite3.o
	mkdir -p ${BUILD_DIR}/sqlite
	${DOCKER} -v ./.build:/worker ${AO_IMAGE} sh -c \
    "cd /worker && emar rcs sqlite/libsqlite.so sqlite-vec.o lsqlite3.o sqlite3.o"
	rm -rf ${BUILD_DIR}/lsqlite3.o ${BUILD_DIR}/sqlite-vec.o ${BUILD_DIR}/sqlite3.o

${BUILD_DIR}/lsqlite3.o: ${LSQLITE3_DEPENDENCY} ${BUILD_DIR}
	${DOCKER} -v .:/worker ${AO_IMAGE} sh -c \
    "cd /worker && emcc ${LSQLITE3_EMCC_OPTION}"
	mv lsqlite3.o .build/

${BUILD_DIR}/sqlite-vec.o: ${SQLITE_VEC_DEPENDENCY} ${BUILD_DIR}
	${DOCKER} -v .:/worker ${AO_IMAGE} sh -c \
    "cd /worker && emcc ${SQLITE_VEC_EMCC_OPTION}"
	rm -rf .build/sqlite-vec.o && mv sqlite-vec.o .build/sqlite-vec.o

${BUILD_DIR}/sqlite3.o: ${BUILD_DIR}
	${DOCKER} -v .:/worker ${AO_IMAGE} sh -c \
    "cd /worker && emcc ${SQLITE3_EMCC_OPTION}"
	rm -rf .build/sqlite3.o && mv sqlite3.o .build/sqlite3.o

vendor: ${VENDOR_SQLITE_DIR} ${VENDOR_AOS_DIR}

${VENDOR_SQLITE_DIR}: ${VENDOR_DIR}
	mkdir -p vendor/sqlite
	curl -O "https://www.sqlite.org/2024/sqlite-autoconf-3460100.tar.gz"
	tar zxvf sqlite-autoconf-3460100.tar.gz
	mv sqlite-autoconf-3460100/* ${VENDOR_SQLITE_DIR}/
	rm -rf sqlite-autoconf-3460100*

${VENDOR_AOS_DIR}: ${VENDOR_DIR}
	curl -L -o aos.zip https://github.com/permaweb/aos/archive/${AOS_GITHUB_COMMIT}.zip
	unzip aos.zip
	mv aos-${AOS_GITHUB_COMMIT} aos && mv aos vendor/
	rm aos.zip

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(VENDOR_DIR):
	mkdir -p $(VENDOR_DIR)

clean:
	sudo rm -rf .build
	sudo rm -rf ${VENDOR_AOS_DIR}/process/libs/*
	sudo rm -rf test/process.js test/process.wasm
	sudo rm -rf ${VENDOR_AOS_DIR}/process/config.yml
	sudo rm -rf ${VENDOR_AOS_DIR}/config.yml
