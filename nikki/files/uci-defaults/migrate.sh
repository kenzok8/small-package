#!/bin/sh

. "$IPKG_INSTROOT/etc/nikki/scripts/include.sh"

# since v1.18.0

mixin_rule=$(uci -q get nikki.mixin.rule); [ -z "$mixin_rule" ] && uci set nikki.mixin.rule=0

mixin_rule_provider=$(uci -q get nikki.mixin.rule_provider); [ -z "$mixin_rule_provider" ] && uci set nikki.mixin.rule_provider=0

# since v1.19.0

mixin_ui_path=$(uci -q get nikki.mixin.ui_path); [ -z "$mixin_ui_path" ] && uci set nikki.mixin.ui_path=ui

uci show nikki | grep -E 'nikki.@rule\[[[:digit:]]+\].match=' | sed 's/nikki.@rule\[\([[:digit:]]\+\)\].match=.*/rename nikki.@rule[\1].match=matcher/' | uci batch

# since v1.19.1

proxy_fake_ip_ping_hijack=$(uci -q get nikki.proxy.fake_ip_ping_hijack); [ -z "$proxy_fake_ip_ping_hijack" ] && uci set nikki.proxy.fake_ip_ping_hijack=0

# since v1.20.0

mixin_api_port=$(uci -q get nikki.mixin.api_port); [ -n "$mixin_api_port" ] && {
	uci del nikki.mixin.api_port
	uci set nikki.mixin.api_listen=[::]:$mixin_api_port
}

mixin_dns_port=$(uci -q get nikki.mixin.dns_port); [ -n "$mixin_dns_port" ] && {
	uci del nikki.mixin.dns_port
	uci set nikki.mixin.dns_listen=[::]:$mixin_dns_port
}


# commit
uci commit nikki

# exit with 0
exit 0
