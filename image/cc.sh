#!/bin/sh
# Ensures gclang is run (this script will replace gcc, clang) and that
# user-defined CFLAGS come after the project's.
# In Dockerfile, we set the real gclang at /bin/.
/bin/gclang $@ $CFLAGS
