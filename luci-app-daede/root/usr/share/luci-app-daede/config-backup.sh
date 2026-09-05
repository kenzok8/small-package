#!/bin/sh
# Whole-plugin backup/import/reset. Only fixed configuration paths are managed.
set -eu
umask 077

ACTION="${1:-}"
UPLOAD="${2:-/tmp/daede-import.b64}"
LOG=/tmp/luci-app-daede.backup.log
LOCK=/tmp/luci-app-daede.config.lock
SHARE=/usr/share/luci-app-daede
MAX_TAR=184320 # Base64 must fit inside the ubus reply (~240 KiB).
MAX_RAW=16777216
FILES="etc/config/dae etc/config/daed etc/config/daede etc/dae/config.dae etc/daed/wing.db etc/daed/wing.db-wal etc/daed/wing.db-shm"
WORK=""
SNAPSHOT=0
MUTATING=0
KEEP=0
RESTART=""

fail() { echo "$*" >&2; exit 1; }
b64enc() { ucode -e 'let f=require("fs"); print(b64enc(f.open(ARGV[0],"r").read("all")));' -- "$1"; }
b64dec() { ucode -e 'let f=require("fs"); let r=b64dec(trim(f.open(ARGV[0],"r").read("all"))); if(!r)exit(1); let o=f.open(ARGV[1],"w"); if(!o || o.write(r)!=length(r))exit(1); o.close();' -- "$1" "$2"; }
# Do not merge pending CLI UCI deltas into snapshots/defaults.
config() { /sbin/uci -c /etc/config -t "$WORK/uci" "$@"; }

