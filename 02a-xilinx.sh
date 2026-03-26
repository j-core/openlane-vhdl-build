#!/bin/bash

export PREFIX=/home/jeff/opt/toolflows

SRC = `pwd`/src
BLD = `pwd`/build

mkdir $SRC
cd $SRC

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

cd "$SRC"/nextpnr-xilinx/xilinx

GM=700
G=$GM

for i in external/prjxray-db/[aks]*7/xc*-*
do
  OUT="$BLD"/xray/$(basename $(dirname $i))
  PART=$(basename $i)
  echo "$PART"
  mkdir -p "$OUT"
  { pypy3 python/bbaexport.py --device $PART --bba $OUT/$PART.bba &&
    $BLD/nextpnr-xilinx/bbasm -l $OUT/$PART.bba $OUT/$PART.bin &&
    rm -f $OUT/$PART.bba || exit 1; } &
#  sleep 1 &

  PG=`echo "$PART" | sed -e "s/xc7.//" -e "s/[^0-9].*//"`
  G=`expr $G - $PG`
#  echo kgates remaining $G
  [ $G -lt 0 ] && { wait; G=$GM; }
done
wait

echo clone db into share

mkdir -p $PREFIX/share
(cd $PREFIX/share; git clone https://github.com/openxc7/prjxray-db)

cd "$BLD"/xray

for i in `find . -name xc\*.bin`
do 
  bn=`basename $i | sed -e s/.bin//`
  dn=`dirname $i`

  cp -v $i $PREFIX/share/prjxray-db/$dn/$bn/$bn.bin
done

cd "$SRC"

echo clone project xray

git clone --recursive https://github.com/f4pga/prjxray.git

cd ../build
mkdir prjxray
cd prjxray

cmake ../../src/prjxray -DCMAKE_INSTALL_PREFIX=$PREFIX

make -C tools xc7frames2bit
make -C tools install xc7frames2bit

echo Manually install the python utilities

cd ../../src/prjxray/utils
mkdir -p $PREFIX/share/prjxray/utils

cp `find . -name \*.py` /home/jeff/opt/toolflows/share/prjxray/utils
ln -s $PREFIX/share/prjxray/utils/fasm2frames.py $PREFIX/bin/fasm2frames
