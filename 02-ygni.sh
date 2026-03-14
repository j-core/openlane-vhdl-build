#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX
export SCR=/home/jeff/openlane-vhdl-build

echo making install dir $PREFIX

# mkdir $PREFIX

echo clone all the things...
mkdir src ; cd src

git clone https://github.com/YosysHQ/icestorm.git &&
git clone --recursive https://github.com/YosysHQ/yosys.git &&
git clone https://github.com/YosysHQ/nextpnr.git &&

git clone https://github.com/ghdl/ghdl.git &&
git clone https://github.com/ghdl/ghdl-yosys-plugin.git &&

git clone https://codeberg.org/djeffdionne/yosys_vhdl_backend.git &&
git clone https://codeberg.org/djeffdionne/yosys_vhdl_rename.git &&

cd .. || exit 1

echo clone done

echo making build area

mkdir build; cd build

echo build icestorm

git clone ../src/icestorm &&
cd icestorm &&

patch -p1 < $SCR/patches/0023-ftx.diff || exit 1

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

echo checking out v0.63 &&
git checkout --recurse-submodules v0.63 &&

patch -p1 << 'EOF' &&
diff --git a/Makefile b/Makefile
index 1c1e19f5f..1142c983f 100644
--- a/Makefile
+++ b/Makefile
@@ -28,7 +28,7 @@ ENABLE_ZLIB := 1
 ENABLE_HELP_SOURCE := 0

 # python wrappers
-ENABLE_PYOSYS := 0
+ENABLE_PYOSYS := 1
 PYOSYS_USE_UV := 1

 # other configuration flags
@@ -68,7 +68,7 @@ CLANG_LTO := -flto=thin
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

echo checking out nextpnr-0.10
(cd ../src/nextpnr ; git checkout --recurse-submodules nextpnr-0.10) &&

mkdir nextpnr &&
cd nextpnr &&
#mkdir ../../src/nextpnr/tests/gui &&
#touch ../../src/nextpnr/tests/gui/CMakeLists.txt &&

LDFLAGS="-L/opt/homebrew/opt/zstd/lib -L/opt/homebrew/opt/icu4c/lib" cmake ../../src/nextpnr -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON &&
make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl

git clone ../src/ghdl &&
cd ghdl &&

echo LLVM requires close to tip of tree &&
echo checking out v6.0.0 &&
git checkout --recurse-submodules v6.0.0 &&

patch -p1 < $SCR/patches/ghdl-recursive-record-expansion.patch || exit 1

LDFLAGS="-L/opt/gcc-14.2.0-2-aarch64/lib/gcc/aarch64-apple-darwin23/14.2.0 -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib" PATH=$PATH:/opt/homebrew/opt/llvm/bin ./configure --with-llvm-config --prefix=$PREFIX

PATH=$PATH:/opt/homebrew/opt/llvm/bin make -j12 &&
make install &&

cd .. || exit 1

echo build ghdl-yosys-plugin

git clone ../src/ghdl-yosys-plugin &&
cd ghdl-yosys-plugin &&
git checkout 07a30ed39fb6a078f1bf7e9e88ce9ed712380ec2 &&
echo LLVM requires close to tip of tree &&

export PATH=$PREFIX/bin:$PATH &&
make &&
make install &&

ln -s /opt/gcc-14.2.0-2-aarch64/lib/gcc/aarch64-apple-darwin23/14.2.0/adalib/libgnat-14.dylib /opt/toolflows/lib/libgnat-14.dylib

cd .. || exit 1

git clone ../src/yosys_vhdl_backend &&
cd yosys_vhdl_backend &&
make &&
make install &&

cd .. || exit 1

git clone ../src/yosys_vhdl_rename &&
cd yosys_vhdl_rename &&
make &&
make install &&

cd .. || exit 1

cd ..
echo Done.
