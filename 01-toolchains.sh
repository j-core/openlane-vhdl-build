#!/bin/sh

# This script needs to be run from the directory where you've just build musl cross make

export PREFIX=/opt/toolchains

echo clone musl-cross-make

git clone https://github.com/richfelker/musl-cross-make.git
cd musl-cross-make

echo config

echo "OUTPUT = $PREFIX" > config.mak
cat presets/j2-fdpic >> config.mak

echo building sh2-fdpic linux toolchain

make -j8

echo install linux toolchain

make install
cd ..

echo building a bare sh2-elf binutils

mkdir bare-binutils
cd bare-binutils

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_binutils/configure --prefix=$PREFIX  --enable-deterministic-archives --target=sh2-elf --disable-separate-code --disable-werror
make -j8

echo install bare metal binutils
make install
cd ..

echo patching gcc for __attribute__ naked functions

(cd musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/gcc/config/sh ; patch -p4 ) << EOF
--- src_gcc/gcc/config/sh/sh.c.cas	2022-06-11 15:59:46.746762896 +0900
+++ src_gcc/gcc/config/sh/sh.c	2022-06-11 16:32:06.714818662 +0900
@@ -210,6 +210,7 @@
 							   tree, int, bool *);
 static tree sh_handle_sp_switch_attribute (tree *, tree, tree, int, bool *);
 static tree sh_handle_trap_exit_attribute (tree *, tree, tree, int, bool *);
+static tree sh_handle_naked_attribute (tree *, tree, tree, int, bool *);
 static tree sh_handle_renesas_attribute (tree *, tree, tree, int, bool *);
 static void sh_print_operand (FILE *, rtx, int);
 static void sh_print_operand_address (FILE *, machine_mode, rtx);
@@ -341,6 +342,8 @@
      sh_handle_sp_switch_attribute, NULL },
   { "trap_exit",         1, 1, true,  false, false, false,
     sh_handle_trap_exit_attribute, NULL },
+  { "naked",             0, 0, true,  false, false, false,
+    sh_handle_naked_attribute, NULL },
   { "renesas",           0, 0, false, true, false, false,
     sh_handle_renesas_attribute, NULL },
   { "trapa_handler",     0, 0, true,  false, false, false,
@@ -7138,6 +7141,8 @@
   tree sp_switch_attr
     = lookup_attribute ("sp_switch", DECL_ATTRIBUTES (current_function_decl));
 
+  if (lookup_attribute ("naked", DECL_ATTRIBUTES (current_function_decl)) != NULL_TREE) return;
+
   current_function_interrupt = sh_cfun_interrupt_handler_p ();
 
   /* We have pretend args if we had an object sent partially in registers
@@ -7238,6 +7243,8 @@
   int save_size = d;
   int frame_size = rounded_frame_size (d);
 
+  if (lookup_attribute ("naked", DECL_ATTRIBUTES (current_function_decl)) != NULL_TREE) return;
+
   if (frame_pointer_needed)
     {
       /* We must avoid scheduling the epilogue with previous basic blocks.
@@ -8416,6 +8423,9 @@
    * trap_exit
 	Use a trapa to exit an interrupt function instead of rte.
 
+   * naked
+	Do not emit a function prolog or epilog.
+
    * nosave_low_regs
 	Don't save r0..r7 in an interrupt handler function.
 	This is useful on SH3* and SH4*, which have a separate set of low
@@ -8606,6 +8616,24 @@
   return NULL_TREE;
 }
 
+/* Handle an "naked" attribute; arguments as in
+   struct attribute_spec.handler.  */
+static tree
+sh_handle_naked_attribute (tree *node, tree name,
+			   tree args ATTRIBUTE_UNUSED,
+		           int flags ATTRIBUTE_UNUSED,
+			   bool *no_add_attrs)
+{
+  if (TREE_CODE (*node) != FUNCTION_DECL)
+    {
+      warning (OPT_Wattributes, "%qE attribute only applies to functions",
+	       name);
+      *no_add_attrs = true;
+    }
+
+  return NULL_TREE;
+}
+
 static tree
 sh_handle_renesas_attribute (tree *node ATTRIBUTE_UNUSED,
 			     tree name ATTRIBUTE_UNUSED,
@@ -8684,6 +8712,14 @@
 	 != NULL_TREE;
 }
 
+/* Returns true if the current function has a "naked" attribute set.  */
+bool
+sh_cfun_naked_p (void)
+{
+  return lookup_attribute ("naked", DECL_ATTRIBUTES (current_function_decl))
+	 != NULL_TREE;
+}
+
 /* Implement TARGET_CHECK_PCH_TARGET_FLAGS.  */
 static const char *
 sh_check_pch_target_flags (int old_flags)
EOF

echo building a bare sh2-elf gcc for C language
mkdir bare-gcc
cd bare-gcc

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/configure --prefix=$PREFIX  --target=sh2-elf --disable-bootstrap --disable-assembly --disable-werror --disable-libmudflap --disable-libsanitizer --disable-gnu-indirect-function --disable-libmpx --disable-libmudflap --disable-libstdcxx-pch --disable-ssp --disable-libssp --enable-languages=c --with-newlib --without-headers
make -j8

echo install bare metal compiler
make install

cd ..
