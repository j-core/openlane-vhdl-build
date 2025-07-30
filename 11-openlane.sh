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

echo Cloning librelane and patching defaults
git clone https://github.com/librelane/librelane.git

(cd librelane; patch -p1) << 'EOF'
diff --git a/librelane/flows/cli.py b/librelane/flows/cli.py
index ebd0e24..8661ced 100644
--- a/librelane/flows/cli.py
+++ b/librelane/flows/cli.py
@@ -131,11 +131,11 @@ def cloup_flow_opts(
     run_options: bool = True,
     sequential_flow_controls: bool = True,
     sequential_flow_reproducible: bool = False,
-    pdk_options: bool = True,
+    pdk_options: bool = "--manual-pdk",
     log_level: bool = True,
     jobs: bool = True,
     accept_config_files: bool = True,
-    volare_by_default: bool = True,
+    volare_by_default: bool = False,
     volare_pdk_override: Optional[str] = None,
     _enable_debug_flags: bool = False,
     enable_overwrite_flag: bool = False,
EOF

cd ../../bin

echo Create script to make librelane available as a tool
cat >> librelane << 'EOF'
#/bin/bash

PYTHONPATH=$PYTHONPATH:/opt/toolflows/share/librelane python3 -m librelane "$@"
EOF

chmod +x librelane

