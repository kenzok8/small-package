#!/bin/sh

#
# (c) 2023 Cezary Jackiewicz <cezary@eko.one.pl>
#
# (c) 2023 modified by Rafał Wabik - IceG - From eko.one.pl forum
#


#
# from config modemdefine
#

idx=$1
test -n "$idx" || idx=0

# from config
DEVICE=$(uci -q get 3ginfo.@3ginfo[$idx].device)
if [ -n "$DEVICE" ]; then
	echo $DEVICE
	exit 0
fi

exit 0
