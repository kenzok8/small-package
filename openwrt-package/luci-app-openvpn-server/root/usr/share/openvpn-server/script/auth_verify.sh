#!/bin/sh

CONFIG="luci-app-openvpn-server"
OVPN_PATH=/var/etc/openvpn-server
LOG_FILE=${OVPN_PATH}/client.log
AUTH_FILE=${OVPN_PATH}/auth
TIME="$(date "+%Y-%m-%d %H:%M:%S")"

IP=${untrusted_ip}

CORRECT_PASSWORD=$(awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${AUTH_FILE})
if [ "${CORRECT_PASSWORD}" = "" ]; then 
	echo "${TIME}: ${username}/${IP} Fail authentication. input password=\"${password}\"." >> ${LOG_FILE}
	exit 1
fi

if [ "${password}" = "${CORRECT_PASSWORD}" ]; then 
	echo "${TIME}: ${username}/${IP} Successful authentication." >> ${LOG_FILE}
	exit 0
fi

echo "${TIME}: ${username}/${IP} Fail authentication. input password=\"${password}\"." >> ${LOG_FILE}
exit 1
