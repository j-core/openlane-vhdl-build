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

# For some reason openlane needs to build out of the install directory.
echo clone OpenLane
echo putting it in $PREFIX/share

cd $PREFIX/share
git clone --recursive https://github.com/The-OpenROAD-Project/OpenLane.git

cd OpenLane

# Tell openthingy not to build a zillion other things internally
# klayout|openroad_app|git|open_pdks already yanked
sed -i -E -e '/^[-][ \t]*name:[ \t]*(cvc_rv|magic|netgen|yosys)[ \t]*$/a\' \
          -e '  in_install: false' dependencies/tool_metadata.yml

# We're running as root but it still tries to sudo?
patch -p1 << EOF
diff --git a/dependencies/installer.py b/dependencies/installer.py
index b474097..e5dd669 100644
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
diff --git a/flow.tcl b/flow.tcl
index a011303..b2cf81a 100755
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
index 794178a..21c8fc0 100755
--- a/scripts/tcl_commands/synthesis.tcl
+++ b/scripts/tcl_commands/synthesis.tcl
@@ -62,10 +62,17 @@ proc run_yosys {args} {
     }
 
     set ::env(SAVE_NETLIST) \$arg_values(-output)
-    try_catch \$::env(SYNTH_BIN) \\
-        -c \$::env(SYNTH_SCRIPT) \\
-        -l \$arg_values(-log)\\
-        |& tee \$::env(TERMINAL_OUTPUT)
+    if { [info exists ::env(SYNTH_BIN_OPTIONS)] } {
+       try_catch \$::env(SYNTH_BIN) \$::env(SYNTH_BIN_OPTIONS) \\
+           -c \$::env(SYNTH_SCRIPT) \\
+           -l \$arg_values(-log)\\
+           |& tee \$::env(TERMINAL_OUTPUT)
+    } else {
+       try_catch \$::env(SYNTH_BIN) \\
+           -c \$::env(SYNTH_SCRIPT) \\
+           -l \$arg_values(-log)\\
+           |& tee \$::env(TERMINAL_OUTPUT)
+    }

     if { ! [info exists flags_map(-no_set_netlist)] } {
         set_netlist -lec \$::env(SAVE_NETLIST)
diff --git a/scripts/yosys/synth.tcl b/scripts/yosys/synth.tcl
index b72f3d0..eaa46d9 100755
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
 
 if { [info exists ::env(SYNTH_PARAMETERS) ] } {
diff --git a/scripts/yosys/elaborate.tcl b/scripts/yosys/elaborate.tcl
index bc294c5..902743d 100755
--- a/scripts/yosys/elaborate.tcl
+++ b/scripts/yosys/elaborate.tcl
@@ -56,9 +56,23 @@ if { [info exists ::env(VERILOG_FILES_BLACKBOX)] } {
 	}
 }
 
+if { [info exists ::env(VERILOG_FILES)] } {
+	for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
+		read_verilog {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+	}
+}
+
+if { [info exists ::env(VHDL_FILES)] } {
+	for { set i 0 } { \$i < [llength \$::env(VHDL_FILES)] } { incr i } {
+		exec -- ghdl -a [lindex \$::env(VHDL_FILES) \$i]
+	}
+}
 
-for { set i 0 } { \$i < [llength \$::env(VERILOG_FILES)] } { incr i } {
-	read_verilog {*}\$vIdirsArgs [lindex \$::env(VERILOG_FILES) \$i]
+if { [info exists ::env(VHDL_MODULE_IMPORTS)] } {
+	for { set i 0 } { \$i < [llength \$::env(VHDL_MODULE_IMPORTS)] } { incr i } {
+		exec -- ghdl -e -Wno-binding [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+		ghdl [lindex \$::env(VHDL_MODULE_IMPORTS) \$i]
+	}
 }
 
 if { [info exists ::env(SYNTH_PARAMETERS) ] } {
EOF

echo patched.

OS=other OPENLANE_ROOT_DIR=$PREFIX/share/OpenLane ./env.py local-install

ln -s /opt/toolflows/share/OpenLane/flow.tcl /opt/toolflows/bin

echo Done.

