#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
umask 077

HONK_ROOT=/etc/honk
HONK_CONFIG=$HONK_ROOT/config.dae
HONK_SYSTEM=$HONK_ROOT/system.dae
HONK_STATE=$HONK_ROOT/state/honk.db
HONK_CORE=/usr/bin/honk-core
IMPORT_PREVIEW_ROOT=/tmp/honk-v2-import
BACKUP=/tmp/honk-backup.tar.gz
RESTORE=/tmp/honk-maintenance/restore.tar.gz
LOCK_DIR=/run/honk.lock
TXN_DIR=/etc/.honk-maintenance
JOURNAL=$TXN_DIR/journal
MAX_COMPRESSED=33554432
MAX_EXPANDED=134217728
MAX_FILE=67108864
MAX_FILES=512
CAPABILITY=$TXN_DIR/capability

if [ "${HONK_MAINT_LIBRARY:-0}" != 1 ]; then
	. /usr/share/honk/lock.sh || exit 1
	. /usr/share/honk/lifecycle.sh || exit 1
	. /usr/share/libubox/jshn.sh || exit 1
	# lifecycle.sh 用 config_load/config_get 读模式，job 路径没有 rc.common 帮它加载。
	[ -r /lib/functions.sh ] && . /lib/functions.sh
fi

json_result() {
	json_ok=0
	[ "$1" = true ] && json_ok=1
	json_init
	json_add_boolean ok "$json_ok"
	[ -n "$2" ] && json_add_string path "$2"
	json_add_string message "$3"
	json_dump
}

error() {
	json_result false "" "$1"
	return 1
}

managed_core_pid() {
	managed_pid=$(ubus call service list '{"name":"honk"}' 2>/dev/null | jsonfilter -e '@.honk.instances.main.pid' 2>/dev/null)
	case "$managed_pid" in ''|*[!0-9]*) return 1 ;; esac
	[ -r "/proc/$managed_pid/cmdline" ] || return 1
	managed_cmd=$(tr '\000' ' ' < "/proc/$managed_pid/cmdline" 2>/dev/null) || return 1
	case "$managed_cmd" in
		*/usr/bin/honk-core\ --config\ /etc/honk/config.dae\ --disable-timestamp*) ;;
		*) return 1 ;;
	esac
	case "$managed_cmd" in *--mock-ebpf*) return 1 ;; esac
	[ "$(readlink -f "/proc/$managed_pid/exe" 2>/dev/null)" = "$HONK_CORE" ] || return 1
	printf '%s\n' "$managed_pid"
}

foreign_core_running() {
	managed_pid=$(managed_core_pid 2>/dev/null || true)
	for core_pid in $(pidof honk-core 2>/dev/null); do
		[ "$core_pid" = "$managed_pid" ] || return 0
	done
	return 1
}

proc_starttime() {
	stat_line=$(cat "/proc/$1/stat" 2>/dev/null) || return 1
	stat_tail=${stat_line##*) }
	set -- $stat_tail
	[ "$#" -ge 20 ] || return 1
	stat_index=1
	for stat_field do
		if [ "$stat_index" = 20 ]; then
			case "$stat_field" in ''|*[!0-9]*) return 1 ;; esac
			printf '%s\n' "$stat_field"
			return 0
		fi
		stat_index=$((stat_index + 1))
	done
	return 1
}

new_nonce() {
	nonce_value=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-') || return 1
	case "$nonce_value" in [0-9a-f][0-9a-f]*) [ "${#nonce_value}" = 32 ] || return 1 ;; *) return 1 ;; esac
	printf '%s\n' "$nonce_value"
}

issue_capability() {
	cap_phase=$1
	[ "$(id -u 2>/dev/null)" = 0 ] || return 1
	case "$cap_phase:$journal_operation:$journal_phase" in
		candidate_health_start:restore:new_installed|rollback_old_start:restore:rollback_old_start|rollback_old_start:reset:rollback_old_start) ;;
		*) return 1 ;;
	esac
	cap_nonce=$(new_nonce) || return 1
	cap_owner=$$
	cap_starttime=$(proc_starttime "$cap_owner") || return 1
	cap_tmp=$TXN_DIR/capability.new.$cap_owner
	{
		printf 'format=1\nnonce=%s\ntxn_id=%s\nphase=%s\nowner_pid=%s\nowner_starttime=%s\n' \
			"$cap_nonce" "$txn_id" "$cap_phase" "$cap_owner" "$cap_starttime"
	} > "$cap_tmp" || return 1
	chmod 0600 "$cap_tmp" || { rm -f "$cap_tmp"; return 1; }
	mv -f "$cap_tmp" "$CAPABILITY" || { rm -f "$cap_tmp"; return 1; }
	export HONK_MAINT_CAP=$cap_nonce
	honk_lifecycle_start 30
	cap_start_rc=$?
	unset HONK_MAINT_CAP
	return "$cap_start_rc"
}

stop_managed() {
	old_pid=$(managed_core_pid 2>/dev/null || true)
	if foreign_core_running; then return 2; fi
	if [ -n "$old_pid" ]; then
		honk_lifecycle_stop 30 || return 1
		managed_core_pid >/dev/null 2>&1 && return 1
	fi
	return 0
}

restore_running() {
	if [ "$old_running" != 1 ]; then service_stopped=0; return 0; fi
	foreign_core_running && return 1
	honk_lifecycle_start 30 || return 1
	service_stopped=0
}

capture_boot_links() {
	boot_start_path=/etc/rc.d/S95honk
	boot_stop_path=/etc/rc.d/K10honk
	old_start_link=-
	old_stop_link=-
	if [ -L "$boot_start_path" ]; then old_start_link=$(readlink "$boot_start_path") || return 1
	elif [ -e "$boot_start_path" ]; then return 1; fi
	if [ -L "$boot_stop_path" ]; then old_stop_link=$(readlink "$boot_stop_path") || return 1
	elif [ -e "$boot_stop_path" ]; then return 1; fi
	case "$old_start_link:$old_stop_link" in
		-:-|../init.d/honk:-|-:../init.d/honk|../init.d/honk:../init.d/honk) ;;
		*) return 1 ;;
	esac
}

restore_boot_links() {
	for boot_link in /etc/rc.d/S95honk /etc/rc.d/K10honk; do
		[ ! -e "$boot_link" ] || [ -L "$boot_link" ] || return 1
		rm -f "$boot_link" || return 1
	done
	if [ "$old_start_link" != - ]; then ln -s "$old_start_link" /etc/rc.d/S95honk || return 1; fi
	if [ "$old_stop_link" != - ]; then ln -s "$old_stop_link" /etc/rc.d/K10honk || return 1; fi
}

disable_boot_links() {
	for boot_link in /etc/rc.d/S95honk /etc/rc.d/K10honk; do
		[ ! -e "$boot_link" ] || [ -L "$boot_link" ] || return 1
		rm -f "$boot_link" || return 1
	done
}

journal_write() {
	journal_next=$TXN_DIR/journal.new
	{
		printf 'format=1\noperation=%s\nphase=%s\ntxn_id=%s\nold_running=%s\nold_enabled=%s\nold_boot=%s\nold_initialized=%s\nold_start_link=%s\nold_stop_link=%s\n' \
			"$journal_operation" "$1" "$txn_id" "$old_running" "$old_enabled" "$old_boot" "$old_initialized" "$old_start_link" "$old_stop_link"
	} > "$journal_next" || return 1
	chmod 0600 "$journal_next" || return 1
	sync
	mv -f "$journal_next" "$JOURNAL" || return 1
	sync
	journal_phase=$1
}

journal_create() {
	journal_operation=$1
	txn_id=$(new_nonce) || return 1
	[ ! -e "$TXN_DIR" ] && [ ! -L "$TXN_DIR" ] || return 1
	mkdir "$TXN_DIR" || return 1
	chmod 0700 "$TXN_DIR" || return 1
	cp "$temp_dir/old-uci" "$TXN_DIR/old-uci" || return 1
	chmod 0600 "$TXN_DIR/old-uci" || return 1
	old_uci_snapshot=$TXN_DIR/old-uci
	journal_active=1
	journal_write prepared
}

