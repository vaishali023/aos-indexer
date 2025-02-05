# Compiler and flags
CC ?= emcc
AR ?= emar
CFLAGS = -sMEMORY64=1 -Wno-experimental -O3
LUA_INC = -I/usr/local/include/lua5.4
AO_IMAGE = "my-ao-db"

# Directories
LIB_SQLITE_VEC_DIR = src/lib/sqlite-vec
LIB_SQLITE3_DIR = src/lib/lsqlite
SRC_PROCESS_DIR = src/process
VENDOR_DIR = vendor
VENDOR_SQLITE_DIR = $(VENDOR_DIR)/sqlite
VENDOR_AOS_DIR = $(VENDOR_DIR)/aos
BUILD_DIR = .build

# Docker command
DOCKER = docker run --platform linux/amd64 -v $(PWD):/worker $(AO_IMAGE)

# Dependencies
SQLITE_VEC_DEPENDENCY = $(LIB_SQLITE_VEC_DIR)/sqlite-vec.c $(BUILD_DIR)
LSQLITE3_DEPENDENCY = $(LIB_SQLITE3_DIR)/lsqlite3.c $(LIB_SQLITE_VEC_DIR)/sqlite-vec.h

# Build options
SQLITE_VEC_EMCC_OPTION = $(CFLAGS) -o sqlite-vec.o -c $(LIB_SQLITE_VEC_DIR)/sqlite-vec.c -I$(VENDOR_SQLITE_DIR) -DSQLITE_CORE
LSQLITE3_EMCC_OPTION = $(CFLAGS) -o lsqlite3.o -c $(LIB_SQLITE3_DIR)/lsqlite3.c $(LUA_INC) -I$(VENDOR_SQLITE_DIR) \
                       -I$(LIB_SQLITE_VEC_DIR) -DSQLITE_CORE -DLUA_USE_LINUX
SQLITE3_EMCC_OPTION = $(CFLAGS) -o sqlite3.o -c $(VENDOR_SQLITE_DIR)/sqlite3.c

# Targets
$(BUILD_DIR)/sqlite/libsqlite.so: $(BUILD_DIR)/lsqlite3.o $(BUILD_DIR)/sqlite-vec.o $(BUILD_DIR)/sqlite3.o
	mkdir -p $(BUILD_DIR)/sqlite
	$(DOCKER) sh -c "cd /worker && emar rcs .build/sqlite/libsqlite.so .build/sqlite-vec.o .build/lsqlite3.o .build/sqlite3.o"
	rm -rf $(BUILD_DIR)/lsqlite3.o $(BUILD_DIR)/sqlite-vec.o $(BUILD_DIR)/sqlite3.o

$(BUILD_DIR)/lsqlite3.o: $(LSQLITE3_DEPENDENCY) $(BUILD_DIR)
	$(DOCKER) sh -c "cd /worker && emcc $(LSQLITE3_EMCC_OPTION)"
	mv lsqlite3.o $(BUILD_DIR)/

$(BUILD_DIR)/sqlite-vec.o: $(SQLITE_VEC_DEPENDENCY) $(BUILD_DIR)
	$(DOCKER) sh -c "cd /worker && emcc $(SQLITE_VEC_EMCC_OPTION)"
	rm -rf $(BUILD_DIR)/sqlite-vec.o && mv sqlite-vec.o $(BUILD_DIR)/sqlite-vec.o

$(BUILD_DIR)/sqlite3.o: $(BUILD_DIR)
	$(DOCKER) sh -c "cd /worker && emcc $(SQLITE3_EMCC_OPTION)"
	rm -rf $(BUILD_DIR)/sqlite3.o && mv sqlite3.o $(BUILD_DIR)/sqlite3.o

vendor: ${VENDOR_SQLITE_DIR} ${VENDOR_AOS_DIR}


$(VENDOR_SQLITE_DIR): $(VENDOR_DIR)
	mkdir -p $(VENDOR_SQLITE_DIR)
	curl -O "https://www.sqlite.org/2024/sqlite-autoconf-3460100.tar.gz"
	tar zxvf sqlite-autoconf-3460100.tar.gz
	mv sqlite-autoconf-3460100/* $(VENDOR_SQLITE_DIR)/
	rm -rf sqlite-autoconf-3460100*

$(VENDOR_AOS_DIR): $(VENDOR_DIR)
	curl -L -o aos.zip https://github.com/permaweb/aos/archive/main.zip
	unzip aos.zip
	mv aos-main aos && mv aos $(VENDOR_DIR)/
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
