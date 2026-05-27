#!/bin/sh
# update-pkg.sh <dae|daed|luci-app-daede>
# Refresh package indexes and upgrade the named package via apk (25.12+) or
# opkg (24.10). Forks the work to background so the LuCI RPC call returns
# immediately; the result is streamed to /tmp/luci-app-daede.pkg.<name>.log.

PKG="$1"
case "$PKG" in
	dae|daed|luci-app-daede) ;;
	*)
		echo "usage: $0 <dae|daed|luci-app-daede>" >&2
		exit 64
		;;
esac

LOCK="/tmp/luci-app-daede.pkg-${PKG}.lock"
LOG="/tmp/luci-app-daede.pkg-${PKG}.log"

if [ -f "$LOCK" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	age=$(( $(date +%s) - mtime ))
	if [ "$age" -lt 300 ]; then
		echo "${PKG} update already in progress (PID $(cat "$LOCK" 2>/dev/null), age ${age}s)" >&2
		exit 75
	fi
	rm -f "$LOCK"
fi

if ! ( set -C; echo "$$" >"$LOCK" ) 2>/dev/null; then
	echo "${PKG} update already in progress" >&2
	exit 75
fi

(
	exec >"$LOG" 2>&1
	trap 'rm -f "$LOCK"' EXIT INT TERM

	echo "$(date '+%F %T') begin upgrade: $PKG"

	if command -v apk >/dev/null 2>&1; then
		echo "--- apk update ---"
		apk update 2>&1
		echo "--- apk upgrade $PKG ---"
		# --no-self-upgrade so apk itself does not jump versions mid-op
		apk upgrade --no-self-upgrade "$PKG" 2>&1
		rc=$?
	elif command -v opkg >/dev/null 2>&1; then
		echo "--- opkg update ---"
		opkg update 2>&1
		echo "--- opkg upgrade $PKG ---"
		opkg upgrade "$PKG" 2>&1
		rc=$?
	else
		echo "no package manager found"
		exit 3
	fi

	echo "$(date '+%F %T') done (rc=$rc)"

	# luci-app-daede upgrade replaces ACL JSON — reload rpcd so changes apply.
	if [ "$PKG" = "luci-app-daede" ] && [ "$rc" = "0" ]; then
		echo "reloading rpcd to pick up new ACL"
		/etc/init.d/rpcd reload 2>&1
	fi
) </dev/null >/dev/null 2>&1 &

echo "started in background, see $LOG"
exit 0
