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

# run from a /tmp copy so upgrading luci-app-daede (which replaces this script)
# can't corrupt the in-flight upgrade
case "$0" in
	/tmp/.daede-upd-*) ;;
	*)
		_self="/tmp/.daede-upd-$$"
		cp "$0" "$_self" 2>/dev/null && exec sh "$_self" "$@"
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
	trap 'rm -f "$LOCK"; [ "${0#/tmp/.daede-upd-}" != "$0" ] && rm -f "$0"' EXIT INT TERM

	echo "$(date '+%F %T') begin upgrade: $PKG"

	if command -v apk >/dev/null 2>&1; then
		# shared apk lock with the bg index refresh (avoid "Unable to lock database")
		(
			flock 9
			apk update 2>&1
			# pin exact latest version + --force-broken-world so unrelated broken
			# packages can't block this upgrade (cf. clashoo component_update)
			ver=$(apk list "$PKG" 2>/dev/null | awk -v p="$PKG" '$1 ~ "^" p "-[0-9]" { v=$1; sub("^" p "-", "", v); print v }' | sort -V | tail -1)
			if [ -n "$ver" ]; then
				echo "--- apk add $PKG=$ver ---"
				apk add "$PKG=$ver" --force-broken-world 2>&1
			else
				echo "--- apk add $PKG ---"
				apk add "$PKG" --force-broken-world 2>&1
			fi
		) 9>/tmp/luci-app-daede.apk.lock
		# apk's exit code is unreliable (broken-world noise); judge by state instead
		if ! apk list --installed 2>/dev/null | grep -q "^${PKG}-"; then
			echo "result: $PKG is not installed"
			rc=1
		elif apk list -u 2>/dev/null | grep -q "^${PKG}-"; then
			echo "result: $PKG still has a pending upgrade"
			rc=1
		else
			echo "result: $PKG is at the latest available version"
			rc=0
		fi
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
