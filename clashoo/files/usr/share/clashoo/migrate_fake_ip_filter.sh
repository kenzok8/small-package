#!/bin/sh

set -f

[ "$(uci -q get clashoo.config.fake_ip_filter_migrated 2>/dev/null)" = "1" ] && exit 0

filters="$(uci -q get clashoo.config.fake_ip_filter 2>/dev/null)"
has_legacy=0
for filter in $filters; do
	[ "$filter" = "*.lan" ] && has_legacy=1
done

if [ "$has_legacy" = "1" ]; then
	uci -q delete clashoo.config.fake_ip_filter
	added_lan=0
	added_local=0
	for filter in $filters; do
		case "$filter" in
			'*.lan'|'+.lan')
				if [ "$added_lan" = "0" ]; then
					uci -q add_list clashoo.config.fake_ip_filter='+.lan'
					added_lan=1
				fi
				;;
			'+.local')
				if [ "$added_local" = "0" ]; then
					uci -q add_list clashoo.config.fake_ip_filter='+.local'
					added_local=1
				fi
				;;
			*)
				uci -q add_list clashoo.config.fake_ip_filter="$filter"
				;;
		esac
	done
	if [ "$added_local" = "0" ]; then
		uci -q add_list clashoo.config.fake_ip_filter='+.local'
	fi
fi

uci -q set clashoo.config.fake_ip_filter_migrated='1'
uci -q commit clashoo
