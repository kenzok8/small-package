#!/bin/sh

. "$IPKG_INSTROOT/lib/functions.sh"
. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

config_load momo
config_get_bool enabled "config" "enabled" 0
config_get_bool core_only "config" "core_only" 0
config_get_bool proxy_enabled "proxy" "enabled" 0 
config_get tcp_mode "proxy" "tcp_mode"
config_get udp_mode "proxy" "udp_mode"
config_get tun_inbound_tag "core" "tun_inbound_tag"

if [ "$enabled" = 1 ] && [ "$core_only" = 0 ] && [ "$proxy_enabled" = 1 ]; then
	if [ "$tcp_mode" = "tun" ] || [ "$udp_mode" = "tun" ]; then
		tun_device=$(jsonfilter -q -i "$RUN_PROFILE_PATH" -e "@['inbounds'][*]" | jsonfilter -q -a -e "@[@['tag']='$tun_inbound_tag']" | jsonfilter -q -a -e "@[@['type']='tun']" | jsonfilter -q -e "@['interface_name']")
		nft insert rule inet fw4 input iifname "$tun_device" counter accept comment "momo"
		nft insert rule inet fw4 forward oifname "$tun_device" counter accept comment "momo"
		nft insert rule inet fw4 forward iifname "$tun_device" counter accept comment "momo"
	fi
fi

exit 0
