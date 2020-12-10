#!/bin/sh

# Install remainder of core.
for path in /usr/ports/core/*; do
    port=`basename $path`
    if [ $port = "COPYING" -o $port = "COPYRIGHT" ]; then continue; fi
    prt-get isinst $port || prt-get depinst --install-scripts $port || exit 1
done

# Some programs used in the build system are linked against libreadline/libhistory,
# so there is a problem when some ports are updated. We'll symlink the old version
# to the new one, and just update everything that (currently) relies on readline.
prt-get update readline || exit 1

ln -s /lib/libreadline.so.8.0 /lib/libreadline.so.7
ln -s /lib/libhistory.so.8.0 /lib/libhistory.so.7

# When we update openssl, wget will be in trouble, so grab sources beforehand.
# Other ports too, courtesy of SiFuh's suggestion in IRC.
ports="wget curl exim openssh bindutils"

for port in $ports; do
  cd /usr/ports/core/$port
  echo $port
  pkgmk -do || exit 1
done

prt-get update openssl

for port in $ports; do
  cd /usr/ports/core/$port
  pkgmk -u || exit 1
done

prt-get remove iputils || exit 1
