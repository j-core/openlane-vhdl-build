#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/boolector/boolector
git clone https://github.com/Z3Prover/z3.git

cd ../build

git clone ../src/boolector
cd boolector
./contrib/setup-btor2tools.sh
./contrib/setup-lingeling.sh

./configure.sh --prefix $PREFIX

make -C build -j8

cp build/bin/b* $PREFIX/bin/
cp deps/btor2tools/bin/btorsim $PREFIX/bin/

mkdir ../z3
cd ../z3

cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$PREFIX ../../src/z3

make -j8
make install

cd ../..

echo Done.
