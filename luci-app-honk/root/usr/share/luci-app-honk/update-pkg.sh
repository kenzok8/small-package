#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# update-pkg.sh <honk|luci-app-honk>
# Refresh package indexes and upgrade the named package via apk. Forks to
# background; the result is streamed to /tmp/luci-app-honk.pkg.<name>.log.

PKG="$1"
case "$PKG" in
	honk|luci-app-honk) ;;
	*)
		echo "usage: $0 <honk|luci-app-honk>" >&2
		exit 64
		;;
esac

# Run from a /tmp copy so upgrading luci-app-honk (which replaces this script)
# cannot corrupt the in-flight upgrade.
case "$0" in
	/tmp/.honk-upd-*) ;;
	*)
		_self="/tmp/.honk-upd-$$"
		cp "$0" "$_self" 2>/dev/null && exec sh "$_self" "$@"
		;;
esac

LOCK="/tmp/luci-app-honk.pkg-${PKG}.lock"
LOG="/tmp/luci-app-honk.pkg-${PKG}.log"

. /usr/share/honk/lifecycle.sh 2>/dev/null || :

# 运行状态与恢复交给 lifecycle：它已经处理 dae0/BPF 排空、崩溃重启和就绪判定。
service_running() {
	honk_lifecycle_managed_pid >/dev/null 2>&1
}

# 镜像卡住时 opkg update 会一直占着锁；这里给它上闸，超时直接掐掉。
pkg_update() {
	_limit=$1; shift
	"$@" &
	_pid=$!
	( sleep "$_limit"; kill -TERM "$_pid" 2>/dev/null ) &
	_watch=$!
	wait "$_pid" 2>/dev/null
	_rc=$?
	kill -TERM "$_watch" 2>/dev/null
	wait "$_watch" 2>/dev/null
	if [ "$_rc" != 0 ]; then
		echo "note: 索引刷新超时或被中断（${_limit}s），改用现有缓存继续"
	fi
	return 0
}

restore_service_state() {
	if [ "$was_running" = 1 ]; then
		echo "--- 升级前为运行状态，重启加载新内核 ---"
		if honk_lifecycle_restart 30 >/dev/null 2>&1; then
			echo "result: 服务已恢复运行"
			return 0
		fi
		echo "result: 服务重启失败"
		return 1
	fi
	if service_running; then
		echo "--- 升级前为停止状态，停止服务 ---"
		honk_lifecycle_stop 30 >/dev/null 2>&1 || {
			echo "result: 服务停止或资源排空失败"
			return 1
		}
	fi
	echo "result: 服务保持停止"
	return 0
}

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
	trap 'rm -f "$LOCK"; [ "${0#/tmp/.honk-upd-}" != "$0" ] && rm -f "$0"' EXIT INT TERM

	echo "$(date '+%F %T') begin upgrade: $PKG"
	# 按包管理器/内核目标判断，而不是按车道一律拒绝：24.10 的源本身就是 6.6 通道，
	# 一律拒绝会把这条通道自己的更新也挡掉。
	core_lane=$(jsonfilter -i /usr/share/honk/core-capabilities.json -e '@.lane' 2>/dev/null)
	case "$core_lane:$(command -v apk >/dev/null 2>&1 && echo apk || echo opkg)" in
		linux66:apk|stable:opkg)
			echo "result: 当前核心与软件源不是同一条通道（$core_lane + $(command -v apk >/dev/null 2>&1 && echo APK || echo IPK)），已拒绝升级"
			echo "✗"
			exit 1
			;;
	esac
	was_running=0
	service_running && was_running=1
	echo "升级前服务状态: $([ "$was_running" = 1 ] && echo 运行中 || echo 已停止)"

	if command -v apk >/dev/null 2>&1; then
		(
			flock 9
			apk list "$PKG" 2>/dev/null | grep -q "^$PKG-" || pkg_update 60 apk update 2>&1
			ver=$(apk list "$PKG" 2>/dev/null | awk -v p="$PKG" '$1 ~ "^" p "-[0-9]" { v=$1; sub("^" p "-", "", v); print v }' | sort -V | tail -1)
			if [ -n "$ver" ]; then
				constraint="$PKG=$ver"
			else
				echo "result: 软件源中没有找到 $PKG，请检查网络或软件源配置"
				exit 1
			fi

			echo "--- apk add -s $constraint ---"
			if ! apk add -s "$constraint" 2>&1; then
				echo "note: apk 预检失败，通常是系统上其它软件包的问题，继续尝试升级"
			fi
			echo "--- apk add $constraint ---"
			apk add "$constraint" 2>&1
			exit 0
		) 9>/tmp/luci-app-honk.apk.lock
		rc=$?
		if [ "$rc" != 0 ]; then
			:
		elif ! apk list --installed 2>/dev/null | grep -q "^${PKG}-"; then
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
		(
			flock 9
			opkg list "$PKG" 2>/dev/null | grep -q "^$PKG - " || pkg_update 60 opkg update 2>&1
			opkg install "$PKG" 2>&1
			exit 0
		) 9>/tmp/luci-app-honk.opkg.lock
		rc=$?
		if [ "$rc" != 0 ]; then
			:
		elif ! opkg status "$PKG" 2>/dev/null | grep -q '^Status: .* installed$'; then
			echo "result: $PKG is not installed"
			rc=1
		elif opkg list-upgradable 2>/dev/null | grep -q "^${PKG} - "; then
			echo "result: $PKG still has a pending upgrade"
			rc=1
		else
			echo "result: $PKG is at the latest available version"
			rc=0
		fi
	else
		echo "no package manager found"
		exit 3
	fi

	service_rc=0
	if [ "$rc" = "0" ]; then
		echo "reloading rpcd to pick up new scripts"
		/etc/init.d/rpcd reload 2>&1
		restore_service_state || service_rc=$?
	fi

	# 前端轮询见到 ✓/✗ 即停止，结论只在这里输出一次。
	if [ "$rc" != "0" ]; then
		echo "$(date '+%F %T') ✗ 升级失败 (rc=$rc)"
	elif [ "$service_rc" != "0" ]; then
		echo "$(date '+%F %T') ✗ 软件包升级成功，但服务启动失败，请查看日志后手动启动"
	else
		echo "$(date '+%F %T') ✓ 完成"
	fi
) </dev/null >/dev/null 2>&1 &

echo "started in background, see $LOG"
exit 0
