#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

uci -q batch <<-EOF > /dev/null
	del firewall.momo
	set firewall.momo=include
	set firewall.momo.type=script
	set firewall.momo.path=$FIREWALL_INCLUDE_SH
	set firewall.momo.fw4_compatible=1
	commit firewall
EOF
