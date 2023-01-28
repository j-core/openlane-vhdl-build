#!/bin/sh

export PREFIX=/opt/toolflows

cd src
git clone https://github.com/YosysHQ/mcy

cd ../build
git clone ../src/mcy
cd mcy

patch -p1 << EOF
diff --git a/Makefile b/Makefile
index 55ca806..315506c 100644
--- a/Makefile
+++ b/Makefile
@@ -1,5 +1,5 @@
 DESTDIR =
-PREFIX = /usr/local
+PREFIX = /opt/toolflows

 build:
        cd gui && cmake -DCMAKE_INSTALL_PREFIX=\$(PREFIX)
EOF

make
make install

cd ../..

echo Done.
