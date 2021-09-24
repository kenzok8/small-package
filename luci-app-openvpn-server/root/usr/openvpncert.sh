#!/bin/sh
# 防止重复启动
[ -f /var/lock/openvpncert.lock ] && exit 1
touch /var/lock/openvpncert.lock
rm -rf /tmp/easyrsa3
(
easyrsa init-pki || return 1
echo -en "\n\n\n\n\n\n\n" | easyrsa build-ca nopass || return 1
echo -en "\n\n\n\n\n\n\n" | easyrsa gen-req server nopass || return 1
echo -en "yes" | easyrsa sign server server || return 1
easyrsa gen-dh || return 1
echo -en "\n\n\n\n\n\n\n" | easyrsa gen-req client nopass || return 1
echo -en "yes" | easyrsa sign client client || return 1
cp /tmp/easyrsa3/pki/ca.crt /etc/openvpn/ || return 1
cp /tmp/easyrsa3/pki/issued/server.crt /etc/openvpn/ || return 1
cp /tmp/easyrsa3/pki/private/server.key /etc/openvpn/ || return 1
cp /tmp/easyrsa3/pki/dh.pem /etc/openvpn/ || return 1
cp /tmp/easyrsa3/pki/issued/client.crt /etc/openvpn/ || return 1
cp /tmp/easyrsa3/pki/private/client.key /etc/openvpn/ || return 1
[ -n "$(uci -q get openvpn.myvpn.tls_auth)" ] && (openvpn --genkey --secret /etc/openvpn/ta.key || return 1) || return 0
)
if [ $? -eq 0 ]; then
	echo "OpenVPN Cert renew successfully" 
else
	echo "OpenVPN Cert renew failed"
fi
rm -rf /tmp/easyrsa3
rm -f /var/lock/openvpncert.lock
