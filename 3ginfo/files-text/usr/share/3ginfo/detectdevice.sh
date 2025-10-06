#!/bin/sh

#
# (c) 2023-2024 Cezary Jackiewicz <cezary@eko.one.pl>
#

# find any device
DEVICES=$(find /dev -name "ttyUSB*" -o -name "ttyACM*" -o -name "wwan*at*" | sort -r)
for DEVICE in $DEVICES; do
	gcom -d $DEVICE -s /usr/share/3ginfo/check.gcom >/dev/null 2>&1
	if [ $? = 0 ]; then
		uci set 3ginfo.@3ginfo[0].device="$DEVICE"
		uci commit 3ginfo
		echo "$DEVICE"
		exit 0
	fi
done

echo ""
exit 0
