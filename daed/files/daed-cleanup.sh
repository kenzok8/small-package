#!/bin/sh
# daed-cleanup.sh — reaper for stale daed kernel state.
#
# Removes:
#   1. Processes inside the `daens` netns (SIGTERM, then SIGKILL after 1s)
#   2. The `daens` network namespace itself (ip netns del, with
#      umount+rm as fallback for zombie nsfs mounts)
#   3. The `dae0` veth pair in the host netns
#
# daed itself owns TC clsact detach. This opkg-side helper only
# reaps stale daens/dae0 state and never removes /sys/fs/bpf/daed.
# The pin directory is created during normal startup, so it is not
# a reliable leak indicator and must not block service lifecycle.
#
# The function stays sourceable by both init.d/daed and daed-guard.

daed_process_probe() {
	if command -v pgrep >/dev/null 2>&1; then
		pgrep -f '^/usr/bin/daed([[:space:]]|$)' >/dev/null 2>&1
		case "$?" in
			0) return 0 ;;
			1) return 1 ;;
		esac
	fi

	if command -v pidof >/dev/null 2>&1; then
		pidof daed >/dev/null 2>&1
		case "$?" in
			0) return 0 ;;
			1) return 1 ;;
		esac
	fi

	return 2
}

daed_cleanup_runtime() {
	local pid rc=0 probe_rc

	# If daed userspace is currently running, do not touch the
	# netns, the veth, or the eBPF dataplane. They are in active
	# use; removing them would make every connection through dae
	# hang.
	daed_process_probe
	probe_rc=$?
	case "$probe_rc" in
	0)
		if [ "${DAED_GUARD_CLEANUP:-start}" = "start" ]; then
			logger -t daed-init "cleanup: pre-start skipped because /usr/bin/daed is still running; refusing a second instance"
			return 1
		fi
		logger -t daed-init "cleanup: post-exit skipped because another /usr/bin/daed instance is still running"
		return 0
		;;
	1) ;;
	*)
		logger -t daed-init "cleanup: cannot determine whether daed is running; refusing to remove netns/veth"
		return 1
		;;
	esac

	# 1. Kill processes inside daens.
	for pid in $(ip netns pids daens 2>/dev/null); do
		kill "$pid" 2>/dev/null
	done

	if [ -n "$(ip netns pids daens 2>/dev/null)" ]; then
		sleep 1
		for pid in $(ip netns pids daens 2>/dev/null); do
			kill -9 "$pid" 2>/dev/null
		done
	fi

	# 2. Remove the daens netns. ip netns del can fail if a
	#    process still references it via /proc/<pid>/ns/net or
	#    because the umount has already happened. Try the
	#    umount/rm fallback.
	if ! ip netns del daens 2>/dev/null; then
		umount -l /run/netns/daens 2>/dev/null
		if [ -e /run/netns/daens ] && ! rm -f /run/netns/daens 2>/dev/null; then
			logger -t daed-init "cleanup: failed to remove /run/netns/daens (resource busy); a reboot may be required"
			rc=1
		fi
	fi

	# 3. Remove the dae0 veth pair.
	if ip link show dae0 >/dev/null 2>&1; then
		if ! ip link del dae0 2>/dev/null; then
			logger -t daed-init "cleanup: failed to remove dae0 veth pair"
			rc=1
		fi
	fi

	# 4. The pin root is normal persistent state. Never remove it or
	#    make its existence change the cleanup result.
	if [ -e /sys/fs/bpf/daed ]; then
		logger -t daed-init "cleanup: /sys/fs/bpf/daed exists; leaving normal pin root unchanged"
	fi

	# Final verification covers only netns and veth state.
	[ ! -e /run/netns/daens ] || return 1
	! ip netns list 2>/dev/null | grep -Eq '^daens([[:space:]]|$)' || return 1
	! ip link show dae0 >/dev/null 2>&1 || return 1

	return $rc
}
