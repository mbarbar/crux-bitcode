#!/bin/sh

# Setup user mapping for unprivileged containers
test -f '/etc/subuid' || touch '/etc/subuid'
/usr/sbin/usermod -v 100000-165535 root

# Setup group mapping for unprivileged containers
test -f '/etc/subgid' || touch '/etc/subgid'
/usr/sbin/usermod -w 100000-165535 root
