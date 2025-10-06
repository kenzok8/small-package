#!/bin/sh

CONFIG="luci-app-openvpn-server"
OVPN_PATH=/var/etc/openvpn-server
LOG_FILE=${OVPN_PATH}/client.log
SESSION_PATH=${OVPN_PATH}/session
TIME="$(date "+%Y-%m-%d %H:%M:%S")"

REMOTE_IP=${trusted_ip}
[ -n "${trusted_ip6}" ] && REMOTE_IP=${trusted_ip6}

rm -f ${SESSION_PATH}/${common_name}

echo "${TIME}: ${common_name}/${REMOTE_IP} offline." >> ${LOG_FILE}

cfgid=$(uci show ${CONFIG} | grep "@users" | grep "\.username='${common_name}'" | cut -d '.' -sf 2)
[ -n "$cfgid" ] && {
	routes=$(uci -q get ${CONFIG}.${cfgid}.routes)
	[ -n "$routes" ] && {
		for route in ${routes}; do
			route del -net ${route} gw ${ifconfig_pool_remote_ip} >/dev/null 2>&1
		done
		#echo "${TIME}: ${common_name}/${REMOTE_IP} del route." >> ${LOG_FILE}
	}
}

#可根据退出的账号自定义脚本，如静态路由表，组网等。
SCRIPT="/usr/share/openvpn-server/script/client_disconnect/${common_name}"
[ -s "$SCRIPT" ] && {
	[ ! -x "$SCRIPT" ] && chmod 0755 "$SCRIPT"
	"$SCRIPT" "$@"
}
exit 0
