#!/bin/sh

# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5
env

TR_RPC_URL=$(echo $TR_RPC_URL | sed 's/\/$//')
# update port
trauth="-u $TR_USERNAME:$TR_PASSWORD"
trsid=$(curl --retry 10 -s $trauth $TR_RPC_URL/transmission/rpc | sed 's/.*<code>//g;s/<\/code>.*//g')
curl --retry 10 -X POST \
    -H "${trsid}" $trauth \
    -d '{"method":"session-set","arguments":{"peer-port":'${outter_port}'}}' \
    "$TR_RPC_URL/transmission/rpc"

if [ $TR_ALLOW_IPV6 = 1 ]; then
    rule_name=$(echo "${NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')
    # ipv6 allow
    uci set firewall.$rule_name=rule
    uci set firewall.$rule_name.name='Allow-Transmission-IPv6'
    uci set firewall.$rule_name.src='wan'
    uci set firewall.$rule_name.dest='lan'
    uci set firewall.$rule_name.target='ACCEPT'
    uci set firewall.$rule_name.proto='tcp udp'
    if uci get firewall.$rule_name.dest_ip >/dev/null 2>&1; then
        uci del firewall.$rule_name.dest_ip
    fi

    for ip in $TR_IPV6_ADDRESS; do
        uci add_list firewall.$rule_name.dest_ip="${ip}"
    done
    uci set firewall.$rule_name.family='ipv6'
    uci set firewall.$rule_name.dest_port="${outter_port}"
    # reload
    uci commit firewall
    /etc/init.d/firewall reload
fi