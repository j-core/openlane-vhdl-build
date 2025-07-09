#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX

echo making install dir $PREFIX

# mkdir $PREFIX

echo clone all the things...
mkdir src ; cd src

git clone https://github.com/YosysHQ/icestorm.git &&
git clone --recursive https://github.com/YosysHQ/yosys.git &&
git clone https://github.com/YosysHQ/nextpnr.git &&

git clone https://github.com/ghdl/ghdl.git &&
git clone https://github.com/ghdl/ghdl-yosys-plugin.git &&

cd .. || exit 1

echo clone done

echo making build area

mkdir build; cd build

echo build icestorm

git clone ../src/icestorm &&
cd icestorm &&

patch -p1 <<EOF &&
--- a/config.mk
+++ b/config.mk
@@ -1,4 +1,4 @@
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 DEBUG ?= 0
 ICEPROG ?= 1
 PROGRAM_PREFIX ?=
EOF

make -j12 &&
make install &&

cd .. || exit 1

echo build yosys

git clone --recursive ../src/yosys &&
cd yosys &&

echo checking out v0.55 &&
git checkout --recurse-submodules v0.55 &&

patch -p1 << 'EOF' &&
diff --git a/Makefile b/Makefile
--- a/Makefile
+++ b/Makefile
@@ -26,7 +26,7 @@ ENABLE_LIBYOSYS := 0
 ENABLE_ZLIB := 1

 # python wrappers
-ENABLE_PYOSYS := 0
+ENABLE_PYOSYS := 1

 # other configuration flags
 ENABLE_GCOV := 0
@@ -60,7 +60,7 @@ CLANG_LTO := -flto=thin
 PROGRAM_PREFIX :=

 OS := $(shell uname -s)
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 INSTALL_SUDO :=
 ifneq ($(filter MINGW%,$(OS)),)
 OS := MINGW
EOF

make config-gcc
make -j12 &&
make install &&

cd .. || exit 1

echo build nextpnr

echo checking out nextpnr-0.8
(cd ../src/nextpnr ; git checkout --recurse-submodules nextpnr-0.8) &&

(cd ../src/nextpnr ; patch -p1) << 'EOF' &&
diff --git a/CMakeLists.txt b/CMakeLists.txt
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -62,10 +62,6 @@ check_cxx_compiler_hash_embed(HAS_HASH_EMBED CXX_FLAGS_HASH_EMBED)
 set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_HASH_EMBED}")
 if (EXTERNAL_CHIPDB)
     set(BBASM_MODE "binary")
-elseif (HAS_HASH_EMBED)
-    set(BBASM_MODE "embed")
-elseif (WIN32)
-    set(BBASM_MODE "resource")
 else()
     set(BBASM_MODE "string")
 endif()
EOF

mkdir nextpnr &&
cd nextpnr &&
mkdir ../../src/nextpnr/tests/gui &&
touch ../../src/nextpnr/tests/gui/CMakeLists.txt &&

LDFLAGS="-L/opt/homebrew/opt/zstd/lib -L/opt/homebrew/opt/icu4c/lib" cmake ../../src/nextpnr -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON &&
make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl

git clone ../src/ghdl &&
cd ghdl &&

echo LLVM requires close to tip of tree &&
echo checking out v5.1.1 &&
git checkout --recurse-submodules v5.1.1 &&

LDFLAGS="-L/opt/gcc-14.2.0-2-aarch64/lib/gcc/aarch64-apple-darwin23/14.2.0 -lgcc" PATH=$PATH:/opt/homebrew/opt/llvm/bin ./configure --with-llvm-config --prefix=$PREFIX

PATH=$PATH:/opt/homebrew/opt/llvm/bin make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl-yosys-plugin

git clone ../src/ghdl-yosys-plugin &&
cd ghdl-yosys-plugin &&
echo LLVM requires close to tip of tree &&

export PATH=$PREFIX/bin:$PATH &&
make &&
make install &&

ln -s /opt/gcc-14.2.0-2-aarch64/lib/gcc/aarch64-apple-darwin23/14.2.0/adalib/libgnat-14.dylib /opt/toolflows/lib/libgnat-14.dylib

cd .. || exit 1

cd ..
echo Done.
