#!/bin/sh
# clashoo core log size guard
# 用法: core_log_guard.sh [logfile]
#
# core.log 落在 /var/log（= /tmp 下的 tmpfs），没有大小上限时一次 accept
# 失败风暴就能把它写到几百 MB，直接把 /tmp 写满（dnsmasq、配置生成、
# cron 全部失效）。这里在超过上限时就地裁剪，只保留尾部内容。
# 内核进程持有该文件的 O_APPEND fd，所以必须原地重写，不能替换 inode。

set -u

LOG="${1:-/var/log/clashoo/core.log}"
MAX_KB="${CLASHOO_CORE_LOG_MAX_KB:-16384}"
KEEP_KB="${CLASHOO_CORE_LOG_KEEP_KB:-1024}"

[ -f "$LOG" ] || exit 0
size="$(wc -c <"$LOG" 2>/dev/null)"
case "${size:-}" in ''|*[!0-9]*) exit 0 ;; esac
[ "$size" -gt $((MAX_KB * 1024)) ] || exit 0

tmp="${LOG}.trim.$$"
if tail -c $((KEEP_KB * 1024)) "$LOG" >"$tmp" 2>/dev/null && cat "$tmp" >"$LOG" 2>/dev/null; then
	rm -f "$tmp"
else
	rm -f "$tmp"
	: >"$LOG" 2>/dev/null || true
fi
exit 0
