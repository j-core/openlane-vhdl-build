#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX

echo making install dir $PREFIX

# mkdir $PREFIX

echo clone all the things...
mkdir src ; cd src

git clone https://github.com/YosysHQ/icestorm.git &&
git clone https://github.com/YosysHQ/yosys.git &&
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

make -j$(nproc) &&
make install &&

cd .. || exit 1

echo build yosys

git clone ../src/yosys &&
cd yosys &&

#echo checking out v0.28 0d6f4b068338c25f3de4ddab0747f714602037b5
#git checkout --recurse-submodules 0d6f4b068338c25f3de4ddab0747f714602037b5
echo checking out v0.29 9c5a60eb20104f7c320e263631c1371af9576911 &&
git checkout --recurse-submodules 9c5a60eb20104f7c320e263631c1371af9576911 &&

patch -p1 << EOF &&
diff --git a/Makefile b/Makefile
index 826562fdf..b9e473d6c 100644
--- a/Makefile
+++ b/Makefile
@@ -1,5 +1,5 @@

-CONFIG := clang
+# CONFIG := clang
-# CONFIG := gcc
+CONFIG := gcc
 # CONFIG := afl-gcc
 # CONFIG := emcc
@@ -53,7 +53,7 @@ SANITIZER =
 PROGRAM_PREFIX :=

 OS := \$(shell uname -s)
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 INSTALL_SUDO :=

 ifneq (\$(wildcard Makefile.conf),)
EOF

make -j$(nproc) &&
make install &&

cd .. || exit 1

echo build nextpnr

git clone ../src/nextpnr &&
cd nextpnr &&

# patch -p1 < ../../nextpnr.diff

cmake . -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON &&
make -j$(nproc) &&
make install &&

cd .. || exit 1

echo build ghdl

git clone ../src/ghdl &&
cd ghdl &&

echo checking out v3.0 7de967c51f352fe2d724dbec549b71a392e5ebae &&
git checkout --recurse-submodules 7de967c51f352fe2d724dbec549b71a392e5ebae &&

# On MacOS, gnat lives in /opt
export PATH=/opt/gnat/bin:$PATH &&
#./configure --prefix=$PREFIX                    # for mcode
./configure --with-llvm-config --prefix=$PREFIX  # for llvm backend

make -j$(nproc) &&
make install &&

cd .. || exit 1

echo build ghdl-yosys-plugin

git clone ../src/ghdl-yosys-plugin &&
cd ghdl-yosys-plugin &&

export PATH=$PREFIX/bin:$PATH &&
make &&
make install &&

cd .. || exit 1

cd ..
echo Done.
