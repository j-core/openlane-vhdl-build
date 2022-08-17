#!/bin/sh

export PREFIX=/opt/toolflows

echo cloning sources.

cd src

git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git
cd OpenROAD
#git checkout --recurse-submodules c1c315118e68926dfff368f85e13bf50adaa920f
git checkout --recurse-submodules 4a99e88667b0840531ca0096c4fa0da8f80d6cb1

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

