#!/bin/sh
[ -n "$1" ] || exit 1
A=$(sed -n 1p $1)
B=$(sed -n 2p $1)
C=/etc/openvpn/server/psw-file
[ -r "$C" ] || exit 1
[ "$B" = "$(awk '!/^;/&&!/^#/&&$1=="'$A'"{print $2;exit}' $C)" ] && exit 0
exit 1
