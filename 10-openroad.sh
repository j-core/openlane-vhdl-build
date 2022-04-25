#!/bin/sh

export PREFIX=/opt/toolflows

echo cloning sources.

cd src

git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
git checkout --recurse-submodules c1c315118e68926dfff368f85e13bf50adaa920f

patch -p1 << EOF
diff --git a/src/cts/src/CMakeLists.txt b/src/cts/src/CMakeLists.txt
index 3b0a21ea2..0b0ec2812 100644
--- a/src/cts/src/CMakeLists.txt
+++ b/src/cts/src/CMakeLists.txt
@@ -35,7 +35,7 @@
 
 include("openroad")
 
-find_package(LEMON REQUIRED)
+find_package(LEMON NAMES LEMON lemon REQUIRED)
 
 swig_lib(NAME      cts
          NAMESPACE cts
diff --git a/src/dpo/CMakeLists.txt b/src/dpo/CMakeLists.txt
index 0eddbe67e..908765ed2 100644
--- a/src/dpo/CMakeLists.txt
+++ b/src/dpo/CMakeLists.txt
@@ -38,7 +38,7 @@ swig_lib(NAME         dpo
          SCRIPTS      src/Optdp.tcl
 )
 
-find_package(LEMON REQUIRED)
+find_package(LEMON NAMES LEMON lemon REQUIRED)
 
 target_sources(dpo
   PRIVATE
EOF

cd ..

echo Building OpenROAD for install to $PREFIX

mkdir ../build/openroad
cd ../build/openroad

cmake ../../src/OpenROAD -DCMAKE_INSTALL_PREFIX=$PREFIX

echo Configured.

make -j8

echo Install...

make install

cd ../..

echo Done.

