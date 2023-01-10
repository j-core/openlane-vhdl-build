#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/boolector/boolector

cd ../build

git clone ../src/boolector
cd boolector
./contrib/setup-btor2tools.sh
./contrib/setup-lingeling.sh

./configure.sh --prefix $PREFIX

make -C build -j8

cp build/bin/b* $PREFIX/bin/
cp deps/btor2tools/bin/btorsim $PREFIX/bin/

cd ../..

echo Done.
