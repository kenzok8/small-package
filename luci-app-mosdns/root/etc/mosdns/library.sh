#!/bin/echo Warning:this is a library should be sourced!
pid() {
	pgrep -f "$1"
}

getdat() {
	if exist curl; then
		curl -fSLo "$TMPDIR/$1" "https://gh.404delivr.workers.dev/https://github.com/QiuSimons/openwrt-mos/raw/master/luci-app-mosdns/root/etc/mosdns/$1"
	else
		wget "https://gh.404delivr.workers.dev/https://github.com/QiuSimons/openwrt-mos/raw/master/luci-app-mosdns/root/etc/mosdns/$1" -nv -O "$TMPDIR/$1"
	fi
}

getdns() {
	if [ "$2" == "inactive" ]; then
		ubus call network.interface.wan status | jsonfilter -e "@['inactive']['dns-server'][$1]"
	else
		ubus call network.interface.wan status | jsonfilter -e "@['dns-server'][$1]"
	fi
}

exist() {
	command -v "$1" >/dev/null &>/dev/null
}

L_exist() {
	if [ "$1" == "ssrp" ]; then
		uci get shadowsocksr.@global[0].global_server &>/dev/null
	elif [ "$1" == "pw" ]; then
		uci get passwall.@global[0].enabled &>/dev/null
	elif [ "$1" == "vssr" ]; then
		uci get vssr.@global[0].global_server &>/dev/null
	fi
}
