#!/bin/sh

getent group ntp || /usr/sbin/groupadd -g 77 ntp
getent passwd ntp || /usr/sbin/useradd -g ntp -u 77 -d /var/lib/ntp -s /bin/false ntp
/usr/bin/passwd -l ntp
