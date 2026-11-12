#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Background package index refresh for the Maintenance view. Returns at once.

LOCK=/tmp/luci-app-honk.idx.lock

if [ -f "$LOCK" ]; then
	mtime=$(date -r "$LOCK" +%s 2>/dev/null || echo 0)
	[ "$(( $(date +%s) - mtime ))" -lt 90 ] && exit 0
fi
: > "$LOCK"

if command -v apk >/dev/null 2>&1; then
	apk update >/dev/null 2>&1 </dev/null &
elif command -v opkg >/dev/null 2>&1; then
	opkg update >/dev/null 2>&1 </dev/null &
else
	exit 0
fi
_pid=$!
# 有一个镜像卡住就会把 opkg 锁占死，60 秒后直接掐掉。
( sleep 60; kill -TERM "$_pid" 2>/dev/null; sleep 5; kill -KILL "$_pid" 2>/dev/null ) >/dev/null 2>&1 &

exit 0
