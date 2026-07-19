#!/bin/sh
# update-geo.sh <geoip|geosite>
# Fork-and-detach so the LuCI RPC call returns immediately. The diagnostics
# card polls the .dat file's mtime/size to detect completion. A lock file
# in /tmp prevents concurrent runs.

TYPE="$1"
# Default source: Loyalsoldier/v2ray-rules-dat — daily-built, China-optimized,
# ships both geoip.dat and geosite.dat. Users can override per-type via
# daede.config.geoip_url / geosite_url (empty falls back to the default below).
case "$TYPE" in
	geoip)
		DEF_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
		URL="$(uci -q get daede.config.geoip_url)"
		DEST="/usr/share/v2ray/geoip.dat"
		;;
	geosite)
		DEF_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
		URL="$(uci -q get daede.config.geosite_url)"
		DEST="/usr/share/v2ray/geosite.dat"
		;;
	*)
		echo "usage: $0 <geoip|geosite>" >&2
		exit 64
		;;
esac
[ -n "$URL" ] || URL="$DEF_URL"

LOCK="/tmp/luci-app-daede.${TYPE}.lock"
LOG="/tmp/luci-app-daede.${TYPE}.log"

if [ -f "$LOCK" ]; then
	# Lock is fresh (< 5 min)? Refuse. Stale? Remove and proceed.
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	age=$(( $(date +%s) - mtime ))
	if [ "$age" -lt 300 ]; then
		echo "${TYPE} update already in progress (PID $(cat "$LOCK" 2>/dev/null), age ${age}s)" >&2
		exit 75
	fi
	rm -f "$LOCK"
fi

if ! ( set -C; echo "$$" >"$LOCK" ) 2>/dev/null; then
	echo "${TYPE} update already in progress" >&2
	exit 75
fi

# Spawn detached worker — parent returns immediately to LuCI.
(
	exec >"$LOG" 2>&1
	trap 'rm -f "$LOCK"' EXIT INT TERM

	rc=0
	TMP="${DEST}.new"
	mkdir -p "$(dirname "$DEST")"
	echo "$(date '+%F %T') begin: $URL"

	if ! curl -fsSL --connect-timeout 15 --max-time 240 -o "$TMP" "$URL"; then
		echo "$(date '+%F %T') download failed"
		rm -f "$TMP"
		rc=1
	else
		size=$(wc -c < "$TMP" 2>/dev/null || echo 0)
		magic=$(hexdump -n 1 -e '1/1 "%02x"' "$TMP" 2>/dev/null)
		if [ "$size" -lt 1024 ]; then
			echo "$(date '+%F %T') file too small ($size bytes)"
			rm -f "$TMP"
			rc=2
		elif [ "$magic" != "0a" ]; then
			echo "$(date '+%F %T') invalid geodata format"
			rm -f "$TMP"
			rc=3
		else
			mv "$TMP" "$DEST"
			echo "$(date '+%F %T') updated $DEST ($size bytes)"
		fi
	fi
	if [ "$rc" = 0 ]; then echo "$(date '+%F %T') ✓ 完成"; else echo "$(date '+%F %T') ✗ 失败 (rc=$rc)"; fi
) </dev/null >/dev/null 2>&1 &

echo "started in background, see $LOG"
exit 0
