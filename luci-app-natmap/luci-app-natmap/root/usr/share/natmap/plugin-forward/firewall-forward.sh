#!/bin/bash
# NATMap
outter_ip=$1
outter_port=$2
ip4p=$3
inner_port=$4
protocol=$5

# if [ "$FORWARD_MODE" != firewall ]; then
# 	exit 0
# fi

if [ -z "$FORWARD_TARGET_PORT" ]; then
	exit 0
fi

if [ -z "$FORWARD_TARGET_IP" ]; then
	exit 0
fi

# get forward target port
# final_forward_target_port=$([ "${FORWARD_TARGET_PORT}" == 0 ] ? $outter_port : "${FORWARD_TARGET_PORT}")
final_forward_target_port=$((FORWARD_TARGET_PORT == 0 ? outter_port : FORWARD_TARGET_PORT))

# ipv4 firewall
rule_name_v4=$(echo "${GENERAL_NAT_NAME}_v4" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')

# ipv4 redirect
uci set firewall.$rule_name_v4=redirect
uci set firewall.$rule_name_v4.name="$rule_name_v4"
uci set firewall.$rule_name_v4.proto="$protocol"
uci set firewall.$rule_name_v4.src="$GENERAL_WAN_INTERFACE"
uci set firewall.$rule_name_v4.dest="$FORWOARD_TARGET_INTERFACE"
uci set firewall.$rule_name_v4.target='DNAT'
uci set firewall.$rule_name_v4.src_dport="${inner_port}"
uci set firewall.$rule_name_v4.dest_ip="${FORWARD_TARGET_IP}"
uci set firewall.$rule_name_v4.dest_port="${final_forward_target_port}"

# --------------------------------------------------------------------------------------------
# QB and TR ipv6 forward
# 检测link_enable
if [ "${LINK_ENABLE}" != 1 ]; then
	exit 0
fi

if [ [ "${LINK_MODE}" = transmission ] && [ "${LINK_TR_ALLOW_IPV6}" = 1 ] ] || [ [ "${LINK_MODE}" = qbittorrent ] && ["${LINK_QB_ALLOW_IPV6}" != 1 ] ]; then

	# get rule name
	rule_name_v6=$(echo "${GENERAL_NAT_NAME}_v6_allow" | sed 's/[^a-zA-Z0-9]/_/g' | awk '{print tolower($0)}')

	# echo "rule_name_v6: $rule_name_v6"
	# ipv6 allow
	uci set firewall.$rule_name_v6=rule
	uci set firewall.$rule_name_v6.name="$rule_name_v6"
	uci set firewall.$rule_name_v6.src="$GENERAL_WAN_INTERFACE"
	uci set firewall.$rule_name_v6.dest="$FORWOARD_TARGET_INTERFACE"
	uci set firewall.$rule_name_v6.target='ACCEPT'
	uci set firewall.$rule_name_v6.proto="$protocol"
	uci set firewall.$rule_name_v6.family='ipv6'
	uci set firewall.$rule_name_v6.dest_port="$final_forward_target_port"

	# check if dest_ip is already set with return code
	if uci get firewall.$rule_name_v6.dest_ip >/dev/null 2>&1; then
		uci del firewall.$rule_name_v6.dest_ip
	fi

	# add dest_ip list
	case "${LINK_MODE}" in
	"transmission")
		for ip in $LINK_TR_IPV6_ADDRESS; do
			uci add_list firewall.$rule_name_v6.dest_ip="${ip}"
		done
		;;
	"qbittorrent")
		for ip in $LINK_QB_IPV6_ADDRESS; do
			uci add_list firewall.$rule_name_v6.dest_ip="${ip}"
		done
		;;
	esac
fi

# reload
uci commit firewall
/etc/init.d/firewall reload
