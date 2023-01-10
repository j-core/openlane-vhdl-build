#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/YosysHQ/sby

cd ../build
git clone ../src/sby
cd sby

patch -p1 << EOF
diff --git a/Makefile b/Makefile
index 7a86f6b..f5a7d7e 100644
--- a/Makefile
+++ b/Makefile
@@ -1,6 +1,6 @@

 DESTDIR =
-PREFIX = /usr/local
+PREFIX = /opt/toolflows
 PROGRAM_PREFIX =

 # On Windows, manually setting absolute path to Python binary may be required
EOF

make install

cd ../..

echo Done.
