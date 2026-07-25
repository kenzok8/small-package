#!/bin/sh

[ "$(uci -q get clashoo.config.acl_migrated 2>/dev/null)" = "1" ] && exit 0
if uci -q show clashoo 2>/dev/null | grep -q '=lan_acl$'; then
	uci -q set clashoo.config.acl_migrated='1'
	uci -q commit clashoo
	exit 0
fi

mode="$(uci -q get clashoo.config.access_control 2>/dev/null)"

add_group() {
	local dns="$1" proxy="$2" list_key="${3:-}" section value

	section="$(uci -q add clashoo lan_acl)" || exit 1
	uci -q set clashoo."$section".enabled='1'
	uci -q set clashoo."$section".dns="$dns"
	uci -q set clashoo."$section".proxy="$proxy"
	if [ -n "$list_key" ]; then
		for value in $(uci -q get clashoo.config."$list_key" 2>/dev/null); do
			uci -q add_list clashoo."$section".ip="$value"
		done
	fi
}

case "$mode" in
	1)
		add_group 1 1 proxy_lan_ips
		add_group 0 0
		;;
	2)
		add_group 0 0 reject_lan_ips
		add_group 1 1
		;;
esac

uci -q set clashoo.config.acl_migrated='1'
uci -q commit clashoo
