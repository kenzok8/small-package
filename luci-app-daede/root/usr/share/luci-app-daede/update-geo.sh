#!/bin/sh
# update-geo.sh <geoip|geosite>
# Fork-and-detach so the LuCI RPC call returns immediately. The diagnostics
# card polls the .dat file's mtime/size to detect completion. A lock file
# in /tmp prevents concurrent runs.

TYPE="$1"
case "$TYPE" in
	geoip)
		URL="https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
		DEST="/usr/share/v2ray/geoip.dat"
		;;
	geosite)
		URL="https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
		DEST="/usr/share/v2ray/geosite.dat"
		;;
	*)
		echo "usage: $0 <geoip|geosite>" >&2
		exit 64
		;;
esac

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

	TMP="${DEST}.new"
	mkdir -p "$(dirname "$DEST")"
	echo "$(date '+%F %T') begin: $URL"

	if ! curl -fsSL --connect-timeout 15 --max-time 240 -o "$TMP" "$URL"; then
		echo "$(date '+%F %T') download failed"
		rm -f "$TMP"
		exit 1
	fi

	size=$(wc -c < "$TMP" 2>/dev/null || echo 0)
	if [ "$size" -lt 102400 ]; then
		echo "$(date '+%F %T') file too small ($size bytes)"
		rm -f "$TMP"
		exit 2
	fi

	mv "$TMP" "$DEST"
	echo "$(date '+%F %T') updated $DEST ($size bytes)"
) </dev/null >/dev/null 2>&1 &

echo "started in background, see $LOG"
exit 0