paths() {
	printf '%s\n' $FILES
	for sub in "$1"/etc/dae/subscriptions/*.sub; do
		[ -e "$sub" ] || [ -L "$sub" ] || continue
		name="${sub##*/}"
		case "${name%.sub}" in ''|*[!A-Za-z0-9_]*) fail 'unexpected subscription filename' ;; esac
		printf 'etc/dae/subscriptions/%s\n' "$name"
	done
}
check_paths() {
	for dir in /etc/config /etc/dae /etc/daed /etc/dae/subscriptions; do
		[ ! -L "$dir" ] || fail "refusing symlink: $dir"
	done
	paths / > "$WORK/paths"
	while IFS= read -r p; do
		[ ! -L "/$p" ] || fail "refusing symlink: /$p"
		[ ! -e "/$p" ] || [ -f "/$p" ] || fail "not a regular file: /$p"
	done < "$WORK/paths"
}
snapshot() {
	mkdir -p "$WORK/before"
	while IFS= read -r p; do
		[ -f "/$p" ] || continue
		mkdir -p "$WORK/before/${p%/*}"
		cp -p "/$p" "$WORK/before/$p"
	done < "$WORK/paths"
	SNAPSHOT=1
}
stop_backends() {
	for svc in dae daed; do
		[ -x "/etc/init.d/$svc" ] || continue
		if /etc/init.d/"$svc" running >/dev/null 2>&1; then RESTART="$RESTART $svc"; fi
		/etc/init.d/"$svc" stop >/dev/null 2>&1 || fail "failed to stop $svc; configuration unchanged"
	done
	# procd termination can be asynchronous. Never copy a live SQLite database.
	for attempt in 1 2 3 4 5; do
		if ! pidof dae daed daed-guard >/dev/null 2>&1; then return; fi
		sleep 1
	done
	fail 'backend still running; configuration unchanged'
}
disable_backends() {
	for svc in dae daed; do
		if [ -f "/etc/config/$svc" ]; then
			config -q set "$svc.config=$svc" || return 1
			config -q set "$svc.config.enabled=0" || return 1
			config -q commit "$svc" || return 1
		fi
		if [ -x "/etc/init.d/$svc" ]; then
			/etc/init.d/"$svc" disable >/dev/null 2>&1 || return 1
			/etc/init.d/"$svc" stop >/dev/null 2>&1 || return 1
		fi
	done
}
restore_snapshot() {
	# Remove files created by the failed operation as well as original files.
	paths / > "$WORK/current" || return 1
	while IFS= read -r p; do rm -f "/$p" || return 1; done < "$WORK/current"
	while IFS= read -r p; do
		[ -f "$WORK/before/$p" ] || continue
		mkdir -p "/${p%/*}" || return 1
		cp -p "$WORK/before/$p" "/$p" || return 1
	done < "$WORK/paths"
}
sync_cron() {
	geo=disable; sub=disable
	[ "$(config -q get daede.config.geo_auto || :)" != 1 ] || geo=enable
	[ "$(config -q get daed.config.subscribe_auto_update || :)" != 1 ] || sub=enable
	"$SHARE/geo-cron.sh" "$geo" >/dev/null 2>&1
	"$SHARE/daed-sub-cron.sh" "$sub" >/dev/null 2>&1
}
finish() {
	rc=$?
	trap - EXIT HUP INT TERM
	if [ "$rc" -ne 0 ] && [ "$MUTATING" = 1 ]; then
		disable_backends || true
		if [ "$SNAPSHOT" = 1 ] && ! restore_snapshot; then
			KEEP=1
			echo "rollback failed; root-only recovery files retained at $WORK" >&2
		else
			echo 'previous configuration restored; backends remain disabled' >&2
		fi
		disable_backends || { KEEP=1; echo 'failed to disable backend; check service state' >&2; }
		sync_cron || true
	fi
	if [ "$ACTION" = export ]; then
		for svc in $RESTART; do
			/etc/init.d/"$svc" start >/dev/null 2>&1 || { rc=1; echo "failed to resume $svc" >&2; }
		done
	fi
	if [ "$ACTION" != export ]; then
		if [ "$rc" = 0 ]; then echo '✓ 完成'; else echo '✗ 失败'; fi
	fi
	[ "$KEEP" = 1 ] || rm -rf "$WORK"
	rmdir "$LOCK"
	exit "$rc"
}
validate_archive() {
	[ "$(wc -c < "$WORK/upload.b64")" -le 245760 ] || fail 'upload too large'
	b64dec "$WORK/upload.b64" "$WORK/import.gz" || fail 'invalid base64 upload'
	[ "$(wc -c < "$WORK/import.gz")" -le "$MAX_TAR" ] || fail 'archive too large'
	gzip -t "$WORK/import.gz" 2>/dev/null || fail 'invalid gzip archive'
	gzip -dc "$WORK/import.gz" | head -c 16777217 > "$WORK/import.tar"
	[ "$(wc -c < "$WORK/import.tar")" -le "$MAX_RAW" ] || fail 'unpacked backup exceeds 16 MiB'
	tar -tf "$WORK/import.tar" > "$WORK/entries" 2>/dev/null || fail 'invalid tar archive'
	[ -s "$WORK/entries" ] || fail 'empty archive'
	# Reject links, directories, devices and duplicate entries before extraction.
	tar -tvf "$WORK/import.tar" > "$WORK/types" 2>/dev/null || fail 'invalid tar headers'
	if grep -qv '^-' "$WORK/types"; then fail 'only regular files are allowed'; fi
	[ -z "$(sort "$WORK/entries" | uniq -d)" ] || fail 'duplicate archive entry'
	while IFS= read -r p; do
		case "$p" in
			etc/config/dae|etc/config/daed|etc/config/daede|etc/dae/config.dae|etc/daed/wing.db|etc/daed/wing.db-wal|etc/daed/wing.db-shm) ;;
			etc/dae/subscriptions/*.sub)
				name="${p#etc/dae/subscriptions/}"
				case "${name%.sub}" in ''|*[!A-Za-z0-9_]*) fail 'invalid subscription path' ;; esac ;;
			*) fail 'unexpected archive entry' ;;
		esac
	done < "$WORK/entries"
	mkdir -p "$WORK/after"
	tar -xf "$WORK/import.tar" -C "$WORK/after"
	found=0
	for svc in dae daed daede; do
		[ -f "$WORK/after/etc/config/$svc" ] || continue
		found=1
		/sbin/uci -c "$WORK/after/etc/config" -t "$WORK/uci" -q export "$svc" >/dev/null || fail "invalid $svc configuration"
	done
	[ "$found" = 1 ] || fail 'backup has no UCI configuration'
	if [ -f "$WORK/after/etc/daed/wing.db-wal" ]; then
		[ -f "$WORK/after/etc/daed/wing.db" ] || fail 'database WAL has no database'
	fi
	ab="$(/sbin/uci -c "$WORK/after/etc/config" -t "$WORK/uci" -q get daede.config.active_backend || echo dae)"
	case "$ab" in dae|daed) ;; *) fail 'invalid backend in backup' ;; esac
	[ -x "/etc/init.d/$ab" ] || fail "backup backend $ab is not installed"
}
run_action() {
	trap finish EXIT
	trap 'exit 1' HUP INT TERM
	check_paths
	if [ "$ACTION" = import ]; then validate_archive; fi
	if [ "$ACTION" = reset ]; then
		mkdir -p "$WORK/after/etc/config"
		for svc in dae daed daede; do
			cp "$SHARE/defaults/$svc" "$WORK/after/etc/config/$svc"
		done
		"$SHARE/config-defaults.sh" "$WORK/after/etc/config"
		if [ ! -x /etc/init.d/daed ]; then
			/sbin/uci -c "$WORK/after/etc/config" -t "$WORK/uci" set daede.config.active_backend=dae
			/sbin/uci -c "$WORK/after/etc/config" -t "$WORK/uci" commit daede
		fi
	fi
	stop_backends
	snapshot
	if [ "$ACTION" = export ]; then
		paths "$WORK/before" > "$WORK/candidates"
		: > "$WORK/entries"
		while IFS= read -r p; do [ ! -f "$WORK/before/$p" ] || echo "$p" >> "$WORK/entries"; done < "$WORK/candidates"
		[ -s "$WORK/entries" ] || fail 'no configuration to export'
		tar -czf "$WORK/export.gz" -C "$WORK/before" -T "$WORK/entries"
		[ "$(wc -c < "$WORK/export.gz")" -le "$MAX_TAR" ] || fail 'config too large; use System Backup instead'
		b64enc "$WORK/export.gz"
		return
	fi
	MUTATING=1
	disable_backends
	# Old backups may omit an uninstalled backend. Keep its UCI file, but remove
	# all managed data first so stale WAL/SHM and local subscriptions cannot leak in.
	while IFS= read -r p; do
		case "$p" in etc/config/*) continue ;; esac
		rm -f "/$p"
	done < "$WORK/paths"
	paths "$WORK/after" > "$WORK/replacement"
	while IFS= read -r p; do
		[ -f "$WORK/after/$p" ] || continue
		mkdir -p "/${p%/*}"
		cp "$WORK/after/$p" "/$p"
		chmod 600 "/$p"
	done < "$WORK/replacement"
	if [ "$ACTION" = reset ]; then
		disable_backends
		sync_cron
		echo 'All defaults restored. Backends are disabled; configure before starting manually.'
	else
		# Preserve the imported active backend's enabled flag. The other backend
		# stays disabled even when the archive was made on a dual-backend router.
		for svc in dae daed; do
			[ "$svc" = "$ab" ] || [ ! -f "/etc/config/$svc" ] || { config -q set "$svc.config.enabled=0"; config -q commit "$svc"; }
		done
		sync_cron
		if [ "$(config -q get "$ab.config.enabled" || :)" = 1 ]; then
			/etc/init.d/"$ab" enable
			/etc/init.d/"$ab" start
			/etc/init.d/"$ab" running >/dev/null 2>&1 || fail 'restored backend failed to start'
		else
			/etc/init.d/"$ab" disable
		fi
		echo 'Backup restored. Active backend follows the saved enabled setting.'
	fi
}

case "$ACTION" in export|import|reset) ;; *) fail "usage: $0 export|import [upload]|reset" ;; esac
# An atomic lock covers the complete operation, including background execution.
mkdir "$LOCK" 2>/dev/null || fail 'another configuration operation is running'
WORK="$(mktemp -d /tmp/daede-config.XXXXXX)" || { rmdir "$LOCK"; exit 1; }
mkdir -p "$WORK/uci"
if [ "$ACTION" = import ]; then
	case "$UPLOAD" in
		/tmp/daede-import.b64) ;;
		/tmp/daede-import.*.b64)
			token="${UPLOAD#/tmp/daede-import.}"; token="${token%.b64}"
			case "$token" in ''|*[!a-f0-9]*) rm -rf "$WORK"; rmdir "$LOCK"; fail 'invalid upload path' ;; esac ;;
		*) rm -rf "$WORK"; rmdir "$LOCK"; fail 'invalid upload path' ;;
	esac
	if [ ! -f "$UPLOAD" ] || [ -L "$UPLOAD" ]; then rm -rf "$WORK"; rmdir "$LOCK"; fail 'upload missing or unsafe'; fi
	mv "$UPLOAD" "$WORK/upload.b64" || { rm -rf "$WORK"; rmdir "$LOCK"; exit 1; }
fi
if [ "$ACTION" = export ]; then
	run_action
else
	# Truncate before returning, so the frontend cannot mistake an earlier job
	# for this one. The child owns the lock and all cleanup from here on.
	: > "$LOG"
	(run_action) </dev/null >"$LOG" 2>&1 &
	echo "started in background, see $LOG"
fi