journal_value() {
	sed -n "s/^$1=//p" "$JOURNAL" 2>/dev/null
}

recover_transaction() {
	[ -e "$TXN_DIR" ] || { journal_active=0; return 0; }
	[ -d "$TXN_DIR" ] && [ ! -L "$TXN_DIR" ] && [ -f "$JOURNAL" ] && [ ! -L "$JOURNAL" ] || return 1
	journal_operation=$(journal_value operation)
	journal_phase=$(journal_value phase)
	journal_format=$(journal_value format)
	txn_id=$(journal_value txn_id)
	old_running=$(journal_value old_running)
	old_enabled=$(journal_value old_enabled)
	old_boot=$(journal_value old_boot)
	old_initialized=$(journal_value old_initialized)
	old_start_link=$(journal_value old_start_link)
	old_stop_link=$(journal_value old_stop_link)
	[ "$journal_format" = 1 ] || return 1
	case "$txn_id" in [0-9a-f][0-9a-f]*) [ "${#txn_id}" = 32 ] || return 1 ;; *) return 1 ;; esac
	case "$journal_operation:$journal_phase" in backup:prepared|backup:stopped|backup:committed|restore:prepared|restore:stopped|restore:old_moved|restore:new_installed|restore:uci_applied|restore:service_started|restore:rollback_old_start|restore:committed|reset:prepared|reset:stopped|reset:old_moved|reset:new_installed|reset:uci_applied|reset:rollback_old_start|reset:committed) ;;
		*) return 1 ;;
	esac
	case "$old_running:$old_enabled:$old_boot:$old_initialized" in
		0:0:0:0|0:0:0:1|0:0:1:0|0:0:1:1|0:1:0:0|0:1:0:1|0:1:1:0|0:1:1:1|1:0:0:0|1:0:0:1|1:0:1:0|1:0:1:1|1:1:0:0|1:1:0:1|1:1:1:0|1:1:1:1) ;;
		*) return 1 ;;
	esac
	case "$old_start_link:$old_stop_link" in -:-|../init.d/honk:-|-:../init.d/honk|../init.d/honk:../init.d/honk) ;; *) return 1 ;; esac
	old_uci_snapshot=$TXN_DIR/old-uci
	[ -f "$old_uci_snapshot" ] && [ ! -L "$old_uci_snapshot" ] || return 1
	if [ "$journal_phase" = committed ]; then
		rm -rf "$TXN_DIR" || return 1
		journal_active=0
		swap_started=0
		if [ "$journal_operation" = backup ] && [ "$old_running" = 1 ]; then
			honk_lifecycle_start 30 || return 1
		fi
		service_stopped=0
		return 0
	fi
	foreign_core_running && return 1
	if [ "$journal_operation" = restore ] || [ "$journal_operation" = reset ]; then
		if managed_core_pid >/dev/null 2>&1; then
			honk_lifecycle_stop 30 || return 1
		fi
		if [ -d "$TXN_DIR/old-tree" ] && [ ! -L "$TXN_DIR/old-tree" ]; then
			if [ -e "$HONK_ROOT" ]; then
				[ ! -e "$TXN_DIR/failed-tree" ] || return 1
				mv "$HONK_ROOT" "$TXN_DIR/failed-tree" || return 1
			fi
			mv "$TXN_DIR/old-tree" "$HONK_ROOT" || return 1
		else
			[ -d "$HONK_ROOT" ] && [ ! -L "$HONK_ROOT" ] || return 1
		fi
	fi
	if ! uci import honk < "$old_uci_snapshot" || ! uci commit honk; then return 1; fi
	restore_boot_links || return 1
	if [ "$old_running" = 1 ]; then
		if ! managed_core_pid >/dev/null 2>&1; then
	if [ "$journal_operation" = restore ] || [ "$journal_operation" = reset ]; then
				journal_write rollback_old_start || return 1
				issue_capability rollback_old_start || return 1
			else
				# A backup never changes the live tree; clear its journal before normal startup.
				rm -rf "$TXN_DIR" || return 1
				journal_active=0
				honk_lifecycle_start 30 || return 1
			fi
		fi
	else
		if managed_core_pid >/dev/null 2>&1; then honk_lifecycle_stop 30 || return 1; fi
	fi
	rm -rf "$TXN_DIR" || return 1
	journal_active=0
	service_stopped=0
	swap_started=0
}

backup_abort() {
	backup_message=$1
	if [ -n "$mock_pid" ] && ! stop_mock; then
		error "${backup_message}_mock_stop_failed_runtime_not_restarted"
		return 1
	fi
	if [ "$journal_active" = 1 ]; then
		recover_transaction || backup_message="${backup_message}_runtime_restore_failed"
	elif ! restore_running; then backup_message="${backup_message}_runtime_restore_failed"; fi
	error "$backup_message"
}

restore_abort() {
	restore_message=$1
	if [ -n "$mock_pid" ] && ! stop_mock; then
		error "${restore_message}_mock_stop_failed"
		return 1
	fi
	if [ "$journal_active" = 1 ]; then
		recover_transaction || restore_message="${restore_message}_rollback_failed"
	elif [ "$service_stopped" = 1 ] && ! restore_running; then
		restore_message="${restore_message}_runtime_restore_failed"
	fi
	error "$restore_message"
}

stop_mock() {
	[ -n "$mock_pid" ] || return 0
	if [ ! -r "/proc/$mock_pid/cmdline" ]; then
		stop_status=0
		wait "$mock_pid" 2>/dev/null || stop_status=$?
		mock_pid=
		[ "$stop_status" = 0 ] || return 1
		return 0
	fi
	mock_identity=$(tr '\000' ' ' < "/proc/$mock_pid/cmdline" 2>/dev/null) || return 1
	case "$mock_identity" in *"$mock_config"*--mock-ebpf*) ;; *) return 1 ;; esac
	[ "$(readlink -f "/proc/$mock_pid/exe" 2>/dev/null)" = "$HONK_CORE" ] || return 1
	kill -TERM "$mock_pid" 2>/dev/null || return 1
	stop_forced=0
	stop_tries=0
	while kill -0 "$mock_pid" 2>/dev/null && [ "$stop_tries" -lt 10 ]; do sleep 1; stop_tries=$((stop_tries + 1)); done
	if kill -0 "$mock_pid" 2>/dev/null; then
		kill -KILL "$mock_pid" 2>/dev/null || return 1
		stop_forced=1
		stop_tries=0
		while kill -0 "$mock_pid" 2>/dev/null && [ "$stop_tries" -lt 5 ]; do sleep 1; stop_tries=$((stop_tries + 1)); done
	fi
	kill -0 "$mock_pid" 2>/dev/null && return 1
	stop_status=0
	wait "$mock_pid" 2>/dev/null || stop_status=$?
	mock_pid=
	[ "$stop_forced" = 0 ] && [ "$stop_status" = 0 ]
}

cleanup() {
	cleanup_status=$?
	cleanup_safe=1
	if [ -n "$mock_pid" ] && ! stop_mock; then cleanup_safe=0; fi
	if [ "$cleanup_safe" = 1 ]; then
		[ ! -e "$CAPABILITY" ] || rm -f "$CAPABILITY"
		if [ "$journal_active" = 1 ]; then
			recover_transaction || { cleanup_safe=0; echo "honk maintenance: transaction recovery failed; preserve $TXN_DIR and $temp_dir" >&2; }
		elif [ "$service_stopped" = 1 ]; then
			restore_running || { cleanup_safe=0; echo "honk maintenance: service restart failed; preserving $temp_dir and lock" >&2; }
		fi
	fi
	if [ "$cleanup_safe" = 1 ]; then
		if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then rm -rf "$temp_dir"; fi
		if [ "$lock_owned" = 1 ]; then honk_lock_release >/dev/null 2>&1; fi
	else
		echo "honk maintenance: cleanup/rollback not confirmed; keeping lock, temporary data at $temp_dir, and any /etc/.honk.restore.* snapshot" >&2
	fi
	return "$cleanup_status"
}

