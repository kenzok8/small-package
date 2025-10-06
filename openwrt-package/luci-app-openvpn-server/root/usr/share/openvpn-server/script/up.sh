#!/bin/sh

uci -q batch <<-EOF >/dev/null
	delete network.ovpn_server
	set network.ovpn_server=interface
	set network.ovpn_server.ifname="${dev}"
	set network.ovpn_server.device="${dev}"
	set network.ovpn_server.proto="static"
	set network.ovpn_server.ipaddr="${ifconfig_local}"
	set network.ovpn_server.netmask="${ifconfig_netmask}"
	commit network
	
	set firewall.ovpn_server.network="ovpn_server"
	commit firewall
EOF

ifdown ovpn_server >/dev/null 2>&1
ifup ovpn_server >/dev/null 2>&1
