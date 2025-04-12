#!/bin/sh

. "$IPKG_INSTROOT/lib/functions.sh"
. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

config_load nikki
config_get enabled "config" "enabled" 0
config_get tcp_mode "proxy" "tcp_mode"
config_get udp_mode "proxy" "udp_mode"
config_get tun_device "mixin" "tun_device"

if [ "$enabled" == 1 ] && [[ "$tcp_mode" == "tun" || "$udp_mode" == "tun" ]]; then
	nft insert rule inet fw4 input iifname "$tun_device" counter accept comment "nikki"
	nft insert rule inet fw4 forward oifname "$tun_device" counter accept comment "nikki"
	nft insert rule inet fw4 forward iifname "$tun_device" counter accept comment "nikki"
fi

exit 0