trap cleanup 0
trap 'exit 1' HUP INT TERM

lock_owned=0
temp_dir=
mock_pid=
mock_config=
old_running=0
service_stopped=0
swap_started=0
old_tree_path=
old_uci_snapshot=
journal_active=0
journal_operation=
journal_phase=
old_start_link=-
old_stop_link=-
lock_error=operation_in_progress

acquire_lock() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then lock_error=update_recovery_required; return 1; fi
	if [ -d "$LOCK_DIR" ]; then
		if [ -e "$TXN_DIR" ]; then lock_error=recovery_required; else lock_error=operation_in_progress_or_stale_lock; fi
		return 1
	fi
	honk_lock_acquire || { lock_error=operation_in_progress; return 1; }
	lock_owned=1
	if [ -e "$TXN_DIR" ]; then
		journal_active=1
		recover_transaction || { lock_error=interrupted_transaction_recovery_failed; return 2; }
	fi
	lock_error=
}

recover_action() {
	if [ -d "$LOCK_DIR" ]; then
		error recovery_required_clear_stale_lock_only_after_confirming_no_honk_core
		return 1
	fi
	if ! honk_lock_acquire; then error operation_in_progress; return 1; fi
	lock_owned=1
	if [ -e "$TXN_DIR" ]; then journal_active=1; fi
	recover_transaction || { error interrupted_transaction_recovery_failed; return 1; }
	json_result true "" transaction_recovered
}

check_root_file() {
	[ ! -L "$1" ] && [ -f "$1" ] || return 1
	[ "$(id -u 2>/dev/null)" = 0 ] || return 1
	[ "$(ls -ln "$1" 2>/dev/null | awk 'NR == 1 { print $3 }')" = 0 ] || return 1
	chmod 0600 "$1" 2>/dev/null || return 1
	[ ! -L "$1" ] && [ -f "$1" ] || return 1
	file_mode=$(ls -ldn "$1" 2>/dev/null | awk 'NR == 1 { print $1 }')
	[ "$file_mode" = '-rw-------' ]
}

safe_relpath() {
	case "$1" in ''|/*|*..*|*[^A-Za-z0-9._/-]*|*//*|*/./*|./*|*/.) return 1 ;; esac
	return 0
}

size_of() {
	wc -c < "$1" | tr -d ' '
}

sha_of() {
	sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

core_commit() {
	jsonfilter -i /usr/share/honk/provenance.json -e '@.core.commit' 2>/dev/null
}

load_uci_values() {
	uci_bin=${1:-uci}
	uci_config=${2:-}
	# Run uci with optional -c/-t flags without eval: keep args in "$@" style
	# via a helper so later callers can't inject through string concatenation.
	if [ -n "$uci_config" ]; then
		uci_run() { "$uci_bin" -c "$uci_config" -t "$temp_dir/uci-tmp" "$@"; }
	else
		uci_run() { "$uci_bin" "$@"; }
	fi
	uci_show=$(uci_run -q show honk 2>/dev/null) || return 1
	printf '%s\n' "$uci_show" | awk -F= '
		/^honk\.main=/ { main++ ; next }
		/^honk\.main\.(enabled|boot_enabled|initialized|config_mode|config_file|listen_port|lan_network|geoip_url|geosite_url|geo_auto|geo_auto_freq|clash_api_enabled|clash_api_port|clash_api_secret)=/ { next }
		/^honk\.main\./ { bad=1; next }
		/^honk\.[A-Za-z0-9_.-]+=/ { bad=1; next }
		END { exit (bad || main != 1) }
	' || return 1
	get_uci() { uci_run -q get "honk.main.$1" 2>/dev/null; }
	u_enabled=$(get_uci enabled) || return 1
	u_boot=$(get_uci boot_enabled) || return 1
	u_initialized=$(get_uci initialized) || return 1
	u_config_mode=$(get_uci config_mode 2>/dev/null || printf managed)
	u_config=$(get_uci config_file) || return 1
	u_port=$(get_uci listen_port) || return 1
	u_network=$(get_uci lan_network) || return 1
	u_clash_enabled=$(get_uci clash_api_enabled 2>/dev/null || printf 0)
	u_clash_port=$(get_uci clash_api_port 2>/dev/null || printf 9090)
	u_clash_secret=$(get_uci clash_api_secret 2>/dev/null || true)
	u_geo_auto=$(get_uci geo_auto 2>/dev/null || printf 0)
	u_geo_auto_freq=$(get_uci geo_auto_freq 2>/dev/null || printf daily)
	case "$u_enabled:$u_boot:$u_initialized" in 0:0:0|0:0:1|0:1:0|0:1:1|1:0:0|1:0:1|1:1:0|1:1:1) ;; *) return 1 ;; esac
	case "$u_config_mode" in managed|manual) ;; *) return 1 ;; esac
	case "$u_geo_auto:$u_geo_auto_freq" in 0:daily|0:weekly|1:daily|1:weekly) ;; *) return 1 ;; esac
	[ "$u_config" = /etc/honk/config.dae ] || return 1
	case "$u_port" in ''|*[!0-9]*) return 1 ;; esac
	[ "$u_port" -ge 1024 ] && [ "$u_port" -le 65535 ] || return 1
	case "$u_network" in ''|*[!A-Za-z0-9_.-]*) return 1 ;; esac
	case "$u_clash_enabled" in 0|1) ;; *) return 1 ;; esac
	case "$u_clash_port" in ''|*[!0-9]*) return 1 ;; esac
	[ "$u_clash_port" -ge 1024 ] && [ "$u_clash_port" -le 65535 ] || return 1
	if [ "$u_clash_enabled" = 1 ]; then
		[ "$u_initialized" = 1 ] && [ "$u_clash_port" != "$u_port" ] || return 1
		case "$u_clash_secret" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac
		[ "${#u_clash_secret}" -ge 6 ] && [ "${#u_clash_secret}" -le 128 ] || return 1
	fi
}

check_sqlite() {
	check_db=$1
	[ ! -L "$check_db" ] && [ -f "$check_db" ] || return 1
	command -v sqlite3 >/dev/null 2>&1 || return 1
	check_result=$(sqlite3 "$check_db" 'PRAGMA quick_check;' 2>/dev/null) || return 1
	[ "$check_result" = ok ]
}

checkpoint_sqlite() {
	[ -e "$HONK_STATE" ] || return 0
	check_sqlite "$HONK_STATE" || return 1
	checkpoint_result=$(sqlite3 "$HONK_STATE" 'PRAGMA wal_checkpoint(TRUNCATE);' 2>/dev/null) || return 1
	case "$checkpoint_result" in
		0\|[0-9]*\|[0-9]*) ;;
		*) return 1 ;;
	esac
	checkpoint_busy=${checkpoint_result%%|*}
	checkpoint_rest=${checkpoint_result#*|}
	checkpoint_log=${checkpoint_rest%%|*}
	checkpoint_done=${checkpoint_rest#*|}
	case "$checkpoint_log:$checkpoint_done" in *[!0-9:]*|:*|*:) return 1 ;; esac
	[ "$checkpoint_busy" = 0 ] && [ "$checkpoint_log" = "$checkpoint_done" ] || return 1
	for sidecar in "$HONK_STATE-wal" "$HONK_STATE-shm"; do
		[ ! -L "$sidecar" ] || return 1
		if [ -e "$sidecar" ]; then
			[ -f "$sidecar" ] || return 1
			[ "$(size_of "$sidecar")" -eq 0 ] || [ "$sidecar" = "$HONK_STATE-shm" ] || return 1
			rm -f "$sidecar" || return 1
		fi
	done
	[ ! -e "$HONK_STATE-wal" ] && [ ! -e "$HONK_STATE-shm" ]
}

is_excluded() {
	case "$1" in
		*/logs/*|logs/*|*/log/*|log/*|*.log|*.tmp|*.pid|*.lock|*/.lock|*/honk.db-wal|*/honk.db-shm|*/honk.db-journal)
			return 0 ;;
		*) return 1 ;;
	esac
}

