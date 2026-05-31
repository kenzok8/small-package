#!/bin/sh
# proxy-check.sh - test whether dae's transparent proxy can actually reach a
# blocked site (default YouTube). dae proxies the router's own WAN-bound traffic
# (wan_interface), so a plain request from here is routed through dae just like a
# LAN client would be. Prints one line: ok=<0|1> code=<http> ms=<n>

URL="${1:-https://www.youtube.com/generate_204}"

code=000
ms=0

if command -v curl >/dev/null 2>&1; then
	out="$(curl -4 -sL --max-time 8 --connect-timeout 4 \
		-o /dev/null -w '%{http_code} %{time_total}' "$URL" 2>/dev/null)"
	code="$(printf '%s' "$out" | awk '{print $1}')"
	t="$(printf '%s' "$out" | awk '{print $2}')"
	[ -n "$code" ] || code=000
	ms="$(awk -v x="${t:-0}" 'BEGIN{printf "%d", x*1000}')"
else
	# busybox wget has no status/timing output — success is exit 0
	if wget -q -T 8 -O /dev/null "$URL" 2>/dev/null; then code=204; else code=000; fi
fi

ok=0
case "$code" in 200|204|301|302) ok=1 ;; esac

echo "ok=$ok code=$code ms=$ms"
