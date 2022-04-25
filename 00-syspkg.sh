#!/bin/sh

#echo Installing packages for bootloader

#apt-get install grub
#grub-install /dev/sda
#update-grub

echo Installing packages for toolchains and toolflows...

apt-get install vim
apt-get install build-essential manpages-dev
apt-get install tcl-dev
apt-get install tk-dev
apt-get install libboost-dev
apt-get install gnat
apt-get install git
apt-get install mercurial
apt-get install libreadline-dev
apt-get install libxt-dev
apt-get install wxgtk3.0
apt-get install autoconf
apt-get install cmake
apt-get install libftdi-dev
apt-get install libffi-dev
apt-get install flex bison
apt-get install libboost-all-dev
apt-get install libeigen3-dev
apt-get install csh
apt-get install libcairo-dev
apt-get install autotools-dev clang lcov libpcre3-dev python3-dev tcllib zlib1g-dev
apt-get install libgomp1 tcl-tclreadline
apt-get install pip

echo Running pip to install Python dependancies...

pip3 install --system pandas

echo Packages for KLayout

apt-get install ruby-dev
apt-get install libqt5-dev
apt-get install qttools5-dev-tools
apt-get install libqt5svg5*
apt-get install libqt5xml*
apt-get install libqt5multi*
apt-get install qt5des*
apt-get install qtmultimedia5-dev
apt-get install qttools5-*

echo Packages for OpenROAD

apt-get install swig
apt-get install libspdlog-dev
apt-get install liblemon-dev

echo Packages for OpenLane

apt-get install python3-venv
apt-get install autopoint
apt-get install ninja-build

pip3 install --system pyinstaller

