#!/bin/sh

# env
# IP_PROTO=dhcp|static
# IP_ADDRESS=ipv4/prefixlen
# IP_GATEWAY=ipv4
# IP_DNS="dns1 dns2 ..."
# DHCP_SERVER=on|off

[ -s /rom/etc/openwrt_release ] || {
	echo "/rom is not a openwrt rootfs!" >&2
	exit 1
}

[ -e /rom/.dockerenv ] && {
	echo "/rom is already a docker container rootfs!" >&2
	exit 1
}

CONSOLE=`readlink /proc/$$/fd/2`

if echo "$CONSOLE" | grep -q '^/dev/'; then
	[ -e /dev/kmsg ] || ln -s "$CONSOLE" /dev/kmsg
	[ -e /dev/console ] || ln -s "$CONSOLE" /dev/console
else
	[ -e /dev/kmsg ] || ln -s /proc/self/fd/2 /dev/kmsg
	[ -e /dev/console ] || ln -s /dev/null /dev/console
fi


mount --make-private /
mount --make-private /rom
mount --make-private /overlay

if unshare -m --propagation unchanged true 2>/dev/null; then
	exec unshare -m --propagation unchanged /shadowrt/s1-unshared.sh "$CONSOLE"
elif unshare -m --propagation shared true 2>/dev/null; then
	exec unshare -m --propagation shared /shadowrt/s1-unshared.sh "$CONSOLE"
else
	echo "unshare does not support propagation flag, fallback to default" >&2
	exec unshare -m /shadowrt/s1-unshared.sh "$CONSOLE"
fi
