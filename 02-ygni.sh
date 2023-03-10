#!/bin/sh

export PREFIX=/opt/toolflows

echo making install dir $PREFIX

# mkdir $PREFIX

echo clone all the things...
if [ 1 -eq 1 ]; then
mkdir src; cd src

git clone https://github.com/YosysHQ/icestorm.git
git clone https://github.com/YosysHQ/yosys.git
git clone https://github.com/YosysHQ/nextpnr.git

git clone https://github.com/ghdl/ghdl.git
git clone https://github.com/ghdl/ghdl-yosys-plugin.git

cd ..
fi
echo clone done

echo making build area

mkdir build; cd build

echo build icestorm
if [ 1 -eq 1 ]; then

git clone ../src/icestorm
cd icestorm

patch -p1 <<EOF
--- a/config.mk
+++ b/config.mk
@@ -1,4 +1,4 @@
-PREFIX ?= /usr/local
+PREFIX ?= $PREFIX
 DEBUG ?= 0
 ICEPROG ?= 1
 PROGRAM_PREFIX ?=
EOF

make -j8
make install

cd ..
fi

echo build yosys
if [ 1 -eq 1 ]; then

git clone ../src/yosys
cd yosys

# echo checking out v0.26 7e588664e7efa36ff473f0497feacaad57f5e90c
# git checkout --recurse-submodules 7e588664e7efa36ff473f0497feacaad57f5e90c
echo checking out v0.27 5f88c218b58cabc20f001c4bf77733670305864e
git checkout --recurse-submodules 5f88c218b58cabc20f001c4bf77733670305864e

patch -p1 << EOF
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

make -j8
make install

cd ..
fi

echo build nextpnr
if [ 1 -eq 1 ]; then

git clone ../src/nextpnr
cd nextpnr

# patch -p1 < ../../nextpnr.diff

cmake . -DARCH="ice40" -DCMAKE_INSTALL_PREFIX=$PREFIX -DICESTORM_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON
make -j8
make install

cd ..
fi

echo build ghdl
if [ 1 -eq 1 ]; then

git clone ../src/ghdl
cd ghdl 

echo checking out v3.0 7de967c51f352fe2d724dbec549b71a392e5ebae
git checkout --recurse-submodules 7de967c51f352fe2d724dbec549b71a392e5ebae

export PATH=/opt/gnat/bin:$PATH
#./configure --prefix=$PREFIX
./configure --with-llvm-config --prefix=$PREFIX

make -j8
make install

cd ..
fi

echo build ghdl-yosys-plugin
if [ 1 -eq 1 ]; then

git clone ../src/ghdl-yosys-plugin
cd ghdl-yosys-plugin

make clean;
export PATH=$PREFIX/bin:$PATH

make
make install
fi

cd ../../
echo Done.
