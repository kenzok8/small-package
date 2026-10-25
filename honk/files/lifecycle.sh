#!/bin/sh

HONK_LIFECYCLE_CORE=/usr/bin/honk-core

honk_lifecycle_procd_pid() {
	ubus call service list '{"name":"honk"}' 2>/dev/null | jsonfilter -e '@.honk.instances.main.pid' 2>/dev/null
}

honk_lifecycle_procd_running() {
	ubus call service list '{"name":"honk"}' 2>/dev/null | jsonfilter -e '@.honk.instances.main.running' 2>/dev/null
}

honk_lifecycle_managed_pid() {
	hlp_pid=$(honk_lifecycle_procd_pid)
	[ -n "$hlp_pid" ] && [ -r "/proc/$hlp_pid/cmdline" ] || return 1
	hlp_cmd=$(tr '\000' ' ' < "/proc/$hlp_pid/cmdline" 2>/dev/null) || return 1
	case "$hlp_cmd" in
		*/usr/bin/honk-core\ --config\ /etc/honk/config.dae\ --disable-timestamp*) ;;
		*) return 1 ;;
	esac
	case "$hlp_cmd" in *--mock-ebpf*) return 1 ;; esac
	[ "$(readlink -f "/proc/$hlp_pid/exe" 2>/dev/null)" = "$HONK_LIFECYCLE_CORE" ] || return 1
	printf '%s\n' "$hlp_pid"
}

honk_lifecycle_starttime() {
	[ -r "/proc/$1/stat" ] || return 1
	awk '{ sub(/^.*\) /, ""); split($0, fields, /[[:space:]]+/); if (fields[20] ~ /^[0-9]+$/) print fields[20]; else exit 1 }' "/proc/$1/stat" 2>/dev/null
}

honk_lifecycle_listen() {
	sed -n "s/^[[:space:]]*listen:[[:space:]]*'\([^']*\)'.*/\1/p" /etc/honk/system.dae 2>/dev/null | head -n 1
}

honk_lifecycle_parse_listen() {
	HONK_LIFECYCLE_LISTEN=$(honk_lifecycle_listen)
	case "$HONK_LIFECYCLE_LISTEN" in *:*) ;; *) return 1 ;; esac
	HONK_LIFECYCLE_PORT=${HONK_LIFECYCLE_LISTEN##*:}
	case "$HONK_LIFECYCLE_LISTEN" in ''|*[!A-Za-z0-9:._-]*) return 1 ;; esac
	case "$HONK_LIFECYCLE_PORT" in ''|*[!0-9]*) return 1 ;; esac
	[ "$HONK_LIFECYCLE_PORT" -ge 1024 ] && [ "$HONK_LIFECYCLE_PORT" -le 65535 ]
}

honk_lifecycle_port_open() {
	hlp_port=$1
	case "$hlp_port" in ''|*[!0-9]*) return 1 ;; esac
	awk -v port="$hlp_port" 'BEGIN { printf "%04X\n", port }' | {
		IFS= read -r hlp_hex || exit 1
		for hlp_table in /proc/net/tcp /proc/net/tcp6; do
			[ -r "$hlp_table" ] || continue
			awk -v port="$hlp_hex" 'NR > 1 && toupper($2) ~ (":" port "$") && $4 == "0A" { found = 1 } END { exit !found }' "$hlp_table" && exit 0
		done
		exit 1
	}
}

