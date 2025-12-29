#!/bin/sh

. "$IPKG_INSTROOT/etc/momo/scripts/include.sh"

# since v1.0.2

section_placeholder=$(uci -q get momo.placeholder); [ -z "$section_placeholder" ] && uci set momo.placeholder="placeholder"

# since v1.1.0

proxy_bypass_china_mainland_ip=$(uci -q get momo.proxy.bypass_china_mainland_ip)
proxy_bypass_china_mainland_ip6=$(uci -q get momo.proxy.bypass_china_mainland_ip6)
[ -z "$proxy_bypass_china_mainland_ip6" ] && uci set momo.proxy.bypass_china_mainland_ip6=$proxy_bypass_china_mainland_ip

routing_tproxy_fw_mask=$(uci -q get momo.routing.tproxy_fw_mask); [ -z "$routing_tproxy_fw_mask" ] && uci set momo.routing.tproxy_fw_mask=0xFF
routing_tun_fw_mask=$(uci -q get momo.routing.tun_fw_mask); [ -z "$routing_tun_fw_mask" ] && uci set momo.routing.tun_fw_mask=0xFF

procd=$(uci -q get momo.procd); [ -z "$procd" ] && {
	uci set momo.procd=procd
	uci set momo.procd.fast_reload=$(uci -q get momo.config.fast_reload)
	uci del momo.config.fast_reload
}

# commit
uci commit momo

# exit with 0
exit 0
