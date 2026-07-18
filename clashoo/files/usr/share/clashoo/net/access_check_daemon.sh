#!/bin/sh

set -eu

RUNDIR="/tmp/clashoo"
PID_FILE="${RUNDIR}/access_check_daemon.pid"
LOCK_DIR="${RUNDIR}/access_check_daemon.lock"
# 周期：默认 30s，ACCESS_CHECK_INTERVAL 环境变量可固定覆盖
INTERVAL_FIXED="${ACCESS_CHECK_INTERVAL:-}"

mkdir -p "$RUNDIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
	exit 0
fi

cleanup() {
	rm -rf "$LOCK_DIR" "$PID_FILE"
}
trap cleanup EXIT
trap 'cleanup; exit 0' INT TERM

echo "$$" >"$PID_FILE"

while :; do
	[ "$(uci -q get clashoo.config.enable 2>/dev/null)" = "1" ] || break
	/usr/share/clashoo/net/access_check_cache.sh >/dev/null 2>&1 || true
	if [ -n "$INTERVAL_FIXED" ]; then
		sleep "$INTERVAL_FIXED"
	else
		sleep 30
	fi
done
