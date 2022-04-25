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

cd ../../

echo clone OpenLane
echo putting it in $PREFIX/share

cd $PREFIX/share
git clone --recursive https://github.com/The-OpenROAD-Project/OpenLane.git

cd OpenLane

patch -p1 << EOF
diff --git a/dependencies/installer.py b/dependencies/installer.py
index c8f64ee..d5fe268 100644
--- a/dependencies/installer.py
+++ b/dependencies/installer.py
@@ -54,8 +54,8 @@ def sh(*args: Tuple[str], root: Union[bool, str] = False, **kwargs):
             it is retried as root.
     """
     args = list(args)
-    if root and not is_root:
-        args = ["sudo"] + args
+#    if root and not is_root:
+#        args = ["sudo"] + args
     try:
         subprocess.run(
             args,
diff --git a/dependencies/tool_metadata.yml b/dependencies/tool_metadata.yml
index d60b131..a37dbe6 100644
--- a/dependencies/tool_metadata.yml
+++ b/dependencies/tool_metadata.yml
@@ -21,6 +21,7 @@
     make clean
     make -j\$(nproc) \$READLINE_CXXFLAGS
     make install
+  in_install: false
 - name: drcu
   repo: https://github.com/cuhk-eda/dr-cu
   commit: 427b4a4f03bb98d8a78b1712fe9e52cfb83a8347
@@ -41,6 +42,7 @@
     make clean
     make -j\$(nproc)
     make install
+  in_install: false
 - name: netgen
   repo: https://github.com/rtimothyedwards/netgen
   commit: bfb01e032f668c09ff43e889f35d611ef0e4a317
@@ -49,6 +51,7 @@
     make clean
     make -j\$(nproc)
     make install
+  in_install: false
 - name: padring
   repo: https://github.com/donn/padring
   commit: b2a64abcc8561d758c0bcb3945117dcb13bd9dca
@@ -76,6 +79,7 @@
     make PREFIX=\$PREFIX config-gcc
     make PREFIX=\$PREFIX -j\$(nproc)
     make PREFIX=\$PREFIX install
+  in_install: false
 - name: klayout
   repo: https://github.com/KLayout/klayout
   commit: 428d0fe8c941faece4eceebc54170cc04d916c03
diff --git a/flow.tcl b/flow.tcl
index a5e2c89..e2b8c03 100755
--- a/flow.tcl
+++ b/flow.tcl
@@ -12,7 +12,9 @@
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
-set ::env(OPENLANE_ROOT) [file dirname [file normalize [info script]]]
+#set ::env(OPENLANE_ROOT) [file dirname [file normalize [info script]]]
+set ::env(PDK_ROOT) "$PREFIX/share/pdk"
+set ::env(OPENLANE_ROOT) "$PREFIX/share/OpenLane"
 set ::env(SCRIPTS_DIR) "\$::env(OPENLANE_ROOT)/scripts"

 if { [file exists \$::env(OPENLANE_ROOT)/install/env.tcl ] } {
diff --git a/scripts/tcl_commands/synthesis.tcl b/scripts/tcl_commands/synthesis.tcl
index 311f81d..6287fbc 100755
--- a/scripts/tcl_commands/synthesis.tcl
+++ b/scripts/tcl_commands/synthesis.tcl
@@ -51,10 +51,18 @@ proc run_yosys {args} {
         lappend ::env(LIB_SYNTH_COMPLETE_NO_PG) \$lib_path
     }
 
-    try_catch \$::env(SYNTH_BIN) \\
-        -c \$::env(SYNTH_SCRIPT) \\
-        -l [index_file \$::env(synthesis_logs)/synthesis.log] \\
-        |& tee \$::env(TERMINAL_OUTPUT)
+    if { [info exists ::env(SYNTH_BIN_OPTIONS)] } {
+        try_catch \$::env(SYNTH_BIN) \\
+            \$::env(SYNTH_BIN_OPTIONS) \\
+            -c \$::env(SYNTH_SCRIPT) \\
+            -l [index_file \$::env(synthesis_logs)/synthesis.log] \\
+            |& tee \$::env(TERMINAL_OUTPUT)
+    } else {
+        try_catch \$::env(SYNTH_BIN) \\
+            -c \$::env(SYNTH_SCRIPT) \\
+            -l [index_file \$::env(synthesis_logs)/synthesis.log] \\
+            |& tee \$::env(TERMINAL_OUTPUT)
+    }
 
     if { ! [info exists flags_map(-no_set_netlist)] } {
         set_netlist \$::env(SAVE_NETLIST)
diff --git a/scripts/yosys/synth.tcl b/scripts/yosys/synth.tcl
index 3ff9653..2aff3f2 100755
--- a/scripts/yosys/synth.tcl
+++ b/scripts/yosys/synth.tcl
@@ -214,8 +214,23 @@ if { !(\$adder_type in [list "YOSYS" "FA" "RCA" "CSA"]) } {
 }
 
 # Start Synthesis
-for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
-    read_verilog -sv {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+if { [info exists ::env(VERILOG_FILES)] } {
+    for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
+    read_verilog {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+    }
+}
+
+if { [info exists ::env(VHDL_FILES)] } {
+    for { set i 0 } { \$i < [llength \$::env(VHDL_FILES)] } { incr i } {
+    exec -- ghdl -a [lindex \$::env(VHDL_FILES) \$i]
+    }
+}
+
+if { [info exists ::env(VHDL_MODULE_IMPORTS)] } {
+    for { set i 0 } { \$i < [llength \$::env(VHDL_MODULE_IMPORTS)] } { incr i } {
+    exec -- ghdl -e -Wno-binding [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+    ghdl [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+    }
 }
 
 select -module \$vtop
diff --git a/scripts/yosys/synth_top.tcl b/scripts/yosys/synth_top.tcl
index 8ed7ebd..342ced2 100755
--- a/scripts/yosys/synth_top.tcl
+++ b/scripts/yosys/synth_top.tcl
@@ -56,9 +56,23 @@ if { [info exists ::env(VERILOG_FILES_BLACKBOX)] } {
 	}
 }
 
+if { [info exists ::env(VERILOG_FILES)] } {
+	for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
+	read_verilog {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+	}
+}
+
+if { [info exists ::env(VHDL_FILES)] } {
+	for { set i 0 } { \$i < [llength \$::env(VHDL_FILES)] } { incr i } {
+	exec -- ghdl -a [lindex \$::env(VHDL_FILES) \$i]
+	}
+}
 
-for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
-  read_verilog {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+if { [info exists ::env(VHDL_MODULE_IMPORTS)] } {
+	for { set i 0 } { \$i < [llength \$::env(VHDL_MODULE_IMPORTS)] } { incr i } {
+        exec -- ghdl -e -Wno-binding [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+	ghdl [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+	}
 }
 
 select -module \$vtop
EOF

echo patched.

OS=other OPENLANE_ROOT_DIR=$PREFIX/share/OpenLane ./env.py local-install

ln -s /opt/toolflows/share/OpenLane/flow.tcl /opt/toolflows/bin

echo Done.

