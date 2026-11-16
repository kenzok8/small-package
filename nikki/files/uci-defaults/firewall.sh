#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

uci -q batch <<-EOF > /dev/null
	del firewall.nikki
	set firewall.nikki=include
	set firewall.nikki.type=script
	set firewall.nikki.path=$FIREWALL_INCLUDE_SH
	set firewall.nikki.fw4_compatible=1
	commit firewall
EOF