collect_tree() {
	collect_root=$1
	collect_out=$2
	[ -d "$collect_root" ] && [ ! -L "$collect_root" ] || return 1
	if find "$collect_root" -type l -print 2>/dev/null | grep -q .; then return 1; fi
	if find "$collect_root" ! -type f ! -type d -print 2>/dev/null | grep -q .; then return 1; fi
	: > "$collect_out" || return 1
	(
		cd "$collect_root" || exit 1
		find . -type f -print
	) > "$collect_out.raw" || return 1
	: > "$collect_out"
	collect_count=0
	collect_total=0
	while IFS= read -r collect_path; do
		collect_path=${collect_path#./}
		is_excluded "$collect_path" && continue
		safe_relpath "$collect_path" || exit 1
		[ -f "$collect_root/$collect_path" ] && [ ! -L "$collect_root/$collect_path" ] || return 1
		collect_size=$(size_of "$collect_root/$collect_path") || return 1
		[ "$collect_size" -le "$MAX_FILE" ] || return 1
		collect_count=$((collect_count + 1))
		collect_total=$((collect_total + collect_size))
		[ "$collect_count" -lt "$MAX_FILES" ] && [ "$collect_total" -le $((MAX_EXPANDED - 1048576)) ] || return 1
		printf '%s\n' "$collect_path" >> "$collect_out" || exit 1
	done < "$collect_out.raw" || return 1
	[ -f "$collect_root/config.dae" ] && [ -f "$collect_root/system.dae" ] || return 1
	return 0
}

validate_config_tree() {
	config_root=$1
	expected_device=$2
	expected_ip=$3
	expected_port=$4
	expected_initialized=$5
	main=$config_root/config.dae
	system=$config_root/system.dae
	[ -f "$main" ] && [ ! -L "$main" ] && [ -f "$system" ] && [ ! -L "$system" ] || return 1
	if [ "$u_config_mode" = manual ]; then
		"$HONK_CORE" config validate --config "$main" >/dev/null 2>&1 || return 2
		find "$config_root" -type l -print 2>/dev/null | grep -q . && return 2
		find "$config_root" ! -type f ! -type d -print 2>/dev/null | grep -q . && return 2
		return 0
	fi
	validate_system_schema "$system" "$expected_device" "$expected_ip" "$expected_port" "$expected_initialized" || return 2
	# `validate_candidate` asks honk-core's own parser to resolve every include
	# and captures the complete source tree inside its private shadow. Keep this
	# shell check limited to filesystem entry types and managed system fields.
	find "$config_root" -type l -print 2>/dev/null | grep -q . && return 2
	find "$config_root" ! -type f ! -type d -print 2>/dev/null | grep -q . && return 2
	return 0
}

validate_system_schema() {
	trusted_system=$1
	expected_device=$2
	expected_ip=$3
	expected_port=$4
	expected_initialized=$5
	lan_iface=$(sed -n "s/^    lan_interface: '\\([^']*\\)'$/\\1/p" "$trusted_system")
	listen_addr=$(sed -n "s/^        listen: '\\([^']*\\)'$/\\1/p" "$trusted_system")
	case "$lan_iface" in ''|*[!A-Za-z0-9_.-]*) return 1 ;; esac
	case "$listen_addr" in ''|*[!0-9.:]*) return 1 ;; esac
	case "$listen_addr" in *.*.*.*:*) ;; *) return 1 ;; esac
	listen_host=${listen_addr%:*}
	listen_port=${listen_addr##*:}
	case "$listen_host" in ''|*[!0-9.]*) return 1 ;; esac
	case "$listen_port" in ''|*[!0-9]*) return 1 ;; esac
	[ "$listen_port" -ge 1024 ] && [ "$listen_port" -le 65535 ] || return 1
	[ "$lan_iface" = "$expected_device" ] && [ "$listen_port" = "$expected_port" ] || return 1
	[ "$listen_host" = "$expected_ip" ] || [ "$listen_host" = 127.0.0.1 ] || return 1
	store_subscribe=$(sed -n 's/^    store_subscribe: \(true\|false\)$/\1/p' "$trusted_system")
	case "$store_subscribe" in true|false) ;; *) return 1 ;; esac
	cat > "$temp_dir/system.expected" <<EOF
global {
    wan_interface: auto
    lan_interface: '$lan_iface'
    log_level: info
    dial_mode: domain
    allow_insecure: false
    auto_config_kernel_parameter: true
    data_dir: '/etc/honk'
    store_subscribe: $store_subscribe
    nfqueue_enable: true
}

experimental {
    native_api {
        enabled: true
        listen: '$listen_addr'
        password_auth: true
        allow_anonymous_loopback: false
        config_write: true
        ui: '/usr/share/doona'
    }
EOF
	if [ "$u_clash_enabled" = 1 ]; then
		cat >> "$temp_dir/system.expected" <<EOF
    clash_api {
        external_controller: '$listen_host:$u_clash_port'
        external_ui: '/usr/share/honk/zashboard'
        secret: '$u_clash_secret'
        default_mode: Rule
    }
EOF
	fi
	cat >> "$temp_dir/system.expected" <<EOF
}
EOF
	cmp -s "$trusted_system" "$temp_dir/system.expected"
}

