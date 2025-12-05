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

echo checking out v0.60 &&
git checkout --recurse-submodules v0.60 &&

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

echo checking out nextpnr-0.9
(cd ../src/nextpnr ; git checkout --recurse-submodules nextpnr-0.9) &&

(cd ../src/nextpnr ; patch -p1) << 'EOF' &&
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 562c718d..c50f4578 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -62,11 +62,6 @@ check_cxx_compiler_hash_embed(HAS_HASH_EMBED CXX_FLAGS_HASH_EMBED)
 set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS_HASH_EMBED}")
 if (EXTERNAL_CHIPDB)
     set(BBASM_MODE "binary")
-elseif (HAS_HASH_EMBED)
-    set(BBASM_MODE "embed")
-elseif (WIN32 AND NOT HAS_HASH_EMBED)
-    set(BBASM_MODE "resource")
-    add_definitions(-DBBAS_ARE_RESOURCES)
 else()
     set(BBASM_MODE "string")
 endif()
@@ -169,7 +164,7 @@ else()
     endif()
 endif()
 
-set(boost_libs filesystem program_options iostreams system)
+set(boost_libs program_options iostreams)
 if (Threads_FOUND)
     list(APPEND boost_libs thread)
 endif()
diff --git a/bba/CMakeLists.txt b/bba/CMakeLists.txt
index e2cba85f..437cd05f 100644
--- a/bba/CMakeLists.txt
+++ b/bba/CMakeLists.txt
@@ -4,12 +4,10 @@ project(bba CXX)
 set(CMAKE_CXX_STANDARD 17)
 
 find_package(Boost REQUIRED COMPONENTS
-    program_options
-    system)
+    program_options)
 
 add_executable(bbasm
     main.cc)
 target_link_libraries(bbasm LINK_PRIVATE
-    ${Boost_PROGRAM_OPTIONS_LIBRARY}
-    ${Boost_SYSTEM_LIBRARY})
+    ${Boost_PROGRAM_OPTIONS_LIBRARY})
 export(TARGETS bbasm FILE ${CMAKE_BINARY_DIR}/bba-export.cmake)
diff --git a/common/kernel/command.cc b/common/kernel/command.cc
index 637561b6..5493173c 100644
--- a/common/kernel/command.cc
+++ b/common/kernel/command.cc
@@ -28,9 +28,9 @@
 
 #include <boost/algorithm/string.hpp>
 #include <boost/algorithm/string/join.hpp>
-#include <boost/filesystem/path.hpp>
 #include <boost/program_options.hpp>
 #include <cinttypes>
+#include <filesystem>
 #include <fstream>
 #include <iostream>
 #include <random>
@@ -276,14 +276,14 @@ bool CommandHandler::parseOptions()
 bool CommandHandler::executeBeforeContext()
 {
     if (vm.count("help") || argc == 1) {
-        std::cerr << boost::filesystem::path(argv[0]).stem()
+        std::cerr << std::filesystem::path(argv[0]).stem()
                   << " -- Next Generation Place and Route (Version " GIT_DESCRIBE_STR ")\n";
         std::cerr << options << "\n";
         return argc != 1;
     }
 
     if (vm.count("version")) {
-        std::cerr << boost::filesystem::path(argv[0]).stem()
+        std::cerr << std::filesystem::path(argv[0]).stem()
                   << " -- Next Generation Place and Route (Version " GIT_DESCRIBE_STR ")\n";
         return true;
     }
diff --git a/common/kernel/embed.cc b/common/kernel/embed.cc
index 5ec2b79a..d4544bf6 100644
--- a/common/kernel/embed.cc
+++ b/common/kernel/embed.cc
@@ -3,7 +3,7 @@
 #define NOMINMAX
 #include <windows.h>
 #endif
-#include <boost/filesystem.hpp>
+#include <filesystem>
 #include <boost/iostreams/device/mapped_file.hpp>
 #include "embed.h"
 #include "nextpnr.h"
@@ -17,7 +17,7 @@ const void *get_chipdb(const std::string &filename)
     static std::map<std::string, boost::iostreams::mapped_file> files;
     if (!files.count(filename)) {
         std::string full_filename = EXTERNAL_CHIPDB_ROOT "/" + filename;
-        if (boost::filesystem::exists(full_filename))
+        if (std::filesystem::exists(full_filename))
             files[filename].open(full_filename, boost::iostreams::mapped_file::priv);
     }
     if (files.count(filename))
diff --git a/generic/viaduct/fabulous/fabulous.cc b/generic/viaduct/fabulous/fabulous.cc
index 6160ff72..07204947 100644
--- a/generic/viaduct/fabulous/fabulous.cc
+++ b/generic/viaduct/fabulous/fabulous.cc
@@ -36,7 +36,7 @@
 #include "pack.h"
 #include "validity_check.h"
 
-#include <boost/filesystem.hpp>
+#include <filesystem>
 
 NEXTPNR_NAMESPACE_BEGIN
 
@@ -62,7 +62,7 @@ struct FabulousImpl : ViaductAPI
         ViaductAPI::init(ctx);
         h.init(ctx);
         fab_root = get_env_var("FAB_ROOT", ", set it to the fabulous build output or project path");
-        if (boost::filesystem::exists(fab_root + "/.FABulous"))
+        if (std::filesystem::exists(fab_root + "/.FABulous"))
             is_new_fab = true;
         else
             is_new_fab = false;
diff --git a/himbaechel/arch.cc b/himbaechel/arch.cc
index e768fb84..840a6155 100644
--- a/himbaechel/arch.cc
+++ b/himbaechel/arch.cc
@@ -18,7 +18,6 @@
  */
 
 #include "arch.h"
-#include <boost/filesystem/path.hpp>
 #include "archdefs.h"
 #include "chipdb.h"
 #include "log.h"
@@ -31,6 +30,8 @@
 #include "router2.h"
 #include "util.h"
 
+#include <filesystem>
+
 NEXTPNR_NAMESPACE_BEGIN
 
 static constexpr int database_version = 6;
@@ -65,7 +66,7 @@ void Arch::load_chipdb(const std::string &path)
         db_path = proc_share_dirname();
         db_path += "himbaechel/";
         db_path += path;
-        boost::filesystem::path p(db_path);
+        std::filesystem::path p(db_path);
         db_path = p.make_preferred().string();
     }
     try {
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

patch -p1 << 'EOF' &&
diff --git a/configure b/configure
index 9b44ef607..dec318ff1 100755
--- a/configure
+++ b/configure
@@ -325,6 +325,7 @@ if test $backend = llvm -o $backend = llvm_jit; then
        check_version 18.1 $llvm_version ||
        check_version 19. $llvm_version ||
        check_version 20. $llvm_version ||
+       check_version 21. $llvm_version ||
        false; then
     echo "Debugging is enabled with llvm $llvm_version"
   else
EOF

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
