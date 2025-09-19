#!/bin/sh
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

if [ ! -z $FORWARD_USE_NATMAP ] && [ $FORWARD_USE_NATMAP = '1' ]; then
	exit 0
fi

if [ -z "$FORWARD_PORT" ]; then
	exit 0
fi

if [ -z "$FORWARD_TARGET" ]; then
	exit 0
fi

rule_name=$(echo "${NAT_NAME}_v4" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
final_forward_port=$FORWARD_PORT
if [ $final_forward_port = 0 ]; then
	final_forward_port=$outter_port
fi
# ipv4 redirect
uci set firewall.$rule_name=redirect
uci set firewall.$rule_name.name="$NAT_NAME"
uci set firewall.$rule_name.proto=$protocol
uci set firewall.$rule_name.src='wan'
uci set firewall.$rule_name.dest='lan'
uci set firewall.$rule_name.target='DNAT'
uci set firewall.$rule_name.src_dport="${inner_port}"
uci set firewall.$rule_name.dest_ip="${FORWARD_TARGET}"
uci set firewall.$rule_name.dest_port="${final_forward_port}"
# reload
uci commit firewall
/etc/init.d/firewall reload