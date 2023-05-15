#!/bin/bash

: ${PREFIX:=/opt/toolflows}
export PREFIX PATH="$PATH:$PREFIX"/bin

# I really hope this is no longer needed. TODO: look up fd leak fix commit #
prlimit -p $$ --nofile=65536:65536

echo clone pdk

if [ -d skywater-pdk ]
then
  echo using existing pdk dir
elif [ -e skywater-pdk.txz ]
then
  tar xvf skywater-pdk.txz || exit 1
else
  # Check out skywater-pdk ourselves and delete anaconda entirely.
  git clone https://github.com/google/skywater-pdk &&
  cd skywater-pdk &&
  # Delete submodule
  git rm --cached third_party/make-env &&
  sed -i '/make-env/d' .gitmodules &&
  # Delete redundant attempt to check out submodule
  sed '/conda.mk:/{N;d}' Makefile &&
  git submodule init &&
  git submodule update && cd .. || exit 1
fi

git clone https://github.com/RTimothyEdwards/open_pdks.git || exit 1

echo build pdk

cd open_pdks

./configure --prefix=$PREFIX --with-sky130-variants=A --enable-sky130-pdk

# Pass our fixed skywater-pdk into the build, both exported (so make -f child
# processes get it) and on the command line (so attempts to assign to it from
# the top level makefile are ignored).
export SKYWATER_PATH="$PWD/../skywater-pdk"

# call make twice (with no args), then call install
# because https://github.com/RTimothyEdwards/open_pdks/issues/315
for i in "" "" install
do
  echo "${i:-make} the pdk"
  make SKYWATER_PATH="$SKYWATER_PATH" $i  # Not quoted so empty string drops out
done

echo SOURCES timestamp
touch /opt/toolflows/share/pdk/sky130A/SOURCES

echo tlef link for DFFRAM
ln -s /opt/toolflows/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef \
      /opt/toolflows/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd.tlef

cd ..
