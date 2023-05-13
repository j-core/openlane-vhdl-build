#!/bin/sh

#echo Installing packages for bootloader

#apt-get install -y grub
#grub-install /dev/sda
#update-grub

# Perl and python panic without a utf8 locale
if ! grep -q en_US.utf-8 /etc/locale.gen
then
  apt-get install -y locales &&
  echo en_US.utf-8 UTF-8 > /etc/locale.gen &&
  locale-gen || exit 1
fi

echo Installing packages for toolchains and toolflows...

apt-get install -y wget &&
apt-get install -y vim &&
apt-get install -y bvi &&
apt-get install -y build-essential manpages-dev &&
apt-get install -y llvm-dev &&
apt-get install -y tcl-dev &&
apt-get install -y tk-dev &&
apt-get install -y libboost-dev &&
apt-get install -y gnat &&
apt-get install -y git &&
apt-get install -y libreadline-dev &&
apt-get install -y libxt-dev &&
apt-get install -y wxgtk3.0 &&
apt-get install -y autoconf &&
apt-get install -y cmake &&
apt-get install -y libbz2-dev &&
apt-get install -y libftdi-dev &&
apt-get install -y libffi-dev &&
apt-get install -y flex bison &&
apt-get install -y libboost-all-dev &&
apt-get install -y libeigen3-dev &&
apt-get install -y csh &&
apt-get install -y libcairo-dev &&
apt-get install -y autotools-dev clang lcov libpcre3-dev python3-dev tcllib zlib1g-dev &&
apt-get install -y libgomp1 tcl-tclreadline &&
apt-get install -y pip &&
apt-get install -y autossh || exit 1

echo Running pip to install Python dependancies...

pip3 install --system pandas &&
apt-get install -y docutils || exit 1

echo Packages for KLayout

apt-get install -y ruby-dev &&
#apt-get install -y libqt5-dev &&
apt-get install -y qttools5-dev-tools &&
apt-get install -y libqt5svg5* &&
apt-get install -y libqt5xml* &&
apt-get install -y libqt5multi* &&
apt-get install -y qt5des* &&
apt-get install -y qtmultimedia5-dev &&
apt-get install -y qttools5-* || exit 1

echo Packages for OpenROAD

apt-get install -y swig &&
apt-get install -y libspdlog-dev &&
apt-get install -y liblemon-dev || exit 1

echo Packages for OpenLane

apt-get install -y python3-venv &&
apt-get install -y autopoint &&
apt-get install -y ninja-build &&

pip3 install --system pyinstaller || exit 1

echo Packages for DFFRAM

pip3 install --system click pyyaml || exit 1

echo Packages for ngspice

apt-get install -y libxaw7-dev || exit 1

echo Packages for iverilog
apt-get install -y gperf || exit 1

echo Packages for j-core Linux development

apt-get install -y device-tree-compiler || exit 1

echo Packages for soc_top tools

apt-get install -y default-jdk || exit 1
echo Do something about installing lein for all users...
