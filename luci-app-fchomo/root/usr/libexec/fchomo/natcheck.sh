#!/bin/sh
#
# Depends: coreutils-timeout
#
# Author: muink
# Ref: https://github.com/muink/luci-app-natmapt/blob/master/root/usr/libexec/natmap/natcheck.sh
#
# Args: <stun server:port> <udp/tcp> <localport>
[ "$#" -ge 3 ] || exit 1
stun="$1" && shift
l4proto="$1" && shift
port="$1" && shift

echo "$stun" | grep -qE "^[A-Za-z0-9.-]+:[0-9]+$" || exit 1
echo "$l4proto" | grep -qE "^(udp|tcp)$" || exit 1
echo "$port" | grep -qE "^[0-9]*$" || exit 1

PROG="$(command -v stunclient)"

result="$(timeout 30 $PROG --protocol $l4proto --mode full ${port:+--localport $port} ${stun%:*} ${stun#*:} 2>/dev/null)"

render() {
echo "$1" | sed -E "\
	s,\b((S|s)uccess)\b,<font color=\"green\">\1</font>,g;\
	s,\b((F|f)ail)\b,<font color=\"#ff331f\">\1</font>,g;\
	s|(Nat behavior:\s*)\b(Unknown Behavior)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Direct Mapping)\b|\1<font color=\"#1e96fc\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Endpoint Independent Mapping)\b|\1<font color=\"#7cfc00\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Address Dependent Mapping)\b|\1<font color=\"#ffc100\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Address and Port Dependent Mapping)\b|\1<font color=\"#ff8200\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Unknown NAT Behavior)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Unknown Filtering)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Direct Mapping (Filtering))\b|\1<font color=\"#1e96fc\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Endpoint Independent Filtering)\b|\1<font color=\"#7cfc00\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Address Dependent Filtering)\b|\1<font color=\"#ffc100\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Address and Port Dependent Filtering)\b|\1<font color=\"#ff8200\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Unknown NAT Filtering)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(:\s*)(.*)$|\1<b>\2</b><br>|g"
}

cat <<- EOF
$(echo ${l4proto} | tr 'a-z' 'A-Z') TEST:<br>
$(render "${result:-<font color=\"red\">Test timeout</font>}")
EOF
