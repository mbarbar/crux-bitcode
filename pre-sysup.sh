#!/bin/sh

# When we update openssl, wget will be in trouble, so grab sources beforehand.
# Other ports too, courtesy of SiFuh's suggestion in IRC.

ports="wget curl exim openssh bindutils"

for port in $ports; do
  cd /usr/ports/core/$port
  echo $port
  pkgmk -do
done

prt-get update openssl

for port in $ports; do
  cd /usr/ports/core/$port
  pkgmk -u
done
