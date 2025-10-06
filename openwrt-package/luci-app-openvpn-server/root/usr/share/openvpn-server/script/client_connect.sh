#!/bin/sh

CONFIG="luci-app-openvpn-server"
OVPN_PATH=/var/etc/openvpn-server
LOG_FILE=${OVPN_PATH}/client.log
SESSION_PATH=${OVPN_PATH}/session
TIME="$(date "+%Y-%m-%d %H:%M:%S")"

mkdir -p ${SESSION_PATH}

REMOTE_IP=${trusted_ip}
[ -n "${trusted_ip6}" ] && REMOTE_IP=${trusted_ip6}

cat <<-EOF > ${SESSION_PATH}/${common_name}
	{
	    "common_name": "${common_name}",
	    "time_ascii": "${time_ascii}",
	    "trusted_ip": "${trusted_ip}",
	    "trusted_ip6": "${trusted_ip6}",
	    "trusted_port": "${trusted_port}",
	    "ifconfig_pool_remote_ip": "${ifconfig_pool_remote_ip}",
	    "time_ascii": "${time_ascii}",
	    "remote_ip": "${REMOTE_IP}",
	    "login_time": "${TIME}"
	}
EOF

echo "${TIME}: ${common_name}/${REMOTE_IP} online." >> ${LOG_FILE}

cfgid=$(uci show ${CONFIG} | grep "@users" | grep "\.username='${common_name}'" | cut -d '.' -sf 2)
[ -n "$cfgid" ] && {
	routes=$(uci -q get ${CONFIG}.${cfgid}.routes)
	[ -n "$routes" ] && {
		for route in ${routes}; do
			route add -net ${route} gw ${ifconfig_pool_remote_ip} >/dev/null 2>&1
		done
		#echo "${TIME}: ${common_name}/${REMOTE_IP} add route." >> ${LOG_FILE}
	}
}

#可根据登录的账号自定义脚本，如组网、日志、限速、权限等特殊待遇。
SCRIPT="/usr/share/openvpn-server/script/client_connect/${common_name}"
[ -s "$SCRIPT" ] && {
	[ ! -x "$SCRIPT" ] && chmod 0755 "$SCRIPT"
	"$SCRIPT" "$@"
}
exit 0
