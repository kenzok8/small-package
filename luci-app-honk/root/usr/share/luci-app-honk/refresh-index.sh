#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Background apk index refresh for the Maintenance view. Returns at once.

LOCK=/tmp/luci-app-honk.idx.lock

if [ -f "$LOCK" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	[ "$(( $(date +%s) - mtime ))" -lt 90 ] && exit 0
fi
: > "$LOCK"

(
	if command -v apk >/dev/null 2>&1; then
		flock -n /tmp/luci-app-honk.apk.lock apk update
	fi
) >/dev/null 2>&1 </dev/null &

exit 0
