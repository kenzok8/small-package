#!/bin/sh

DIR=$(cd "$(dirname "$0")";pwd)
LOCK_FILE=/var/lock/ca_renew.lock

lock() {
	if [ -s ${LOCK_FILE} ]; then
		SPID=$(cat ${LOCK_FILE})
		if [ -e /proc/${SPID}/status ]; then
			exit 1
		fi
		cat /dev/null > ${LOCK_FILE}
	fi
	echo $$ > ${LOCK_FILE}
}

unlock() {
	rm -rf ${LOCK_FILE}
}

lock
cd /tmp
echo yes | easyrsa init-pki
echo CA | easyrsa build-ca nopass
easyrsa gen-dh
echo yes | easyrsa build-server-full server nopass
cp -f /tmp/pki/dh.pem /usr/share/openvpn-server/dh.pem
cp -f /tmp/pki/ca.crt /usr/share/openvpn-server/ca.crt
cp -f /tmp/pki/issued/server.crt /usr/share/openvpn-server/server.crt
cp -f /tmp/pki/private/server.key /usr/share/openvpn-server/server.key
rm -rf /tmp/pki
cd ${DIR}
/etc/init.d/luci-app-openvpn-server restart
unlock