honk_lifecycle_listener_owned() {
	hlp_pid=$1
	hlp_port=$2
	hlp_hex=$(awk -v port="$hlp_port" 'BEGIN { printf "%04X", port }') || return 1
	for hlp_table in /proc/net/tcp /proc/net/tcp6; do
		[ -r "$hlp_table" ] || continue
		for hlp_inode in $(awk -v port="$hlp_hex" 'NR > 1 && toupper($2) ~ (":" port "$") && $4 == "0A" { print $10 }' "$hlp_table"); do
			for hlp_fd in /proc/"$hlp_pid"/fd/*; do
				[ "$(readlink "$hlp_fd" 2>/dev/null)" = "socket:[$hlp_inode]" ] && return 0
			done
		done
	done
	return 1
}

honk_lifecycle_api_owned() {
	hlp_pid=$1
	honk_lifecycle_parse_listen || return 1
	honk_lifecycle_listener_owned "$hlp_pid" "$HONK_LIFECYCLE_PORT" && \
		curl -fsS --noproxy '*' --connect-timeout 1 --max-time 2 "http://$HONK_LIFECYCLE_LISTEN/api" -o /dev/null 2>/dev/null
}

honk_lifecycle_resources_clear() {
	command -v ip >/dev/null 2>&1 || return 1
	for hlp_link in dae0 dae0peer; do
		ip link show "$hlp_link" >/dev/null 2>&1 && return 1
	done
	! ip netns list 2>/dev/null | awk '{print $1}' | grep -qx daens
}

honk_lifecycle_drain() {
	hlp_timeout=${1:-30}
	while [ "$hlp_timeout" -gt 0 ]; do
		hlp_wait=0
		if [ -n "${HONK_LIFECYCLE_STOP_PID:-}" ] && \
			[ "$(honk_lifecycle_starttime "$HONK_LIFECYCLE_STOP_PID" 2>/dev/null)" = "$HONK_LIFECYCLE_STOP_STARTTIME" ]; then
			hlp_wait=1
		fi
		hlp_procd=$(honk_lifecycle_procd_pid)
		[ -z "$hlp_procd" ] || hlp_wait=1
		hlp_running=$(honk_lifecycle_procd_running)
		case "$hlp_running" in true|1) hlp_wait=1 ;; esac
		hlp_all=$(pidof honk-core 2>/dev/null)
		if [ -n "$hlp_all" ]; then
			for hlp_pid in $hlp_all; do
				if [ "$hlp_pid" != "${HONK_LIFECYCLE_STOP_PID:-}" ] || \
					[ "$(honk_lifecycle_starttime "$hlp_pid" 2>/dev/null)" != "${HONK_LIFECYCLE_STOP_STARTTIME:-}" ]; then
					echo "honk lifecycle: unmanaged honk-core process remains" >&2
					return 1
				fi
			done
			hlp_wait=1
		fi
		honk_lifecycle_resources_clear || hlp_wait=1
		honk_lifecycle_parse_listen || { echo "honk lifecycle: invalid configured listener" >&2; return 1; }
		hlp_port=$HONK_LIFECYCLE_PORT
		if honk_lifecycle_port_open "$hlp_port"; then hlp_wait=1; fi
		if [ "$hlp_wait" = 0 ]; then
			return 0
		fi
		sleep 1
		hlp_timeout=$((hlp_timeout - 1))
	done
	echo "honk lifecycle: old process or network resources did not drain" >&2
	return 1
}

honk_lifecycle_stop() {
	hlp_timeout=${1:-30}
	HONK_LIFECYCLE_STOP_PID=$(honk_lifecycle_managed_pid 2>/dev/null)
	if [ -n "$HONK_LIFECYCLE_STOP_PID" ]; then
		HONK_LIFECYCLE_STOP_STARTTIME=$(honk_lifecycle_starttime "$HONK_LIFECYCLE_STOP_PID") || return 1
	else
		[ -z "$(pidof honk-core 2>/dev/null)" ] || { echo "honk lifecycle: refusing to stop unmanaged honk-core" >&2; return 1; }
		[ -z "$(honk_lifecycle_procd_pid)" ] || { echo "honk lifecycle: procd instance is not the expected core" >&2; return 1; }
		case "$(honk_lifecycle_procd_running)" in true|1) echo "honk lifecycle: procd instance is still running" >&2; return 1 ;; esac
		HONK_LIFECYCLE_STOP_STARTTIME=
	fi
	if [ -n "$HONK_LIFECYCLE_STOP_PID" ]; then /etc/init.d/honk stop >/dev/null 2>&1 || :; fi
	honk_lifecycle_drain "$hlp_timeout"
}

honk_lifecycle_start() {
	hlp_timeout=${1:-30}
	[ -z "$(pidof honk-core 2>/dev/null)" ] || { echo "honk lifecycle: refusing start while a core process exists" >&2; return 1; }
	[ -z "$(honk_lifecycle_procd_pid)" ] || { echo "honk lifecycle: procd instance has not stopped" >&2; return 1; }
	case "$(honk_lifecycle_procd_running)" in true|1) echo "honk lifecycle: procd instance is still running" >&2; return 1 ;; esac
	honk_lifecycle_resources_clear || { echo "honk lifecycle: network resources have not drained" >&2; return 1; }
	honk_lifecycle_parse_listen || { echo "honk lifecycle: invalid configured listener" >&2; return 1; }
	hlp_listen=$HONK_LIFECYCLE_LISTEN
	hlp_port=$HONK_LIFECYCLE_PORT
	if honk_lifecycle_port_open "$hlp_port"; then echo "honk lifecycle: listener port remains occupied" >&2; return 1; fi
	if [ -n "${HONK_MAINT_CAP:-}" ]; then export HONK_MAINT_CAP; fi
	/etc/init.d/honk start >/dev/null 2>&1
	hlp_start_status=$?
	unset HONK_MAINT_CAP
	[ "$hlp_start_status" = 0 ] || { echo "honk lifecycle: init start failed" >&2; return 1; }
	hlp_stable=0
	hlp_pid=
	hlp_starttime=
	while [ "$hlp_timeout" -gt 0 ]; do
		hlp_new_pid=$(honk_lifecycle_managed_pid 2>/dev/null)
		if [ -n "$hlp_new_pid" ]; then
			hlp_new_starttime=$(honk_lifecycle_starttime "$hlp_new_pid") || hlp_new_starttime=
			if [ -n "$hlp_new_starttime" ] && \
				{ [ -z "${HONK_LIFECYCLE_STOP_PID:-}" ] || [ "$hlp_new_pid:$hlp_new_starttime" != "$HONK_LIFECYCLE_STOP_PID:$HONK_LIFECYCLE_STOP_STARTTIME" ]; } && \
				honk_lifecycle_listener_owned "$hlp_new_pid" "$hlp_port" && \
				curl -fsS --noproxy '*' --connect-timeout 1 --max-time 2 "http://$hlp_listen/api" -o /dev/null 2>/dev/null; then
				if [ "$hlp_pid:$hlp_starttime" = "$hlp_new_pid:$hlp_new_starttime" ]; then
					hlp_stable=$((hlp_stable + 1))
				else
					hlp_pid=$hlp_new_pid
					hlp_starttime=$hlp_new_starttime
					hlp_stable=1
				fi
				if [ "$hlp_stable" -ge 3 ]; then
					HONK_LIFECYCLE_STOP_PID=$hlp_new_pid
					HONK_LIFECYCLE_STOP_STARTTIME=$hlp_new_starttime
					return 0
				fi
			else
				hlp_stable=0
				hlp_pid=
				hlp_starttime=
			fi
		else
			hlp_stable=0
			hlp_pid=
			hlp_starttime=
		fi
		sleep 1
		hlp_timeout=$((hlp_timeout - 1))
	done
	echo "honk lifecycle: new managed core did not become stable and own its API listener" >&2
	return 1
}

honk_lifecycle_restart() {
	if [ -n "$(honk_lifecycle_managed_pid 2>/dev/null)" ]; then
		HONK_LIFECYCLE_WAS_RUNNING=1
	else
		[ -z "$(pidof honk-core 2>/dev/null)" ] || { echo "honk lifecycle: refusing unmanaged honk-core" >&2; return 1; }
		HONK_LIFECYCLE_WAS_RUNNING=0
	fi
	honk_lifecycle_stop "${1:-30}" && honk_lifecycle_start "${1:-30}"
}
