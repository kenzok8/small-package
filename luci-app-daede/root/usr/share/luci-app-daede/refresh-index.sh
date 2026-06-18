#!/bin/sh
# Refresh the apk/opkg index for the Updates view. Runs in the FOREGROUND so
# the caller can re-probe once the index is current; throttled to 90s.

LOCK=/tmp/luci-app-daede.idx.lock

if [ -f "$LOCK" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	[ "$(( $(date +%s) - mtime ))" -lt 90 ] && exit 0
fi
: > "$LOCK"

# -n: skip if a package op holds the shared apk lock (no need to refresh then)
if command -v apk >/dev/null 2>&1; then
	flock -n /tmp/luci-app-daede.apk.lock apk update
elif command -v opkg >/dev/null 2>&1; then
	opkg update
fi >/dev/null 2>&1

exit 0
