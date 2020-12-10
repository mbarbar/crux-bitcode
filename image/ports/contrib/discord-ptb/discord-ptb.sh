#!/bin/bash

prt-get isinst apulse > /dev/null

if [ $? = 0 ]; then
	exec /usr/bin/apulse /opt/discord-ptb/DiscordPTB "$@"
else
	exec /opt/discord-ptb/DiscordPTB "$@"
fi

