#!/bin/sh

# This script needs to be run from the directory where you've just build musl cross make

: ${PREFIX:=/opt/toolchains}
export PREFIX

echo clone musl-cross-make

git clone https://github.com/richfelker/musl-cross-make.git &&
cp patches/* musl-cross-make/patches/gcc-9.4.0 &&
cd musl-cross-make 

echo config &&

echo "OUTPUT = $PREFIX" > config.mak &&
echo "BINUTILS_CONFIG += --with-system-zlib" >> config.mak &&
echo "GCC_CONFIG += --with-system-zlib" >> config.mak &&
echo "CXXFLAGS += -std=c++17" >> config.mak &&
cat presets/j2-fdpic >> config.mak &&

echo patch for specs &&
cat >> patches/gcc-9.4.0/0020-gcc-specs.patch << 'EOF' &&
--- gcc-9.4.0.orig/gcc/gcc.c	2021-06-01 02:53:04.800475820 -0500
+++ gcc-9.4.0/gcc/gcc.c	2023-05-12 22:49:06.476185322 -0500
@@ -2178,7 +2179,7 @@
       /* Is this a special command that starts with '%'? */
              /* Don't allow this for the main specs file, since it would
 	 encourage people to overwrite it.  */
-      if (*p == '%' && !main_p)
+      if (*p == '%')
 	{
 	  p1 = p;
 	  while (*p && *p != '\n')
EOF

echo patch for vfork  &&

cat >> patches/musl-1.2.5/0001-nommu.patch << 'EOF' &&
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
 static void dummy(int x) { }
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

echo building sh2-fdpic linux toolchain &&

make -j12 &&

echo install linux toolchain &&

make install &&
cd .. || exit 1

echo clone target side libraries
git clone https://github.com/sabotage-linux/netbsd-curses.git &&

echo patching curses for J-Core &&
cd netbsd-curses &&
rm infocmp/Makefile \
   libcurses/EXAMPLES/Makefile \
   libcurses/PSD.doc/Makefile \
   nbperf/Makefile \
   tabs/Makefile \
   tic/Makefile \
   tput/Makefile \
   tset/Makefile &&

patch -p1 << EOF &&
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
+PREFIX=$PREFIX/sh2eb-linux-muslfdpic
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

PATH=$PATH:$PREFIX/bin make CFLAGS=-Os LDFLAGS=-static all-static &&
make CFLAGS=-Os LDFLAGS=-static install-headers install-stalibs &&

cd .. || exit 1

echo building a bare sh2-elf binutils

mkdir bare-binutils &&
cd bare-binutils &&

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_binutils/configure --with-system-zlib --prefix=$PREFIX  --enable-deterministic-archives --target=sh2-elf --disable-separate-code --disable-werror &&
make -j12 &&

echo install bare metal binutils &&
make install &&
cd .. || exit 1

echo patching gcc for __attribute__ naked functions

(cd musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/gcc/config/sh ; patch -p4 ) << EOF &&
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

echo building a bare sh2-elf gcc for C language &&
mkdir bare-gcc &&
cd bare-gcc &&

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/configure --with-system-zlib --prefix=$PREFIX  --target=sh2-elf --disable-bootstrap --disable-assembly --disable-werror --disable-libmudflap --disable-libsanitizer --disable-gnu-indirect-function --disable-libmpx --disable-libmudflap --disable-libstdcxx-pch --disable-ssp --disable-libssp --enable-languages=c,c++ --with-newlib --without-headers --disable-hosted-libstdcxx &&

make -j12 all-gcc &&
make -j12 all-target-libgcc &&

echo install bare metal compiler &&
make install-strip-gcc &&
make install-strip-target-libgcc &&
ln -s sh2-elf-gcc "$PREFIX"/bin/sh2-elf-cc &&

cd .. || exit 1

echo building a bare sh2-j1-elf binutils

mkdir nomult-binutils &&
cd nomult-binutils &&

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_binutils/configure --with-system-zlib --prefix=$PREFIX  --enable-deterministic-archives --target=sh2-j1-elf --disable-separate-code --disable-werror &&
make -j12 &&

echo install bare metal binutils &&
make install &&
cd .. || exit 1

echo patching gcc for nomult

(cd musl-cross-make ; patch -p0 ) << 'EOF' &&
diff -urN gcc-9.4.0.orig/gcc/config/sh/sh.md /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/gcc/config/sh/sh.md
--- gcc-9.4.0.orig/gcc/config/sh/sh.md	2021-06-01 07:53:04.636473777 +0000
+++ /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/gcc/config/sh/sh.md	2024-09-12 05:11:58.930801166 +0000
@@ -2445,285 +2445,6 @@
 ;; Multiplication instructions
 ;; -------------------------------------------------------------------------
 
-(define_insn_and_split "mulhisi3"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(mult:SI (sign_extend:SI (match_operand:HI 1 "arith_reg_operand"))
-		 (sign_extend:SI (match_operand:HI 2 "arith_reg_operand"))))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH1 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(set (reg:SI MACL_REG) (mult:SI (sign_extend:SI (match_dup 1))
-				   (sign_extend:SI (match_dup 2))))
-   (set (match_dup 0) (reg:SI MACL_REG))])
-
-(define_insn_and_split "umulhisi3"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(mult:SI (zero_extend:SI (match_operand:HI 1 "arith_reg_operand"))
-		 (zero_extend:SI (match_operand:HI 2 "arith_reg_operand"))))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH1 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(set (reg:SI MACL_REG) (mult:SI (zero_extend:SI (match_dup 1))
-				   (zero_extend:SI (match_dup 2))))
-   (set (match_dup 0) (reg:SI MACL_REG))])
-
-(define_insn "umulhisi3_i"
-  [(set (reg:SI MACL_REG)
-	(mult:SI (zero_extend:SI
-		  (match_operand:HI 0 "arith_reg_operand" "r"))
-		 (zero_extend:SI
-		  (match_operand:HI 1 "arith_reg_operand" "r"))))]
-  "TARGET_SH1"
-  "mulu.w	%1,%0"
-  [(set_attr "type" "smpy")])
-
-(define_insn "mulhisi3_i"
-  [(set (reg:SI MACL_REG)
-	(mult:SI (sign_extend:SI
-		  (match_operand:HI 0 "arith_reg_operand" "r"))
-		 (sign_extend:SI
-		  (match_operand:HI 1 "arith_reg_operand" "r"))))]
-  "TARGET_SH1"
-  "muls.w	%1,%0"
-  [(set_attr "type" "smpy")])
-
-
-;; mulsi3 on the SH2 can be done in one instruction, on the SH1 we generate
-;; a call to a routine which clobbers known registers.
-(define_insn "mulsi3_call"
-  [(set (match_operand:SI 1 "register_operand" "=z")
-	(mult:SI (reg:SI R4_REG) (reg:SI R5_REG)))
-   (clobber (reg:SI MACL_REG))
-   (clobber (reg:SI T_REG))
-   (clobber (reg:SI PR_REG))
-   (clobber (reg:SI R3_REG))
-   (clobber (reg:SI R2_REG))
-   (clobber (reg:SI R1_REG))
-   (use (match_operand:SI 0 "arith_reg_operand" "r"))]
-  "TARGET_SH1"
-  "jsr	@%0%#"
-  [(set_attr "type" "sfunc")
-   (set_attr "needs_delay_slot" "yes")])
-
-(define_insn "mul_r"
-  [(set (match_operand:SI 0 "arith_reg_dest" "=r")
-	(mult:SI (match_operand:SI 1 "arith_reg_operand" "0")
-		 (match_operand:SI 2 "arith_reg_operand" "z")))]
-  "TARGET_SH2A"
-  "mulr	%2,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_insn "mul_l"
-  [(set (reg:SI MACL_REG)
-	(mult:SI (match_operand:SI 0 "arith_reg_operand" "r")
-		 (match_operand:SI 1 "arith_reg_operand" "r")))]
-  "TARGET_SH2"
-  "mul.l	%1,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_insn_and_split "mulsi3_i"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(mult:SI (match_operand:SI 1 "arith_reg_operand")
-		 (match_operand:SI 2 "arith_reg_operand")))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(set (reg:SI MACL_REG) (mult:SI (match_dup 1) (match_dup 2)))
-   (set (match_dup 0) (reg:SI MACL_REG))])
-
-(define_expand "mulsi3"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(mult:SI (match_operand:SI 1 "arith_reg_operand")
-		 (match_operand:SI 2 "arith_reg_operand")))]
-  "TARGET_SH1"
-{
-  if (!TARGET_SH2)
-    {
-      emit_move_insn (gen_rtx_REG (SImode, R4_REG), operands[1]);
-      emit_move_insn (gen_rtx_REG (SImode, R5_REG), operands[2]);
-
-      rtx sym = function_symbol (NULL, "__mulsi3", SFUNC_STATIC).sym;
-
-      emit_insn (gen_mulsi3_call (force_reg (SImode, sym), operands[0]));
-    }
-  else
-    {
-      /* FIXME: For some reason, expanding the mul_l insn and the macl store
-	 insn early gives slightly better code.  In particular it prevents
-	 the decrement-test loop type to be used in some cases which saves
-	 one multiplication in the loop setup code.
-
-         emit_insn (gen_mulsi3_i (operands[0], operands[1], operands[2]));
-      */
-
-      emit_insn (gen_mul_l (operands[1], operands[2]));
-      emit_move_insn (operands[0], gen_rtx_REG (SImode, MACL_REG));
-    }
-  DONE;
-})
-
-(define_insn "mulsidi3_i"
-  [(set (reg:SI MACH_REG)
-	(truncate:SI
-	 (lshiftrt:DI
-	  (mult:DI
-	   (sign_extend:DI (match_operand:SI 0 "arith_reg_operand" "r"))
-	   (sign_extend:DI (match_operand:SI 1 "arith_reg_operand" "r")))
-	  (const_int 32))))
-   (set (reg:SI MACL_REG)
-	(mult:SI (match_dup 0)
-		 (match_dup 1)))]
-  "TARGET_SH2"
-  "dmuls.l	%1,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_expand "mulsidi3"
-  [(set (match_operand:DI 0 "arith_reg_dest")
-	(mult:DI (sign_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-		 (sign_extend:DI (match_operand:SI 2 "arith_reg_operand"))))]
-  "TARGET_SH2"
-{
-  emit_insn (gen_mulsidi3_compact (operands[0], operands[1], operands[2]));
-  DONE;
-})
-
-(define_insn_and_split "mulsidi3_compact"
-  [(set (match_operand:DI 0 "arith_reg_dest")
-	(mult:DI (sign_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-		 (sign_extend:DI (match_operand:SI 2 "arith_reg_operand"))))
-   (clobber (reg:SI MACH_REG))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(const_int 0)]
-{
-  rtx low_dst = gen_lowpart (SImode, operands[0]);
-  rtx high_dst = gen_highpart (SImode, operands[0]);
-
-  emit_insn (gen_mulsidi3_i (operands[1], operands[2]));
-
-  emit_move_insn (low_dst, gen_rtx_REG (SImode, MACL_REG));
-  emit_move_insn (high_dst, gen_rtx_REG (SImode, MACH_REG));
-  /* We need something to tag the possible REG_EQUAL notes on to.  */
-  emit_move_insn (operands[0], operands[0]);
-  DONE;
-})
-
-(define_insn "umulsidi3_i"
-  [(set (reg:SI MACH_REG)
-	(truncate:SI
-	 (lshiftrt:DI
-	  (mult:DI
-	   (zero_extend:DI (match_operand:SI 0 "arith_reg_operand" "r"))
-	   (zero_extend:DI (match_operand:SI 1 "arith_reg_operand" "r")))
-	  (const_int 32))))
-   (set (reg:SI MACL_REG)
-	(mult:SI (match_dup 0)
-		 (match_dup 1)))]
-  "TARGET_SH2"
-  "dmulu.l	%1,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_expand "umulsidi3"
-  [(set (match_operand:DI 0 "arith_reg_dest")
-	(mult:DI (zero_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-		 (zero_extend:DI (match_operand:SI 2 "arith_reg_operand"))))]
-  "TARGET_SH2"
-{
-  emit_insn (gen_umulsidi3_compact (operands[0], operands[1], operands[2]));
-  DONE;
-})
-
-(define_insn_and_split "umulsidi3_compact"
-  [(set (match_operand:DI 0 "arith_reg_dest")
-	(mult:DI (zero_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-		 (zero_extend:DI (match_operand:SI 2 "arith_reg_operand"))))
-   (clobber (reg:SI MACH_REG))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(const_int 0)]
-{
-  rtx low_dst = gen_lowpart (SImode, operands[0]);
-  rtx high_dst = gen_highpart (SImode, operands[0]);
-
-  emit_insn (gen_umulsidi3_i (operands[1], operands[2]));
-
-  emit_move_insn (low_dst, gen_rtx_REG (SImode, MACL_REG));
-  emit_move_insn (high_dst, gen_rtx_REG (SImode, MACH_REG));
-  /* We need something to tag the possible REG_EQUAL notes on to.  */
-  emit_move_insn (operands[0], operands[0]);
-  DONE;
-})
-
-(define_insn "smulsi3_highpart_i"
-  [(set (reg:SI MACH_REG)
-	(truncate:SI
-	 (lshiftrt:DI
-	  (mult:DI
-	   (sign_extend:DI (match_operand:SI 0 "arith_reg_operand" "r"))
-	   (sign_extend:DI (match_operand:SI 1 "arith_reg_operand" "r")))
-	  (const_int 32))))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2"
-  "dmuls.l	%1,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_insn_and_split "smulsi3_highpart"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(truncate:SI
-	  (lshiftrt:DI
-	    (mult:DI
-	      (sign_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-	      (sign_extend:DI (match_operand:SI 2 "arith_reg_operand")))
-	  (const_int 32))))
-   (clobber (reg:SI MACL_REG))
-   (clobber (reg:SI MACH_REG))]
-  "TARGET_SH2 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(const_int 0)]
-{
-  emit_insn (gen_smulsi3_highpart_i (operands[1], operands[2]));
-  emit_move_insn (operands[0], gen_rtx_REG (SImode, MACH_REG));
-})
-
-(define_insn "umulsi3_highpart_i"
-  [(set (reg:SI MACH_REG)
-	(truncate:SI
-	 (lshiftrt:DI
-	  (mult:DI
-	   (zero_extend:DI (match_operand:SI 0 "arith_reg_operand" "r"))
-	   (zero_extend:DI (match_operand:SI 1 "arith_reg_operand" "r")))
-	  (const_int 32))))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2"
-  "dmulu.l	%1,%0"
-  [(set_attr "type" "dmpy")])
-
-(define_insn_and_split "umulsi3_highpart"
-  [(set (match_operand:SI 0 "arith_reg_dest")
-	(truncate:SI
-	  (lshiftrt:DI
-	    (mult:DI
-	      (zero_extend:DI (match_operand:SI 1 "arith_reg_operand"))
-	      (zero_extend:DI (match_operand:SI 2 "arith_reg_operand")))
-	  (const_int 32))))
-   (clobber (reg:SI MACL_REG))]
-  "TARGET_SH2 && can_create_pseudo_p ()"
-  "#"
-  "&& 1"
-  [(const_int 0)]
-{
-  emit_insn (gen_umulsi3_highpart_i (operands[1], operands[2]));
-  emit_move_insn (operands[0], gen_rtx_REG (SImode, MACH_REG));
-})
-
 ;; -------------------------------------------------------------------------
 ;; Logical operations
 ;; -------------------------------------------------------------------------
diff -urN gcc-9.4.0.orig/include/longlong.h /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/include/longlong.h
--- gcc-9.4.0.orig/include/longlong.h	2021-06-01 07:53:06.264494051 +0000
+++ /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/include/longlong.h	2024-09-15 04:37:26.492150251 +0000
@@ -1105,14 +1105,28 @@
 #if defined(__sh__) && W_TYPE_SIZE == 32
 #ifndef __sh1__
 #define umul_ppmm(w1, w0, u, v) \
-  __asm__ (								\
-       "dmulu.l	%2,%3\n\tsts%M1	macl,%1\n\tsts%M0	mach,%0"	\
-	   : "=r<" ((USItype)(w1)),					\
-	     "=r<" ((USItype)(w0))					\
-	   : "r" ((USItype)(u)),					\
-	     "r" ((USItype)(v))						\
-	   : "macl", "mach")
-#define UMUL_TIME 5
+  do { \
+    UWtype __x0, __x1, __x2, __x3; \
+    UHWtype __ul, __vl, __uh, __vh; \
+ \
+    __ul = __ll_lowpart (u); \
+    __uh = __ll_highpart (u); \
+    __vl = __ll_lowpart (v); \
+    __vh = __ll_highpart (v); \
+ \
+    __x0 = __mulsi3 (__ul, __vl); \
+    __x1 = __mulsi3 (__ul, __vh); \
+    __x2 = __mulsi3 (__uh, __vl); \
+    __x3 = __mulsi3 (__uh, __vh); \
+ \
+    __x1 += __ll_highpart (__x0);/* this can't give carry */ \
+    __x1 += __x2; /* but this indeed can */ \
+    if (__x1 < __x2) /* did we get it? */ \
+      __x3 += __ll_B; /* yes, add it in the proper pos.  */ \
+ \
+    (w1) = __x3 + __ll_highpart (__x1); \
+    (w0) = __ll_lowpart (__x1) * __ll_B + __ll_lowpart (__x0); \
+  } while (0)
 #endif
 
 /* This is the same algorithm as __udiv_qrnnd_c.  */
diff -urN gcc-9.4.0.orig/libgcc/config/sh/lib1funcs.S /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/libgcc/config/sh/lib1funcs.S
--- gcc-9.4.0.orig/libgcc/config/sh/lib1funcs.S	2021-06-01 07:53:06.376495444 +0000
+++ /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/libgcc/config/sh/lib1funcs.S	2024-09-15 02:56:48.651403511 +0000
@@ -964,40 +964,26 @@
 
 #ifdef L_mulsi3
 
-
 	.global	GLOBAL(mulsi3)
 	HIDDEN_FUNC(GLOBAL(mulsi3))
 
-! r4 =       aabb
-! r5 =       ccdd
-! r0 = aabb*ccdd  via partial products
-!
-! if aa == 0 and cc = 0
-! r0 = bb*dd
-!
-! else
-! aa = bb*dd + (aa*dd*65536) + (cc*bb*65536)
-!
-
 GLOBAL(mulsi3):
+ 	.weak  	GLOBAL(muldi3)
-	mulu.w  r4,r5		! multiply the lsws  macl=bb*dd
-	mov     r5,r3		! r3 = ccdd
-	swap.w  r4,r2		! r2 = bbaa
-	xtrct   r2,r3		! r3 = aacc
-	tst  	r3,r3		! msws zero ?
-	bf      hiset
-	rts			! yes - then we have the answer
-	sts     macl,r0
-
-hiset:	sts	macl,r0		! r0 = bb*dd
-	mulu.w	r2,r5		! brewing macl = aa*dd
-	sts	macl,r1
-	mulu.w	r3,r4		! brewing macl = cc*bb
-	sts	macl,r2
-	add	r1,r2
-	shll16	r2
-	rts
-	add	r2,r0
+	mov	r4,r0
+	mov	#0,r1
+.L2:
+	tst	r0,r0
+	bf	.L4
+	rts	
+	mov	r1,r0
+.L4:
+	tst	#1,r0
+	bt	.L3
+	add	r5,r1
+.L3:
+	shlr	r0
+	bra	.L2
+	add	r5,r5
 
 	ENDFUNC(GLOBAL(mulsi3))
 #endif
diff -urN gcc-9.4.0.orig/libgcc/libgcc2.c /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/libgcc/libgcc2.c
--- gcc-9.4.0.orig/libgcc/libgcc2.c	2021-06-01 07:53:06.384495544 +0000
+++ /home/jeff/work/j1-tools/musl-cross-make/gcc-9.4.0.orig/libgcc/libgcc2.c	2024-09-15 03:46:23.846359130 +0000
@@ -545,16 +545,17 @@
 
 #ifdef L_muldi3
 DWtype
-__muldi3 (DWtype u, DWtype v)
+__muldi3 (DWtype a, DWtype b)
 {
-  const DWunion uu = {.ll = u};
-  const DWunion vv = {.ll = v};
-  DWunion w = {.ll = __umulsidi3 (uu.s.low, vv.s.low)};
+  DWtype out = 0, bb = b;
 
-  w.s.high += ((UWtype) uu.s.low * (UWtype) vv.s.high
-	       + (UWtype) uu.s.high * (UWtype) vv.s.low);
+  while (a) {
+    if (a&1) out += bb;
+    bb <<= 1;
+    a >>= 1;
+  }
 
-  return w.ll;
+  return out;
 }
 #endif
 
EOF

echo building a nomult sh2-elf gcc for C language &&
mkdir nomult-gcc &&
cd nomult-gcc &&

../musl-cross-make/build/local/sh2eb-linux-muslfdpic/src_gcc/configure --with-system-zlib --prefix=$PREFIX  --target=sh2-j1-elf --disable-bootstrap --disable-assembly --disable-werror --disable-libmudflap --disable-libsanitizer --disable-gnu-indirect-function --disable-libmpx --disable-libmudflap --disable-libstdcxx-pch --disable-ssp --disable-libssp --enable-languages=c,c++ --with-newlib --without-headers --disable-hosted-libstdcxx &&

make -j12 all-gcc &&
make -j12 all-target-libgcc &&

echo install bare metal compiler &&
make install-strip-gcc &&
make install-strip-target-libgcc &&
ln -s sh2-j1-elf-gcc "$PREFIX"/bin/sh2-j1-elf-cc &&

cd .. || exit 1

PATH=$PATH:/opt/toolchains/bin

echo Clone minimal-lib

git clone http://10.0.0.2:3000/J-Core/minimal-lib.git

cd minimal-lib
make clean; CROSS_COMPILE=sh2-elf- make

rm -f /opt/toolchains/lib/gcc/sh2-elf/*/*.o
cp -vp *.[oa] /opt/toolchains/sh2-elf/lib
cp -rvp include /opt/toolchains/sh2-elf

make clean; CROSS_COMPILE=sh2-j1-elf- make

rm -f /opt/toolchains/lib/gcc/sh2-j1-elf/*/*.o
cp -vp *.[oa] /opt/toolchains/sh2-j1-elf/lib
cp -rvp include /opt/toolchains/sh2-j1-elf
