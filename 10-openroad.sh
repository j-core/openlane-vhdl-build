#!/bin/sh

: ${PREFIX:=/opt/toolflows}
export PREFIX

echo cloning sources.

cd src &&
git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git &&
cd OpenROAD &&
git checkout --recurse-submodules 7f6c37aa57467242807155c654deb350022d75c1 &&

#patch -p1 << EOF
#EOF

cd .. || exit 1

echo Building OpenROAD for install to $PREFIX

mkdir ../build/openroad &&
cd ../build/openroad &&
cmake ../../src/OpenROAD -DCMAKE_INSTALL_PREFIX=$PREFIX &&
echo Configured. &&
make -j$(nproc) &&
echo Install... &&
make install &&

cd ../.. || exit 1

echo Done.

