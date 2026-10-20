#!/bin/sh
# Background apk/opkg update for the Updates view. Returns at once; throttled.

LOCK=/tmp/luci-app-daede.idx.lock
STATUS=/tmp/luci-app-daede.idx.status
LOG=/tmp/luci-app-daede.idx.log

write_status() {
	printf '%s\n' "$1" > "${STATUS}.$$" && mv "${STATUS}.$$" "$STATUS"
}

if [ -f "$LOCK" ] && [ -f "$STATUS" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	[ "$(( $(date +%s) - mtime ))" -lt 90 ] && exit 0
fi
: > "$LOCK"
write_status running

(
	flock -n 9 || exit 0
	umask 077
	# Wait for package upgrades before refreshing the same apk database.
	if command -v apk >/dev/null 2>&1; then
		flock /tmp/luci-app-daede.apk.lock apk update > "$LOG" 2>&1
		rc=$?
	elif command -v opkg >/dev/null 2>&1; then
		opkg update > "$LOG" 2>&1
		rc=$?
	else
		printf '%s\n' 'No supported package manager' > "$LOG"
		rc=127
	fi
	if [ "$rc" -eq 0 ]; then
		write_status success
	else
		write_status failed
	fi
) 9>/tmp/luci-app-daede.idx.run.lock >/dev/null 2>&1 </dev/null &

exit 0
