#!/bin/sh

export PREFIX=/opt/toolflows

echo cloning sources.

cd src

git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
git checkout --recurse-submodules 6b5937db431d2fa1023d3865f21ccd9b65781492
# 7f6c37aa57467242807155c654deb350022d75c1

#patch -p1 << EOF
#EOF

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

