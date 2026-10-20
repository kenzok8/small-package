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
			flock 9 || exit 1
			if ! apk info -e "$PKG" >/dev/null 2>&1; then
				echo "result: $PKG 未通过包管理器安装，不能在线升级"
				exit 1
			fi
			if ! apk update 2>&1; then
				echo "result: 软件源刷新失败，请检查网络和软件源配置"
				exit 1
			fi
			ver=$(apk list -a "$PKG" 2>/dev/null | awk -v p="$PKG" '$1 ~ "^" p "-[0-9]" { v=$1; sub("^" p "-", "", v); print v }' | sort -V | tail -1)
			if [ -n "$ver" ]; then
				constraint="$PKG=$ver"
			else
				echo "result: 软件源中没有找到 $PKG，请检查网络或软件源配置"
				exit 1
			fi
			installed=$(apk list -I "$PKG" 2>/dev/null | awk -v p="$PKG" '$1 ~ "^" p "-[0-9]" { v=$1; sub("^" p "-", "", v); print v; exit }')
			if [ -n "$installed" ] && [ "$(printf '%s\n%s\n' "$ver" "$installed" | sort -V | tail -1)" = "$installed" ]; then
				echo "result: $PKG 已安装版本不低于软件源版本，无需升级"
				exit 2
			fi

			echo "--- apk add -s $constraint ---"
			if ! apk add -s "$constraint" 2>&1; then
				echo "note: apk 预检失败，通常是系统上其它软件包的问题，继续尝试升级"
			fi
			echo "--- apk add $constraint ---"
			apk add "$constraint" 2>&1
			add_rc=$?
			[ "$add_rc" -eq 0 ] || exit 1
			if ! apk list -I "$PKG" 2>/dev/null | awk -v p="$PKG" -v v="$ver" '$1 == p "-" v { found = 1 } END { exit !found }'; then
				echo "result: $PKG was not upgraded to $ver"
				exit 1
			fi
			exit 0
		) 9>/tmp/luci-app-daede.apk.lock
		rc=$?
		if [ "$rc" = 2 ]; then
			:
		elif [ "$rc" != 0 ]; then
			:
		elif apk list -u 2>/dev/null | grep -q "^${PKG}-"; then
			echo "result: $PKG still has a pending upgrade"
			rc=1
		else
			echo "result: $PKG is at the latest available version"
			rc=0
		fi
	elif command -v opkg >/dev/null 2>&1; then
		echo "--- opkg update ---"
		if opkg update 2>&1; then
			echo "--- opkg upgrade $PKG ---"
			opkg upgrade "$PKG" 2>&1
			rc=$?
		else
			echo "result: 软件源刷新失败，请检查网络和软件源配置"
			rc=1
		fi
	else
		echo "no package manager found"
		rc=3
	fi

	if [ "$rc" = 0 ]; then
		echo "$(date '+%F %T') ✓ 完成"
	elif [ "$rc" = 2 ]; then
		echo "$(date '+%F %T') ✓ 无需升级"
	else
		echo "$(date '+%F %T') ✗ 失败 (rc=$rc)"
	fi

	# luci-app-daede upgrade replaces ACL JSON — reload rpcd so changes apply.
	if [ "$PKG" = "luci-app-daede" ] && [ "$rc" = "0" ]; then
		echo "reloading rpcd to pick up new ACL"
		/etc/init.d/rpcd reload 2>&1
	fi
) </dev/null >/dev/null 2>&1 &

echo "started in background, see $LOG"
exit 0
