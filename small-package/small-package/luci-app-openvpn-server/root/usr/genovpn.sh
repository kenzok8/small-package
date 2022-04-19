#!/bin/sh

ddns=`uci get openvpn.myvpn.ddns`
port=`uci get openvpn.myvpn.port`
proto=`uci get openvpn.myvpn.proto`
ciphers=`uci get openvpn.myvpn.data_ciphers`
uci -q get openvpn.myvpn.remote_cert_tls >/dev/null && status1="remote-cert-tls server"
uci -q get openvpn.myvpn.tls_auth >/dev/null && status2="key-direction 1"
uci -q get openvpn.myvpn.auth_user_pass_verify >/dev/null && status3="auth-user-pass"
uci -q get openvpn.myvpn.float >/dev/null && status4="float"
status5=`uci -q get openvpn.myvpn.verify_client_cert`
OVPN=`cat /etc/openvpn/ovpnadd/ovpnadd.conf 2>/dev/null`
RETRY=`uci -q get openvpn.myvpn.retry`

cat > /tmp/my.ovpn  <<EOF
client
dev tun
proto $proto
remote $ddns $port
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
auth-nocache
connect-retry $RETRY
data-ciphers $ciphers
$([ -n "$status1" ] && echo "$status1")
$([ -n "$status2" ] && echo "$status2")
$([ -n "$status3" ] && echo "$status3")
$([ -n "$status4" ] && echo "$status4")
EOF

echo '<ca>' >> /tmp/my.ovpn
cat /etc/openvpn/ca.crt >> /tmp/my.ovpn
echo '</ca>' >> /tmp/my.ovpn
[ -n "$status5" ] || (
echo '<cert>' >> /tmp/my.ovpn
cat /etc/openvpn/client.crt >> /tmp/my.ovpn
echo '</cert>' >> /tmp/my.ovpn
echo '<key>' >> /tmp/my.ovpn
cat /etc/openvpn/client.key >> /tmp/my.ovpn
echo '</key>' >> /tmp/my.ovpn
)
[ -n "$status2" ] && (
echo '<tls-auth>' >> /tmp/my.ovpn
cat /etc/openvpn/ta.key >> /tmp/my.ovpn
echo '</tls-auth>' >> /tmp/my.ovpn
)
[ -n "$OVPN" ] && cat /etc/openvpn/ovpnadd/ovpnadd.conf >> /tmp/my.ovpn
