#!/bin/sh

#
# (c) 2024 Cezary Jackiewicz <cezary@eko.one.pl>
#

getdevicepath() {
	devname="$(basename $1)"
	case "$devname" in
	'wwan'*'at'*)
		devpath="$(readlink -f /sys/class/wwan/$devname/device)"
		echo ${devpath%/*/*/*}
		;;
	'ttyACM'*)
		devpath="$(readlink -f /sys/class/tty/$devname/device)"
		echo ${devpath%/*}
		;;
	'tty'*)
		devpath="$(readlink -f /sys/class/tty/$devname/device)"
		echo ${devpath%/*/*}
		;;
	*)
		devpath="$(readlink -f /sys/class/usbmisc/$devname/device)"
		echo ${devpath%/*}
		;;
	esac
}

CONFIGSEC=$1
if [ -n "$CONFIGSEC" ]; then
	SEC=$(uci -q get 3ginfo.${CONFIGSEC}.network)
	if [ -n "$SEC" ]; then
		echo "$SEC"
		exit 0
	fi
fi

DEVICE=$(uci -q get 3ginfo.${CONFIGSEC}.device)
if [ -z "$DEVICE" ]; then
	echo ""
	exit 0
fi

DEVPATH=$(getdevicepath "$DEVICE")
DEVICES=$(uci show network | awk '/network\..*\.device/')
for T in $DEVICES; do
	T1=$(echo "$T" | cut -f2 -d= | xargs)
	if [ -e "$T1" ]; then
		if [ "$DEVPATH" = "$(getdevicepath "$T1")" ]; then
			T2=$(echo "$T" | cut -f2 -d.)
			uci set 3ginfo.${CONFIGSEC}.network="$T2"
			uci commit 3ginfo
			echo "$T2"
			exit 0
		fi
	fi
done

echo ""
exit 0
