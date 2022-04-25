#!/bin/sh

mkdir klayout
mkdir /opt/toolflows/share/klayout

cd klayout

git clone https://github.com/KLayout/klayout.git
cd klayout

./build.sh -j8 -prefix /opt/toolflows/share/klayout

ln -s /opt/toolflows/share/klayout/klayout /opt/toolflows/bin

echo Done.

