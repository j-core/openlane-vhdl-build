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

echo checking out v0.52 &&
git checkout --recurse-submodules v0.52 &&

patch -p1 << EOF &&
diff --git a/Makefile b/Makefile
--- a/Makefile
+++ b/Makefile
@@ -53,7 +53,7 @@ SANITIZER =
 PROGRAM_PREFIX :=

 OS := \$(shell uname -s)
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 INSTALL_SUDO :=

 ifneq (\$(wildcard Makefile.conf),)
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

LDFLAGS="-L/opt/homebrew/Cellar/zstd/1.5.7/lib -L/opt/homebrew/Cellar/icu4c@77/77.1/lib" cmake ../../src/nextpnr -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON &&
make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl

git clone ../src/ghdl &&
cd ghdl &&

echo LLVM requires close to tip of tree &&
# echo checking out v5.0.1 &&
# git checkout --recurse-submodules v5.0.1 &&

LDFLAGS="-L/opt/gcc-14.2.0-2-aarch64/lib/gcc/aarch64-apple-darwin23/14.2.0 -lgcc" PATH=$PATH:/opt/homebrew/Cellar/llvm/20.1.4/bin ./configure --with-llvm-config --prefix=$PREFIX

PATH=$PATH:/opt/homebrew/Cellar/llvm/20.1.4/bin make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl-yosys-plugin

git clone ../src/ghdl-yosys-plugin &&
cd ghdl-yosys-plugin &&
echo LLVM requires close to tip of tree &&
# git checkout --recurse-submodules 8c29f2cc7cc3b8c979acd02f543d25f321b55c30 &&

export PATH=$PREFIX/bin:$PATH &&
make &&
make install &&

cd .. || exit 1

cd ..
echo Done.
