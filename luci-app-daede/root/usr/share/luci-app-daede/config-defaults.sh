#!/bin/sh
# Shared installation/reset defaults. Optional directory is an isolated UCI tree.
set -eu
if [ "$#" -gt 0 ]; then
	config_dir="$1"
	mkdir -p "$config_dir/.uci"
	uci() { /sbin/uci -c "$config_dir" -t "$config_dir/.uci" "$@"; }
fi

if ! uci -q get dae.config.lan_interface >/dev/null 2>&1; then
	uci -q set dae.config.lan_interface='br-lan'
fi
if ! uci -q show dae | grep -q "=group$"; then
	g="$(uci add dae group)"
	uci -q set "dae.$g.name=proxy"
	uci -q set "dae.$g.policy=min_moving_avg"
fi
if ! uci -q get dae.routing >/dev/null 2>&1; then
	uci -q set dae.routing=routing
	uci -q set dae.routing.private_direct=1
	uci -q set dae.routing.cn_direct=1
	uci -q set dae.routing.block_ads=0
	uci -q set dae.routing.fallback=proxy
fi
if ! uci -q get dae.dns >/dev/null 2>&1; then
	uci -q set dae.dns=dns
	uci -q set dae.dns.cn_upstream='udp://dns.alidns.com:53'
	uci -q set dae.dns.fallback_upstream='tcp+udp://dns.google:53'
	uci -q set dae.dns.response_ttl='0'
fi
uci -q commit dae
