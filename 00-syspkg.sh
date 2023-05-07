#!/bin/sh

#echo Installing packages for bootloader

#apt-get install grub
#grub-install /dev/sda
#update-grub

# Perl and python panic without a utf8 locale
if ! grep -q en_US.utf-8 /etc/locale.gen
then
  apt-get install locales &&
  echo en_US.utf-8 UTF-8 > /etc/locale.gen &&
  locale-gen || exit 1
fi

echo Installing packages for toolchains and toolflows...

apt-get install wget &&
apt-get install vim &&
apt-get install bvi &&
apt-get install build-essential manpages-dev &&
apt-get install llvm-dev &&
apt-get install tcl-dev &&
apt-get install tk-dev &&
apt-get install libboost-dev &&
apt-get install gnat &&
apt-get install git &&
apt-get install libreadline-dev &&
apt-get install libxt-dev &&
apt-get install wxgtk3.0 &&
apt-get install autoconf &&
apt-get install cmake &&
apt-get install libbz2-dev &&
apt-get install libftdi-dev &&
apt-get install libffi-dev &&
apt-get install flex bison &&
apt-get install libboost-all-dev &&
apt-get install libeigen3-dev &&
apt-get install csh &&
apt-get install libcairo-dev &&
apt-get install autotools-dev clang lcov libpcre3-dev python3-dev tcllib zlib1g-dev &&
apt-get install libgomp1 tcl-tclreadline &&
apt-get install pip &&
apt-get install autossh || exit 1

echo Running pip to install Python dependancies...

pip3 install --system pandas &&
apt-get install docutils || exit 1

echo Packages for KLayout

apt-get install ruby-dev &&
#apt-get install libqt5-dev &&
apt-get install qttools5-dev-tools &&
apt-get install libqt5svg5* &&
apt-get install libqt5xml* &&
apt-get install libqt5multi* &&
apt-get install qt5des* &&
apt-get install qtmultimedia5-dev &&
apt-get install qttools5-* || exit 1

echo Packages for OpenROAD

apt-get install swig &&
apt-get install libspdlog-dev &&
apt-get install liblemon-dev || exit 1

echo Packages for OpenLane

apt-get install python3-venv &&
apt-get install autopoint &&
apt-get install ninja-build &&

pip3 install --system pyinstaller || exit 1

echo Packages for DFFRAM

pip3 install --system click pyyaml || exit 1

echo Packages for ngspice

apt-get install libxaw7-dev || exit 1

echo Packages for iverilog
apt-get install gperf || exit 1

echo Packages for j-core Linux development

apt install device-tree-compiler || exit 1

echo Packages for soc_top tools

apt-get install default-jdk || exit 1
echo Do something about installing lein for all users...
