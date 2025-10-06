#!/bin/sh

uci -q batch <<-EOF >/dev/null
	delete network.ovpn_server
	commit network
EOF

ifup ovpn_server >/dev/null 2>&1
ifdown ovpn_server >/dev/null 2>&1
