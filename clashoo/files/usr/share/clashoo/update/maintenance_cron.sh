#!/bin/sh

STATE_DIR="${CLASHOO_STATE_DIR:-/usr/share/clashbackup}"
UPDATE_SCRIPT="${CLASHOO_UPDATE_SCRIPT:-/usr/share/clashoo/update/update_all.sh}"
LOG_FILE="${CLASHOO_LOG_FILE:-/usr/share/clashoo/clashoo.txt}"
LOCK_DIR="${CLASHOO_LOCK_DIR:-/tmp/clashoo_maintenance.lock}"
NOW="${CLASHOO_NOW:-$(date +%s)}"

stamp() {
	tmp="$STATE_DIR/$1.tmp.$$"
	printf 'last_run=%s\n' "$NOW" >"$tmp" && mv -f "$tmp" "$STATE_DIR/$1"
}

due() {
	hours="$(uci -q get "clashoo.config.$2")"
	echo "$hours" | grep -Eq '^[0-9]+$' && [ "$hours" -ge 1 ] || hours=12
	last="$(sed -n 's/^last_run=//p' "$STATE_DIR/$1" 2>/dev/null | head -1)"
	if ! echo "$last" | grep -Eq '^[0-9]+$' || [ "$last" -gt "$NOW" ]; then
		stamp "$1"
		return 1
	fi
	[ $((NOW - last)) -ge $((hours * 3600)) ]
}

mkdir -p "$STATE_DIR" || exit 0
mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1' EXIT INT TERM

if [ "$(uci -q get clashoo.config.auto_update)" = "1" ] && due rule_update.status auto_update_time; then
	CLASHOO_STATE_DIR="$STATE_DIR" sh "$UPDATE_SCRIPT" >/dev/null 2>&1
fi

if [ "$(uci -q get clashoo.config.auto_clear_log)" = "1" ] && due log_cleanup.status clear_time; then
	: >"$LOG_FILE"
	stamp log_cleanup.status
fi
