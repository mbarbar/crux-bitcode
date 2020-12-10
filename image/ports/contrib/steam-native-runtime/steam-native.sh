#!/bin/bash
export STEAM_RUNTIME=0
export STEAM_RUNTIME_HEAVY=0
# Workaround for dbus fatal termination related coredumps (SIGABRT)
# https://github.com/ValveSoftware/steam-for-linux/issues/4464
export DBUS_FATAL_WARNINGS=0
# Override some libraries as these are what games linked against.
export LD_LIBRARY_PATH="/usr/lib/steam:/usr/lib32/steam${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
# Steam webview/game browser not working in native runtime (Black screen)
# Since the new Steam Friends UI update, the client webview isn't working correctly with the native-runtime. 
LD_PRELOAD="/usr/lib/libgio-2.0.so.0 /usr/lib/libglib-2.0.so.0"
prt-get isinst apulse-32 > /dev/null

if [ $? = 0 ]; then
	exec /usr/bin/apulse-32 /usr/lib/steam/steam "$@"
else
	exec /usr/lib/steam/steam "$@"
fi

