#!/bin/sh

daed_cleanup_runtime() {
	local pid

	for pid in $(ip netns pids daens 2>/dev/null); do
		kill "$pid" 2>/dev/null
	done

	if [ -n "$(ip netns pids daens 2>/dev/null)" ]; then
		sleep 1
		for pid in $(ip netns pids daens 2>/dev/null); do
			kill -9 "$pid" 2>/dev/null
		done
	fi

	if ! ip netns del daens 2>/dev/null; then
		umount -l /run/netns/daens 2>/dev/null
		rm -f /run/netns/daens
	fi

	ip link del dae0 2>/dev/null || true

	[ ! -e /run/netns/daens ] || return 1
	! ip netns list 2>/dev/null | awk '$1 == "daens" { found=1 } END { exit !found }' || return 1
	! ip link show dae0 >/dev/null 2>&1 || return 1
}
