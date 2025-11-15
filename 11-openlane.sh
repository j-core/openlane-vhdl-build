#!/bin/sh

export PREFIX=/opt/toolflows

echo clone sources
cd src

git clone https://github.com/d-m-bailey/cvc
git clone https://github.com/rtimothyedwards/netgen

cd ../build

git clone ../src/cvc
cd cvc

patch -p1 << EOF
diff --git a/src_py/Makefile.am b/src_py/Makefile.am
--- a/src_py/Makefile.am
+++ b/src_py/Makefile.am
@@ -12,7 +12,7 @@
 all : check_cvc
 
 check_cvc : \$(checkcvc_sources) check_cvc.spec
-	pyinstaller -F check_cvc.spec --clean
+	pyinstaller check_cvc.spec --clean
 	cp dist/check_cvc .
 
 install : check_cvc
EOF

autoreconf -i
./configure --disable-nls --prefix=$PREFIX

make -j8
make install

cd ..

git clone ../src/netgen

cd netgen
./configure --prefix=$PREFIX

make -j8
make install

cd ..

git clone --recursive https://github.com/efabless/ioplace_parser.git

cd ioplace_parser
make
pip3 install --break-system-packages .

cd ..

git clone --recursive https://github.com/efabless/libparse-python.git

cd libparse-python
make
pip3 install --break-system-packages .

cd ..

git clone --recursive https://github.com/perlpunk/pyyaml-core.git

cd pyyaml-core 
make
pip3 install --break-system-packages .

cd /opt/toolflows/share

echo Cloning librelane
git clone https://github.com/librelane/librelane.git
echo Cloning librelane-summary
git clone https://github.com/mattvenn/librelane_summary.git

cd ../../bin

echo Create script to make librelane available as a tool
cat >> librelane << 'EOF'
#/bin/bash

PYTHONPATH=$PYTHONPATH:/opt/toolflows/share/librelane:/opt/toolflows/share/klayout/pymod \
LD_LIBRARY_PATH=/opt/toolflows/lib \
python3 -m librelane --manual-pdk --pdk-root=/opt/toolflows/share/pdk "$@"
EOF

chmod +x librelane

echo Create script to make librelane-summary available as a tool
cat >> librelane-summary << 'EOF'
#!/bin/bash

PDK_ROOT=/opt/toolflows/share/pdk \
PYTHONPATH=$PYTHONPATH:/opt/toolflows/share/librelane:/opt/toolflows/share/klayout/pymod \
/opt/toolflows/share/librelane_summary/summary.py "$@"
EOF

chmod +x librelane-summary

