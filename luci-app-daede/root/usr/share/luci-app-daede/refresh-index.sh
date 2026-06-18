#!/bin/sh
# Refresh the apk/opkg index for the Updates view without holding the LuCI RPC
# request open. The view watches STATUS and re-probes as soon as it reads done.

LOCK=/tmp/luci-app-daede.idx.lock
STATUS=/tmp/luci-app-daede.idx.status

if [ -f "$LOCK" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	if [ "$(( $(date +%s) - mtime ))" -lt 90 ]; then
		[ -f "$STATUS" ] || printf '%s\n' done > "$STATUS"
		exit 0
	fi
fi
: > "$LOCK"
printf '%s\n' running > "$STATUS"

# -n: skip if a package op holds the shared apk lock (no need to refresh then)
(
	if command -v apk >/dev/null 2>&1; then
		flock -n /tmp/luci-app-daede.apk.lock apk update
	elif command -v opkg >/dev/null 2>&1; then
		opkg update
	fi
	printf '%s\n' done > "$STATUS"
) >/dev/null 2>&1 </dev/null &

exit 0
