#!/bin/bash

export PREFIX=/opt/toolflows

mkdir src
cd src

echo clone Xilinx NextPNR branch

git clone --recursive https://github.com/openXC7/nextpnr-xilinx.git

echo Patching

cd nextpnr-xilinx
patch -p1 << 'EOF' &&
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 1ba70080..3a3e243e 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -99,7 +99,7 @@ endif()
 find_package(Sanitizers)

 # List of Boost libraries to include
-set(boost_libs filesystem thread program_options iostreams system)
+set(boost_libs filesystem thread program_options iostreams)

 if (BUILD_GUI AND NOT BUILD_PYTHON)
     message(FATAL_ERROR "GUI requires Python to build")
@@ -284,7 +284,7 @@ foreach (family ${ARCH})
         # Include family-specific source files to all family targets and set defines appropriately
         target_include_directories(${target} PRIVATE ${family}/ ${CMAKE_CURRENT_BINARY_DIR}/generated/)
         target_compile_definitions(${target} PRIVATE NEXTPNR_NAMESPACE=nextpnr_${family} ARCH_${ufamily} ARCHNAME=${family})
-        target_link_libraries(${target} LINK_PUBLIC ${Boost_LIBRARIES} ${link_param})
+        target_link_libraries(${target} LINK_PUBLIC ${Boost_LIBRARIES} Eigen3::Eigen ${link_param})
         if (NOT MSVC)
             target_link_libraries(${target} LINK_PUBLIC pthread)
         endif()
EOF

mkdir ../../build
cd ../../build

echo make nextpnr-xilinx

mkdir nextpnr-xilinx
cd nextpnr-xilinx

LDFLAGS="-L/opt/homebrew/opt/zstd/lib -L/opt/homebrew/opt/icu4c/lib" cmake ../../src/nextpnr-xilinx -DARCH="xilinx" -DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF -DSTATIC_BUILD=ON -DUSE_OPENMP=OFF

make -j6
make install
