#!/bin/sh

# This script needs to be run from the directory where you've just build musl cross make

export PREFIX=/opt/toolchains

echo clone musl-cross-make

git clone https://github.com/richfelker/musl-cross-make.git
cd musl-cross-make

echo patch for musl 1.2.4

patch -p1 << 'EOF'
diff --git a/Makefile b/Makefile
index 09f8c2d..5d3d805 100644
--- a/Makefile
+++ b/Makefile
@@ -4,7 +4,7 @@ SOURCES = sources
 CONFIG_SUB_REV = 3d5db9ebe860
 BINUTILS_VER = 2.33.1
 GCC_VER = 9.4.0
-MUSL_VER = 1.2.3
+MUSL_VER = 1.2.4
 GMP_VER = 6.1.2
 MPC_VER = 1.1.0
 MPFR_VER = 4.0.2
diff --git a/hashes/musl-1.2.4.tar.gz.sha1 b/hashes/musl-1.2.4.tar.gz.sha1
new file mode 100644
index 0000000..0f94407
--- /dev/null
+++ b/hashes/musl-1.2.4.tar.gz.sha1
@@ -0,0 +1 @@
+78eb982244b857dbacb2ead25cc0f631ce44204d  musl-1.2.4.tar.gz
EOF

echo config

echo "OUTPUT = $PREFIX" > config.mak
cat presets/j2-fdpic >> config.mak

echo patch for vfork 

mkdir patches/musl-1.2.4 && cat >> patches/musl-1.2.4/0001-nommu.patch << 'EOF'
--- a/src/legacy/daemon.c
+++ b/src/legacy/daemon.c
@@ -17,3 +17,3 @@
 
-	switch(fork()) {
+	switch(vfork()) {
 	case 0: break;
@@ -25,3 +25,3 @@
 
-	switch(fork()) {
+	switch(vfork()) {
 	case 0: break;
--- a/src/misc/forkpty.c
+++ b/src/misc/forkpty.c
@@ -8,2 +8,3 @@
 
+#ifndef __SH_FDPIC__
 int forkpty(int *pm, char *name, const struct termios *tio, const struct winsize *ws)
@@ -57,1 +58,2 @@
 }
+#endif
--- a/src/misc/wordexp.c
+++ b/src/misc/wordexp.c
@@ -25,2 +25,3 @@
 
+#ifndef __SH_FDPIC__
 static int do_wordexp(const char *s, wordexp_t *we, int flags)
@@ -177,2 +178,3 @@
 }
+#endif
 
--- a/src/process/fork.c
+++ b/src/process/fork.c
@@ -7,2 +7,3 @@
 
+#ifndef __SH_FDPIC__
 static void dummy(int x)
@@ -37,1 +38,2 @@
 }
+#endif
--- a/Makefile
+++ b/Makefile
@@ -100,3 +100,3 @@
 	cp $< $@
-	sed -n -e s/__NR_/SYS_/p < $< >> $@
+	sed -e s/__NR_/SYS_/ < $< >> $@
 
--- a/arch/sh/bits/syscall.h.in
+++ b/arch/sh/bits/syscall.h.in
@@ -2,3 +2,5 @@
 #define __NR_exit                   1
+#ifndef __SH_FDPIC__
 #define __NR_fork                   2
+#endif
 #define __NR_read                   3
EOF

echo building sh2-fdpic linux toolchain

make -j8

echo install linux toolchain

make install
cd ..

echo clone target side libraries
git clone https://github.com/sabotage-linux/netbsd-curses.git

echo patching curses for J-Core
cd netbsd-curses
rm infocmp/Makefile \
   libcurses/EXAMPLES/Makefile \
   libcurses/PSD.doc/Makefile \
   nbperf/Makefile \
   tabs/Makefile \
   tic/Makefile \
   tput/Makefile \
   tset/Makefile

patch -p1 << EOF 
diff --git a/GNUmakefile b/GNUmakefile
index d302ce1..4623ffb 100644
--- a/GNUmakefile
+++ b/GNUmakefile
@@ -1,7 +1,9 @@
-HOSTCC ?= \$(CC)
+CROSS = sh2eb-linux-muslfdpic-
+HOSTCC = gcc
+CC = \$(CROSS)gcc
 AWK ?= awk
-AR ?= ar
-RANLIB ?= ranlib
+AR = \$(CROSS)ar
+RANLIB = \$(CROSS)ranlib
 HOST_SH ?= /bin/sh
 LN ?= ln
 INSTALL ?= ./install.sh
@@ -11,7 +13,7 @@ SO_SUFFIX ?= .so
 
 PIC = -fPIC
 
-PREFIX=/usr/local
+PREFIX=/opt/toolchains/sh2eb-linux-muslfdpic
 BINDIR=\$(PREFIX)/bin
 LIBDIR=\$(PREFIX)/lib
 INCDIR=\$(PREFIX)/include
@@ -43,7 +45,7 @@ STATIC_BINS=0
 endif
 
 CFLAGS+=-Werror-implicit-function-declaration
-CPPFLAGS+= -I. -I./libterminfo
+CPPFLAGS+= -I. -I./libterminfo -I./libcurses
 
 TOOL_NBPERF=	nbperf/nbperf
 NBPERF_SRCS=	nbperf/nbperf.c
diff --git a/libterminfo/GNUmakefile b/libterminfo/GNUmakefile
index ce0dc06..80b7992 100644
--- a/libterminfo/GNUmakefile
+++ b/libterminfo/GNUmakefile
@@ -5,8 +5,8 @@ USE_SHLIBDIR=	yes
 LIB=		terminfo
 WARNS?=		5
 
-CPPFLAGS+=	-I.
-CPPFLAGS+=	-I..
+CPPFLAGS+=	-I. -I../libcurses
+CPPFLAGS+=	-I.. -I../libcurses
 
 SRCS=		term.c ti.c setupterm.c curterm.c tparm.c tputs.c
 SRCS+=		compile.c hash.c
EOF

PATH=$PATH:/opt/toolchains/bin make CFLAGS=-Os LDFLAGS=-static all-static
make CFLAGS=-Os LDFLAGS=-static install-headers install-stalibs

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

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/configure --prefix=$PREFIX  --target=sh2-elf --disable-bootstrap --disable-assembly --disable-werror --disable-libmudflap --disable-libsanitizer --disable-gnu-indirect-function --disable-libmpx --disable-libmudflap --disable-libstdcxx-pch --disable-ssp --disable-libssp --enable-languages=c,c++ --with-newlib --without-headers --disable-hosted-libstdcxx

make -j8 all-gcc
make -j8 all-target-libgcc

echo install bare metal compiler
make install-strip-gcc
make install-strip-target-libgcc

cd ..

echo install mercurial
wget https://www.mercurial-scm.org/release/mercurial-6.4.2.tar.gz
tar -zxvf mercurial-6.4.2.tar.gz
cd mercurial-6.4.2

make install

cd ..