check_tar_members() {
	archive=$1
	member_list=$2
	[ "$(size_of "$archive")" -le "$MAX_COMPRESSED" ] || return 1
	ulimit -f 262144 2>/dev/null || return 1
	tar -tvzf "$archive" > "$member_list" 2>/dev/null || return 1
	awk '
		{
			if (NF < 2 || substr($1,1,1) != "-") exit 1
			name=$NF
			if (name !~ /^[A-Za-z0-9_.\/-]+$/ || name ~ /^\// || name ~ /(^|\/)\.\.(\/|$)/ || name ~ /(^|\/)\.($|\/)/ || name ~ /\/\//) exit 1
			seen[name]++
			if (seen[name] > 1) exit 1
			count++
			if (count > 513) exit 1
			print name
		}
		END { if (!count) exit 1 }
	' "$member_list" > "$member_list.names" || return 1
	grep -qx 'manifest.tsv' "$member_list.names" || return 1
}

extract_archive() {
	archive=$1
	stage=$2
	member_listing=$temp_dir/members.verbose
	check_tar_members "$archive" "$member_listing" || return 1
	mkdir -p "$stage" || return 1
	: > "$stage/manifest.tsv" || return 1
	ulimit -f 262144 2>/dev/null || return 1
	tar -xOzf "$archive" manifest.tsv > "$stage/manifest.tsv" 2>/dev/null || return 1
	[ "$(size_of "$stage/manifest.tsv")" -le 1048576 ] || return 1
	awk -F '\t' '
		NR==1 { if (NF!=2 || $1!="format" || $2!="1") exit 1; next }
		NR==2 { if (NF!=2 || $1!="core_commit" || length($2)!=40 || $2 !~ /^[0-9a-f]+$/) exit 1; next }
		NR==3 { if (NF!=2 || $1!="state" || ($2!="present" && $2!="absent")) exit 1; next }
		$1=="file" {
			if (NF!=4 || $2 !~ /^[A-Za-z0-9_.\/-]+$/ || $2 ~ /^\// || $2 ~ /(^|\/)\.\.(\/|$)/ || $2 ~ /(^|\/)\.($|\/)/ || $2 ~ /\/\//) exit 1
			if ($3 !~ /^[0-9]+$/ || $3 > 67108864 || $4 !~ /^[0-9a-f]{64}$/) exit 1
			if (seen[$2]++) exit 1
			total += $3; count++; next
		}
		{ exit 1 }
		END { if (NR<4 || count<3 || count>512 || total>133169152) exit 1 }
	' "$stage/manifest.tsv" || return 1
	manifest_commit=$(sed -n '2s/^core_commit\t//p' "$stage/manifest.tsv")
	[ -n "$manifest_commit" ] && [ "$manifest_commit" = "$(core_commit)" ] || return 2
	archive_state=$(sed -n '3s/^state\t//p' "$stage/manifest.tsv")
	while IFS="$(printf '\t')" read -r kind relpath expected_size expected_sha; do
		[ "$kind" = file ] || continue
		safe_relpath "$relpath" || return 1
		is_excluded "$relpath" && return 1
		grep -qx "$relpath" "$member_listing.names" || return 1
		case "$relpath" in uci/honk|etc/honk/*) ;; *) return 1 ;; esac
		mkdir -p "$stage/$(dirname "$relpath")" || return 1
		: > "$stage/$relpath" || return 1
		tar -xOzf "$archive" "$relpath" > "$stage/$relpath" 2>/dev/null || return 1
		[ "$(size_of "$stage/$relpath")" -eq "$expected_size" ] || return 1
		[ "$(sha_of "$stage/$relpath")" = "$expected_sha" ] || return 1
	done < "$stage/manifest.tsv"
	# Every tar member must be declared exactly once in the manifest.
	awk -F '\t' '$1=="file" {print $2}' "$stage/manifest.tsv" | sort > "$member_listing.expected"
	grep -v '^manifest.tsv$' "$member_listing.names" | sort > "$member_listing.actual"
	cmp -s "$member_listing.expected" "$member_listing.actual" || return 1
	[ -f "$stage/etc/honk/config.dae" ] && [ -f "$stage/etc/honk/system.dae" ] && [ -f "$stage/uci/honk" ] || return 1
	if [ "$archive_state" = present ]; then
		[ -f "$stage/etc/honk/state/honk.db" ] || return 1
	else
		[ ! -e "$stage/etc/honk/state/honk.db" ] || return 1
	fi
}

parse_uci_file() {
	uci_dir=$1
	mkdir -p "$temp_dir/uci-tmp" || return 1
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" -q export honk >/dev/null 2>&1 || return 1
	load_uci_values uci "$uci_dir" || return 1
	[ "$u_initialized" = 1 ] || [ ! -f "$restore_stage/etc/honk/state/honk.db" ] || return 1
}

# 清订阅、节点、策略、历史与缓存，保留管理员记录和 geo 设置。
purge_business_state() {
	purge_db=$1
	[ -f "$purge_db" ] && [ ! -L "$purge_db" ] || return 0
	command -v sqlite3 >/dev/null 2>&1 || return 1
	purge_sql='BEGIN IMMEDIATE;'
	for purge_table in head revision subscription_body selector delay_sample dns_answer clash_state listener_secret; do
		purge_exists=$(sqlite3 "$purge_db" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='$purge_table';" 2>/dev/null) || return 1
		[ "$purge_exists" = 1 ] || continue
		purge_sql="$purge_sql DELETE FROM $purge_table;"
	done
	sqlite3 "$purge_db" "$purge_sql COMMIT; PRAGMA wal_checkpoint(TRUNCATE); VACUUM;" >/dev/null 2>&1 || return 1
	check_sqlite "$purge_db"
}

archive_sqlite_check() {
	db=$1
	[ -f "$db" ] || return 0
	check_sqlite "$db" || return 1
}

unused_loopback_port() {
	command -v netstat >/dev/null 2>&1 || command -v ss >/dev/null 2>&1 || return 1
	for port_candidate in 39127 39129 39131 39133 39135 39137 39139 39141; do
		if command -v netstat >/dev/null 2>&1; then
			port_listeners=$(netstat -lnt 2>/dev/null)
		else
			port_listeners=$(ss -lnt 2>/dev/null)
		fi
		if ! printf '%s\n' "$port_listeners" | awk -v p="$port_candidate" '$4 ~ (":" p "$") {found=1} END {exit !found}'; then
			printf '%s\n' "$port_candidate"
			return 0
		fi
	done
	return 1
}

rewrite_shadow_system() {
	shadow_system=$1
	shadow_data=$2
	shadow_port=$3
	cat > "$shadow_system.new" <<EOF
global {
    wan_interface: auto
    lan_interface: ''
    log_level: info
    dial_mode: domain
    allow_insecure: false
    auto_config_kernel_parameter: false
    data_dir: '$shadow_data'
    store_subscribe: false
    nfqueue_enable: false
}

experimental {
    native_api {
        enabled: true
        listen: '127.0.0.1:$shadow_port'
        password_auth: true
        allow_anonymous_loopback: false
        config_write: true
        ui: '/usr/share/doona'
    }
}
EOF
	mv "$shadow_system.new" "$shadow_system"
}

write_live_system() {
	live_system=$1
	live_device=$2
	live_ip=$3
	live_port=$4
	live_initialized=$5
	if [ "$live_initialized" = 1 ]; then live_host=$live_ip; else live_host=127.0.0.1; fi
	cat > "$live_system" <<EOF
global {
    wan_interface: auto
    lan_interface: '$live_device'
    log_level: info
    dial_mode: domain
    allow_insecure: false
    auto_config_kernel_parameter: true
    data_dir: '/etc/honk'
    store_subscribe: true
    nfqueue_enable: true
}

experimental {
    native_api {
        enabled: true
        listen: '$live_host:$live_port'
        password_auth: true
        allow_anonymous_loopback: false
        config_write: true
        ui: '/usr/share/doona'
    }
EOF
	if [ "$u_clash_enabled" = 1 ]; then
		cat >> "$live_system" <<EOF
    clash_api {
        external_controller: '$live_host:$u_clash_port'
        external_ui: '/usr/share/honk/zashboard'
        secret: '$u_clash_secret'
        default_mode: Rule
    }
EOF
	fi
	cat >> "$live_system" <<EOF
}
EOF
}

mock_identity_ok() {
	[ -n "$mock_pid" ] && [ -r "/proc/$mock_pid/cmdline" ] || return 1
	mock_identity=$(tr '\000' ' ' < "/proc/$mock_pid/cmdline" 2>/dev/null) || return 1
	case "$mock_identity" in *"$mock_config"*--mock-ebpf*) ;; *) return 1 ;; esac
	[ "$(readlink -f "/proc/$mock_pid/exe" 2>/dev/null)" = "$HONK_CORE" ]
}

validate_candidate() {
	candidate=$1
	uci_dir=$2
	state=$3
	config_tree=$candidate/etc/honk
	mkdir -p "$temp_dir/uci-tmp" || return 1
	load_uci_values uci "$uci_dir" || return 1
	if [ "$u_config_mode" = manual ]; then
		validate_config_tree "$config_tree" '' '' "$u_port" "$u_initialized" || return 2
		if [ "$state" = present ] || { [ "$state" = preview ] && { [ -e "$config_tree/state/honk.db" ] || [ -L "$config_tree/state/honk.db" ]; }; }; then
			archive_sqlite_check "$config_tree/state/honk.db" || return 1
		fi
		if [ -f "$config_tree/state/honk.db" ] && [ ! -L "$config_tree/state/honk.db" ]; then
			restore_initialized=1
		else
			restore_initialized=0
		fi
		return 0
	fi
	. /lib/functions/network.sh || return 1
	candidate_device=
	candidate_ip=
	network_get_device candidate_device "$u_network" || return 1
	network_get_ipaddr candidate_ip "$u_network" || return 1
	validate_config_tree "$config_tree" "$candidate_device" "$candidate_ip" "$u_port" "$u_initialized" || return 2
	if [ "$state" = present ] || { [ "$state" = preview ] && { [ -e "$config_tree/state/honk.db" ] || [ -L "$config_tree/state/honk.db" ]; }; }; then
		archive_sqlite_check "$config_tree/state/honk.db" || return 1
	fi
	mkdir -p "$temp_dir/shadow/etc" "$temp_dir/shadow-data" || return 1
	chmod 0700 "$temp_dir/shadow" "$temp_dir/shadow/etc" "$temp_dir/shadow-data" || return 1
	cp -pR "$config_tree" "$temp_dir/shadow/etc/honk" || return 1
	find "$temp_dir/shadow" -type d -exec chmod 0700 {} + || return 1
	find "$temp_dir/shadow/etc/honk" -type f -exec chmod 0600 {} + || return 1
	find "$temp_dir/shadow/etc/honk" -type l -print 2>/dev/null | grep -q . && return 2
	find "$temp_dir/shadow/etc/honk" ! -type f ! -type d -print 2>/dev/null | grep -q . && return 2
	shadow_port=$(unused_loopback_port) || return 1
	rewrite_shadow_system "$temp_dir/shadow/etc/honk/system.dae" "$temp_dir/shadow-data" "$shadow_port" || return 2
	chmod 0600 "$temp_dir/shadow/etc/honk"/*.dae 2>/dev/null || true
	if [ "$state" = present ] || { [ "$state" = preview ] && [ -f "$config_tree/state/honk.db" ]; }; then
		mkdir -p "$temp_dir/shadow-data/state" || return 1
		cp "$config_tree/state/honk.db" "$temp_dir/shadow-data/state/honk.db" || return 1
		chmod 0600 "$temp_dir/shadow-data/state/honk.db" || return 1
	fi
	mock_config=$temp_dir/shadow/etc/honk/config.dae
	mock_log=$temp_dir/mock.log
	response_file=$temp_dir/discovery.json
	DAE_LOCATION_ASSET=/usr/share/v2ray "$HONK_CORE" --config "$mock_config" --mock-ebpf > "$mock_log" 2>&1 &
	mock_pid=$!
	mock_ready=0
	attempt=0
	while [ "$attempt" -lt 15 ]; do
		if ! kill -0 "$mock_pid" 2>/dev/null; then return 1; fi
		if curl -fsS --noproxy '*' --connect-timeout 1 --max-time 2 "http://127.0.0.1:$shadow_port/api" -o "$response_file" 2>/dev/null; then
			mock_identity_ok || return 1
			mock_ready=1
			break
		fi
		sleep 1
		attempt=$((attempt + 1))
	done
	[ "$mock_ready" = 1 ] || return 1
	setup_required=$(jsonfilter -i "$response_file" -e '@.auth.setup_required' 2>/dev/null)
	case "$setup_required" in true) restore_initialized=0 ;; false) restore_initialized=1 ;; *) return 1 ;; esac
	[ "$state" != absent ] || [ "$restore_initialized" = 0 ] || return 1
	mock_identity_ok || return 1
	stop_mock || return 1
	return 0
}

make_manifest() {
	root=$1
	state=$2
	manifest=$3
	commit=$(core_commit)
	case "$commit" in [0-9a-f][0-9a-f]*) [ "${#commit}" -eq 40 ] || return 1 ;; *) return 1 ;; esac
	{
		printf 'format\t1\ncore_commit\t%s\nstate\t%s\n' "$commit" "$state"
		while IFS= read -r relpath; do
			[ -n "$relpath" ] || continue
			file=$root/$relpath
			file_size=$(size_of "$file") || return 1
			file_sha=$(sha_of "$file") || return 1
			[ "$file_size" -le "$MAX_FILE" ] || return 1
			printf 'file\t%s\t%s\t%s\n' "$relpath" "$file_size" "$file_sha"
		done < "$temp_dir/files.list"
	} > "$manifest" || return 1
	[ "$(size_of "$manifest")" -le 1048576 ]
}

backup() {
	if [ -L "$BACKUP" ] || { [ -e "$BACKUP" ] && [ ! -f "$BACKUP" ]; }; then error unsafe_backup_path; return 1; fi
	if foreign_core_running; then error unmanaged_core_running; return 1; fi
	if managed_core_pid >/dev/null 2>&1; then old_running=1; fi
	if ! acquire_lock; then error "$lock_error"; return 1; fi
	foreign_core_running && { error unmanaged_core_running; return 1; }
	if [ "$old_running" = 1 ]; then managed_core_pid >/dev/null 2>&1 || { error service_state_changed; return 1; }
	else managed_core_pid >/dev/null 2>&1 && { error service_state_changed; return 1; }; fi
	temp_dir=$(mktemp -d /tmp/honk-maint.XXXXXX) || { error temporary_storage_unavailable; return 1; }
	chmod 0700 "$temp_dir" || { error temporary_storage_unavailable; return 1; }
	load_uci_values || { error uci_validation_failed; return 1; }
	old_enabled=$u_enabled
	old_boot=$u_boot
	old_initialized=$u_initialized
	uci export honk > "$temp_dir/old-uci" 2>/dev/null || { error uci_export_failed; return 1; }
	if [ "$old_running" = 1 ]; then
		capture_boot_links || { error boot_link_state_unavailable; return 1; }
		journal_create backup || { error transaction_journal_create_failed; return 1; }
		service_stopped=1
		stop_managed || { backup_abort service_stop_failed; return 1; }
		journal_write stopped || { backup_abort transaction_journal_write_failed; return 1; }
	fi
	uci export honk > "$temp_dir/uci.honk" 2>/dev/null || { backup_abort uci_export_failed; return 1; }
	if [ -f "$HONK_STATE" ]; then
		checkpoint_sqlite || { backup_abort sqlite_checkpoint_failed; return 1; }
		state=present
		[ "$u_initialized" = 1 ] || { backup_abort state_without_initialized_profile; return 1; }
	else
		state=absent
		[ "$u_initialized" = 0 ] || { backup_abort initialized_state_missing; return 1; }
	fi
	mkdir -p "$temp_dir/archive/etc" "$temp_dir/archive/uci" || { backup_abort temporary_storage_unavailable; return 1; }
	collect_tree "$HONK_ROOT" "$temp_dir/files.list" || { backup_abort unsupported_honk_tree_entry; return 1; }
	while IFS= read -r relpath; do
		[ -n "$relpath" ] || continue
		dest=$temp_dir/archive/etc/honk/$relpath
		mkdir -p "$(dirname "$dest")" || { backup_abort snapshot_failed; return 1; }
		cp "$HONK_ROOT/$relpath" "$dest" || { backup_abort snapshot_failed; return 1; }
		chmod 0600 "$dest" || { backup_abort snapshot_failed; return 1; }
	done < "$temp_dir/files.list"
	cp "$temp_dir/uci.honk" "$temp_dir/archive/uci/honk" || { backup_abort uci_snapshot_failed; return 1; }
	chmod 0600 "$temp_dir/archive/uci/honk" || { backup_abort uci_snapshot_failed; return 1; }
	if [ "$state" = present ]; then
		check_sqlite "$temp_dir/archive/etc/honk/state/honk.db" || { backup_abort sqlite_check_failed; return 1; }
	fi
	validate_candidate "$temp_dir/archive" "$temp_dir/archive/uci" "$state"
	validate_rc=$?
	if [ "$validate_rc" -ne 0 ]; then
		if ! restore_running; then
			[ "$validate_rc" = 2 ] && error unsupported_candidate_config_runtime_restore_failed || error candidate_validation_failed_runtime_restore_failed
		else
			[ "$validate_rc" = 2 ] && error unsupported_candidate_config || error candidate_validation_failed
		fi
		return 1
	fi
	[ "$u_initialized" = "$restore_initialized" ] || { backup_abort initialized_state_mismatch; return 1; }
	(
		cd "$temp_dir/archive" || exit 1
		find etc uci -type f -print | sort > "$temp_dir/files.list"
	)
	make_manifest "$temp_dir/archive" "$state" "$temp_dir/archive/manifest.tsv" || { backup_abort manifest_create_failed; return 1; }
	(
		cd "$temp_dir/archive" || exit 1
		{ printf '%s\n' manifest.tsv; cat "$temp_dir/files.list"; } > "$temp_dir/tar.list"
		ulimit -f 65536 2>/dev/null || exit 1
		tar -czf "$temp_dir/backup.tar.gz" -T "$temp_dir/tar.list"
	) || { backup_abort archive_create_failed; return 1; }
	[ "$(size_of "$temp_dir/backup.tar.gz")" -le "$MAX_COMPRESSED" ] || { backup_abort archive_too_large; return 1; }
	check_tar_members "$temp_dir/backup.tar.gz" "$temp_dir/output-members" || { backup_abort archive_self_validation_failed; return 1; }
	if [ -L "$BACKUP" ]; then backup_abort unsafe_backup_path; return 1; fi
	mv -f "$temp_dir/backup.tar.gz" "$BACKUP" || { backup_abort backup_write_failed; return 1; }
	chmod 0600 "$BACKUP" || { backup_abort backup_permissions_failed; return 1; }
	if [ "$journal_active" = 1 ]; then
		journal_write committed || { backup_abort transaction_journal_write_failed; return 1; }
		rm -rf "$TXN_DIR" || { error backup_created_journal_cleanup_failed; return 1; }
		journal_active=0
	fi
	if ! restore_running; then backup_abort backup_created_service_restart_failed; return 1; fi
	json_result true "$BACKUP" backup_created
}

restore() {
	check_root_file "$RESTORE" || { error unsafe_restore_path; return 1; }
	if foreign_core_running; then error unmanaged_core_running; return 1; fi
	if managed_core_pid >/dev/null 2>&1; then old_running=1; fi
	if ! acquire_lock; then error "$lock_error"; return 1; fi
	foreign_core_running && { error unmanaged_core_running; return 1; }
	if [ "$old_running" = 1 ]; then managed_core_pid >/dev/null 2>&1 || { error service_state_changed; return 1; }
	else managed_core_pid >/dev/null 2>&1 && { error service_state_changed; return 1; }; fi
	temp_dir=$(mktemp -d /tmp/honk-maint.XXXXXX) || { error temporary_storage_unavailable; return 1; }
	chmod 0700 "$temp_dir" || { error temporary_storage_unavailable; return 1; }
	archive_hash=$(sha_of "$RESTORE")
	[ -n "$archive_hash" ] || { error archive_read_failed; return 1; }
	restore_stage=$temp_dir/extracted
	extract_archive "$RESTORE" "$restore_stage"
	extract_rc=$?
	[ "$extract_rc" = 0 ] || { [ "$extract_rc" = 2 ] && error incompatible_core_version || error invalid_archive; return 1; }
	uci_dir=$restore_stage/uci
	parse_uci_file "$uci_dir" || { error invalid_uci_config; return 1; }
	archive_state=$(sed -n '3s/^state\t//p' "$restore_stage/manifest.tsv")
	if [ "$archive_state" = present ]; then
		archive_sqlite_check "$restore_stage/etc/honk/state/honk.db" || { error invalid_sqlite_state; return 1; }
	fi
	load_uci_values || { error current_uci_invalid; return 1; }
	old_enabled=$u_enabled
	old_boot=$u_boot
	old_initialized=$u_initialized
	uci export honk > "$temp_dir/old-uci" 2>/dev/null || { error current_uci_snapshot_failed; return 1; }
	capture_boot_links || { error boot_link_state_unavailable; return 1; }
	if [ "$archive_state" = absent ] && { [ "$old_enabled" = 1 ] || [ "$old_boot" = 1 ] || [ "$old_running" = 1 ] || [ "$old_start_link" != - ]; }; then
		error empty_archive_would_clear_active_state
		return 1
	fi
	validate_candidate "$restore_stage" "$uci_dir" "$archive_state"
	validate_rc=$?
	if [ "$validate_rc" -ne 0 ]; then
		[ "$validate_rc" = 2 ] && error unsupported_candidate_config || error candidate_validation_failed
		return 1
	fi
	[ "$old_running" != 1 ] || [ "$restore_initialized" = 1 ] || { error running_service_requires_initialized_restore; return 1; }
	[ "$(sha_of "$RESTORE")" = "$archive_hash" ] || { error restore_archive_changed; return 1; }
	if [ "$u_config_mode" = managed ]; then
		write_live_system "$restore_stage/etc/honk/system.dae" "$candidate_device" "$candidate_ip" "$u_port" "$restore_initialized" || { error system_config_render_failed; return 1; }
		chmod 0600 "$restore_stage/etc/honk/system.dae" || { error system_config_render_failed; return 1; }
	fi
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" set "honk.main.enabled=$old_enabled" || { error restore_profile_stage_failed; return 1; }
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" set "honk.main.boot_enabled=$old_boot" || { error restore_profile_stage_failed; return 1; }
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" set "honk.main.initialized=$restore_initialized" || { error restore_profile_stage_failed; return 1; }
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" set honk.main.config_file=/etc/honk/config.dae || { error restore_profile_stage_failed; return 1; }
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" commit honk || { error restore_profile_stage_failed; return 1; }
	load_uci_values uci "$uci_dir" || { error restore_profile_stage_failed; return 1; }
	[ "$u_enabled:$u_boot:$u_initialized" = "$old_enabled:$old_boot:$restore_initialized" ] || { error restore_profile_stage_failed; return 1; }
	uci -c "$uci_dir" -t "$temp_dir/uci-tmp" export honk > "$temp_dir/new-uci" 2>/dev/null || { error restore_profile_stage_failed; return 1; }
	if [ -d "$HONK_ROOT" ] && [ ! -L "$HONK_ROOT" ]; then :; else error current_tree_unavailable; return 1; fi
	journal_create restore || { error transaction_journal_create_failed; return 1; }
	mkdir "$TXN_DIR/new-tree" || { restore_abort restore_stage_failed; return 1; }
	cp -pR "$restore_stage/etc/honk/." "$TXN_DIR/new-tree/" || { restore_abort restore_stage_failed; return 1; }
	find "$TXN_DIR/new-tree" -type d -exec chmod 0700 {} \; 2>/dev/null
	find "$TXN_DIR/new-tree" -type f -exec chmod 0600 {} \; 2>/dev/null
	chmod 0600 "$TXN_DIR/new-tree/system.dae" || { restore_abort restore_stage_failed; return 1; }
	if [ "$old_running" = 1 ]; then
		service_stopped=1
		stop_managed || { restore_abort service_stop_failed; return 1; }
	fi
	journal_write stopped || { restore_abort transaction_journal_write_failed; return 1; }
	if foreign_core_running; then restore_abort unmanaged_core_running; return 1; fi
	old_tree_path=$TXN_DIR/old-tree
	new_tree_path=$TXN_DIR/new-tree
	if ! mv "$HONK_ROOT" "$old_tree_path"; then restore_abort tree_swap_failed; return 1; fi
	swap_started=1
	journal_write old_moved || { restore_abort transaction_journal_write_failed; return 1; }
	if ! mv "$new_tree_path" "$HONK_ROOT"; then restore_abort tree_swap_failed; return 1; fi
	journal_write new_installed || { restore_abort transaction_journal_write_failed; return 1; }
	if ! uci import honk < "$temp_dir/new-uci" || ! uci commit honk; then
		apply_failed=1
	else
		apply_failed=0
	fi
	if [ "$apply_failed" = 0 ]; then
		load_uci_values || apply_failed=1
		[ "$apply_failed" = 1 ] || [ "$u_enabled:$u_boot:$u_initialized" = "$old_enabled:$old_boot:$restore_initialized" ] || apply_failed=1
		if [ "$apply_failed" = 0 ] && [ "$old_running" = 1 ]; then
			issue_capability candidate_health_start || apply_failed=1
		fi
	fi
	if [ "$apply_failed" = 1 ]; then
		restore_abort restore_failed
		return 1
	fi
	journal_write service_started || { restore_abort transaction_journal_write_failed; return 1; }
	journal_write committed || { restore_abort transaction_journal_write_failed; return 1; }
	rm -rf "$TXN_DIR" || { error restore_succeeded_snapshot_cleanup_pending; return 1; }
	journal_active=0
	swap_started=0
	service_stopped=0
	json_result true "" restored
}

reset_data() {
	if foreign_core_running; then error unmanaged_core_running; return 1; fi
	if managed_core_pid >/dev/null 2>&1; then old_running=1; fi
	if ! acquire_lock; then error "$lock_error"; return 1; fi
	foreign_core_running && { error unmanaged_core_running; return 1; }
	if [ "$old_running" = 1 ]; then managed_core_pid >/dev/null 2>&1 || { error service_state_changed; return 1; }
	else managed_core_pid >/dev/null 2>&1 && { error service_state_changed; return 1; }; fi
	temp_dir=$(mktemp -d /tmp/honk-maint.XXXXXX) || { error temporary_storage_unavailable; return 1; }
	chmod 0700 "$temp_dir" || { error temporary_storage_unavailable; return 1; }
	load_uci_values || { error current_uci_invalid; return 1; }
	old_enabled=$u_enabled
	old_boot=$u_boot
	old_initialized=$u_initialized
	uci export honk > "$temp_dir/old-uci" 2>/dev/null || { error current_uci_snapshot_failed; return 1; }
	capture_boot_links || { error boot_link_state_unavailable; return 1; }
	[ -d "$HONK_ROOT" ] && [ ! -L "$HONK_ROOT" ] || { error current_tree_unavailable; return 1; }
	reset_stage=$temp_dir/reset-stage
	reset_uci=$temp_dir/reset-uci
	mkdir -p "$reset_stage/etc/honk" "$reset_uci" || { error temporary_storage_unavailable; return 1; }
	[ -f /usr/share/honk/default-config.dae ] && [ ! -L /usr/share/honk/default-config.dae ] || { error default_config_unavailable; return 1; }
	cp /usr/share/honk/default-config.dae "$reset_stage/etc/honk/config.dae" || { error reset_stage_failed; return 1; }
	chmod 0600 "$reset_stage/etc/honk/config.dae" || { error reset_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" import honk < "$temp_dir/old-uci" || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.enabled=0 || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.boot_enabled=0 || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.config_mode=managed || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.listen_port=9527 || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.lan_network=lan || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.clash_api_enabled=0 || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.clash_api_port=9090 || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" set honk.main.clash_api_secret= || { error reset_profile_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" commit honk || { error reset_profile_stage_failed; return 1; }
	load_uci_values uci "$reset_uci" || { error reset_profile_stage_failed; return 1; }
	. /lib/functions/network.sh || { error lan_network_unavailable; return 1; }
	reset_device=
	reset_ip=
	network_get_device reset_device "$u_network" || { error lan_network_unavailable; return 1; }
	network_get_ipaddr reset_ip "$u_network" || { error lan_network_unavailable; return 1; }
	write_live_system "$reset_stage/etc/honk/system.dae" "$reset_device" "$reset_ip" "$u_port" "$u_initialized" || { error system_config_render_failed; return 1; }
	chmod 0600 "$reset_stage/etc/honk/system.dae" || { error system_config_render_failed; return 1; }
	reset_candidate=$temp_dir/reset-candidate
	mkdir -p "$reset_candidate/etc" || { error reset_stage_failed; return 1; }
	cp -pR "$reset_stage/etc/honk" "$reset_candidate/etc/honk" || { error reset_stage_failed; return 1; }
	uci -c "$reset_uci" -t "$temp_dir/uci-tmp" export honk > "$temp_dir/new-uci" 2>/dev/null || { error reset_profile_stage_failed; return 1; }
	validate_candidate "$reset_candidate" "$reset_uci" absent
	validate_rc=$?
	[ "$validate_rc" = 0 ] || { [ "$validate_rc" = 2 ] && error default_config_unsupported || error default_config_validation_failed; return 1; }
	journal_create reset || { error transaction_journal_create_failed; return 1; }
	if [ "$old_running" = 1 ]; then
		service_stopped=1
		stop_managed || { restore_abort service_stop_failed; return 1; }
	fi
	journal_write stopped || { restore_abort transaction_journal_write_failed; return 1; }
	foreign_core_running && { restore_abort unmanaged_core_running; return 1; }
	checkpoint_sqlite || { restore_abort sqlite_checkpoint_failed; return 1; }
	rm -rf "$reset_stage/etc/honk" || { restore_abort reset_stage_failed; return 1; }
	stage_reset_tree "$HONK_ROOT" "$reset_stage/etc/honk" "$reset_candidate/etc/honk/system.dae" /usr/share/honk/default-config.dae || { restore_abort reset_stage_failed; return 1; }
	purge_business_state "$reset_stage/etc/honk/state/honk.db" || { restore_abort state_reset_failed; return 1; }
	reset_archive_state=absent
	if [ -f "$reset_stage/etc/honk/state/honk.db" ]; then reset_archive_state=present; fi
	if [ "$reset_archive_state" = present ]; then archive_sqlite_check "$reset_stage/etc/honk/state/honk.db" || { restore_abort state_reset_validation_failed; return 1; }; fi
	rm -rf "$reset_candidate" || { restore_abort reset_stage_failed; return 1; }
	mkdir -p "$reset_candidate/etc" || { restore_abort reset_stage_failed; return 1; }
	cp -pR "$reset_stage/etc/honk" "$reset_candidate/etc/honk" || { restore_abort reset_stage_failed; return 1; }
	mkdir "$TXN_DIR/new-tree" || { restore_abort reset_stage_failed; return 1; }
	cp -pR "$reset_candidate/etc/honk/." "$TXN_DIR/new-tree/" || { restore_abort reset_stage_failed; return 1; }
	find "$TXN_DIR/new-tree" -type d -exec chmod 0700 {} \; 2>/dev/null
	find "$TXN_DIR/new-tree" -type f -exec chmod 0600 {} \; 2>/dev/null
	chmod 0600 "$TXN_DIR/new-tree/system.dae" || { restore_abort reset_stage_failed; return 1; }
	foreign_core_running && { restore_abort unmanaged_core_running; return 1; }
	old_tree_path=$TXN_DIR/old-tree
	new_tree_path=$TXN_DIR/new-tree
	mv "$HONK_ROOT" "$old_tree_path" || { restore_abort tree_swap_failed; return 1; }
	swap_started=1
	journal_write old_moved || { restore_abort transaction_journal_write_failed; return 1; }
	mv "$new_tree_path" "$HONK_ROOT" || { restore_abort tree_swap_failed; return 1; }
	journal_write new_installed || { restore_abort transaction_journal_write_failed; return 1; }
	uci import honk < "$temp_dir/new-uci" && uci commit honk || { restore_abort reset_failed; return 1; }
	load_uci_values || { restore_abort reset_failed; return 1; }
	[ "$u_enabled:$u_boot:$u_initialized:$u_network:$u_port" = "0:0:$old_initialized:lan:9527" ] || { restore_abort reset_failed; return 1; }
	disable_boot_links || { restore_abort boot_link_update_failed; return 1; }
	journal_write uci_applied || { restore_abort transaction_journal_write_failed; return 1; }
	journal_write committed || { restore_abort transaction_journal_write_failed; return 1; }
	rm -rf "$TXN_DIR" || { error reset_succeeded_snapshot_cleanup_pending; return 1; }
	journal_active=0
	swap_started=0
	service_stopped=0
	json_result true "" data_reset
}

stage_reset_tree() {
	stage_source=$1
	stage_target=$2
	stage_system=$3
	stage_default=$4
	[ -d "$stage_source" ] && [ ! -L "$stage_source" ] || return 1
	[ -f "$stage_system" ] && [ ! -L "$stage_system" ] || return 1
	[ -f "$stage_default" ] && [ ! -L "$stage_default" ] || return 1
	mkdir -p "$stage_target/state" || return 1
	cp "$stage_default" "$stage_target/config.dae" || return 1
	cp "$stage_system" "$stage_target/system.dae" || return 1
	chmod 0600 "$stage_target/config.dae" || return 1
	chmod 0600 "$stage_target/system.dae" || return 1
	chmod 0700 "$stage_target/state" || return 1
	if [ -e "$stage_source/state/honk.db" ] || [ -L "$stage_source/state/honk.db" ]; then
		[ -f "$stage_source/state/honk.db" ] && [ ! -L "$stage_source/state/honk.db" ] || return 1
		cp -p "$stage_source/state/honk.db" "$stage_target/state/honk.db" || return 1
		chmod 0600 "$stage_target/state/honk.db" || return 1
	fi
}

if [ "${HONK_MAINT_LIBRARY:-0}" = 1 ]; then
	trap - 0 HUP INT TERM
	return 0 2>/dev/null || exit 0
fi

case "$1" in
	backup) backup ;;
	restore) restore ;;
	reset) reset_data ;;
	recover) recover_action ;;
	*) error invalid_action ;;
esac
