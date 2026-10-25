#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
umask 077
. /usr/share/libubox/jshn.sh

JOBS=/tmp/honk-jobs
MAINT=/usr/share/honk/maintenance.sh

write_status() {
	status_state=$1
	status_phase=$2
	status_ok=$3
	status_message=$4
	status_tmp=$job_dir/status.new
	{
		json_init
		json_add_string state "$status_state"
		json_add_string phase "$status_phase"
		json_add_boolean ok "$status_ok"
		json_add_string message "$status_message"
		json_dump
	} > "$status_tmp" || return 1
	chmod 0600 "$status_tmp" || return 1
	mv -f "$status_tmp" "$job_dir/status" || return 1
}

job_id=$1
operation=$2
case "$job_id" in
	*[!0-9a-f]*|'') exit 2 ;;
esac
[ "${#job_id}" -eq 32 ] || exit 2
case "$operation" in backup|restore|reset|update_check|update_apply) ;; *) exit 2 ;; esac

job_dir=$JOBS/$job_id
[ -d "$JOBS" ] && [ ! -L "$JOBS" ] && [ -d "$job_dir" ] && [ ! -L "$job_dir" ] || exit 2
[ "$(stat -c '%u:%a' "$JOBS" 2>/dev/null)" = 0:700 ] && [ "$(stat -c '%u:%a' "$job_dir" 2>/dev/null)" = 0:700 ] || exit 2
[ "$(id -u)" = 0 ] || exit 2
write_status running preparing true preparing || exit 1
: > "$job_dir/output" || exit 1
chmod 0600 "$job_dir/output" || exit 1
if [ "$operation" = update_apply ]; then
	/usr/share/honk/update.sh apply > "$job_dir/output" 2>&1 &
elif [ "$operation" = update_check ]; then
	/usr/share/honk/update.sh check > "$job_dir/output" 2>&1 &
else
	"$MAINT" "$operation" > "$job_dir/output" 2>&1 &
fi
maint_pid=$!
logger -t honk-maintenance "$operation started" 2>/dev/null || :
# Total watchdog: never poll forever if maintenance.sh hangs.
_poll_deadline=$(($(date +%s) + 1800))
while kill -0 "$maint_pid" 2>/dev/null; do
	if [ "$(date +%s)" -ge "$_poll_deadline" ]; then
		logger -t honk-maintenance "$operation timed out after 1800s, killing $maint_pid" 2>/dev/null || :
		kill -9 "$maint_pid" 2>/dev/null || :
		break
	fi
	journal_phase=$(sed -n 's/^phase=//p' /etc/.honk-maintenance/journal 2>/dev/null | sed -n '1p')
	if [ "$operation" = update_apply ]; then
		update_phase=$(cat /etc/.honk-update/phase 2>/dev/null)
		case "$update_phase" in
			downloading) status_phase=downloading ;;
			verifying) status_phase=validating ;;
			stopping) status_phase=stopping ;;
			installing) status_phase=applying ;;
			starting) status_phase=starting ;;
			*) status_phase=preparing ;;
		esac
	elif [ "$operation" = update_check ]; then
		status_phase=checking_feed
	else case "$journal_phase" in
		prepared) status_phase=preparing ;;
		stopped) status_phase=stopping ;;
		old_moved|new_installed) status_phase=applying ;;
		uci_applied) status_phase=validating ;;
		service_started) status_phase=starting ;;
		rollback_old_start) status_phase=rolling_back ;;
		committed) status_phase=committing ;;
		*) status_phase=preparing ;;
	esac; fi
	write_status running "$status_phase" true "$status_phase" || :
	sleep 1
done
wait "$maint_pid"
operation_rc=$?
json_load "$(cat "$job_dir/output" 2>/dev/null)" 2>/dev/null || {
	if [ -e /etc/.honk-maintenance/journal ] || [ -L /etc/.honk-maintenance/journal ] || [ -d /run/honk.lock ]; then
		write_status rollback_required recovery false maintenance_recovery_required
	else
		write_status failed complete false operation_failed
	fi
	logger -t honk-maintenance "$operation failed (invalid result)" 2>/dev/null || :
	exit 1
}
json_get_var operation_ok ok
json_get_var operation_message message
if [ "$operation_rc" -eq 0 ] && [ "$operation_ok" = 1 ]; then
	if [ "$operation" = update_check ]; then
		json_add_string state succeeded
		json_add_string phase complete
		json_add_string job_id "$job_id"
		json_dump > "$job_dir/status.new" && chmod 0600 "$job_dir/status.new" && mv -f "$job_dir/status.new" "$job_dir/status" || exit 1
		logger -t honk-maintenance "$operation completed" 2>/dev/null || :
		exit 0
	fi
	write_status succeeded complete true "$operation_message"
	logger -t honk-maintenance "$operation completed" 2>/dev/null || :
	exit 0
fi
case "$operation_message" in
	*rollback_failed*|*recovery_required*|*snapshot_retained*)
		write_status rollback_required recovery false "$operation_message"
		logger -t honk-maintenance "$operation requires recovery" 2>/dev/null || :
		exit 1
		;;
esac
write_status failed complete false "${operation_message:-operation_failed}"
logger -t honk-maintenance "$operation failed" 2>/dev/null || :
exit 1
