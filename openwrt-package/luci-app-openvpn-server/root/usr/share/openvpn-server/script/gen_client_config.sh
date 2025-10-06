#!/bin/sh

CONFIG="luci-app-openvpn-server"

port=$(uci -q get ${CONFIG}.server.port || echo "1194")
proto=$(uci -q get ${CONFIG}.server.proto || echo "udp")
ddns=$(uci -q get ${CONFIG}.server.ddns || echo "example.com")

cat <<-EOF > /tmp/openvpn.ovpn
	client
	dev tun
	proto ${proto}
	remote ${ddns} ${port}
	resolv-retry infinite
	nobind
	persist-key
	persist-tun
	auth-user-pass
	comp-lzo
	verb 3
	<ca>
	$(cat /usr/share/openvpn-server/ca.crt)
	</ca>
EOF
