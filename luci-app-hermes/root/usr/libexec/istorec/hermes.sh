#!/bin/sh

set -eu

NATIVE=${HERMES_NATIVE_ADAPTER:-/usr/libexec/istorec/hermes-native.sh}
DOCKER=${HERMES_DOCKER_ADAPTER:-/usr/libexec/istorec/hermes-docker.sh}

backend() {
	value="$(uci -q get 'hermes.@main[0].backend' 2>/dev/null || true)"
	case "$value" in native|docker) echo "$value" ;; *) echo native ;; esac
}

adapter() {
	case "$1" in native) echo "$NATIVE" ;; docker) echo "$DOCKER" ;; *) return 1 ;; esac
}

other_backend() {
	[ "$1" = native ] && echo docker || echo native
}

state() {
	"$(adapter "$1")" status
}

was_active() {
	case "$(state "$1")" in running|degraded) return 0 ;; *) return 1 ;; esac
}

save_backend() {
	target="$1"
	case "$target" in native|docker) ;; *) return 1 ;; esac
	uci -q set "hermes.@main[0].backend=$target"
	uci -q set "hermes.@main[0].target_backend=$target"
	if [ "$target" = native ]; then
		uci -q set 'hermes.@main[0].native_enabled=1'
	else
		uci -q set 'hermes.@main[0].native_enabled=0'
	fi
	uci -q commit hermes
}

restore_backend() {
	old_backend="$1"
	old_native_enabled="$2"
	uci -q set "hermes.@main[0].backend=$old_backend"
	uci -q set "hermes.@main[0].native_enabled=$old_native_enabled"
	uci -q commit hermes
}

activate() {
	target="$1"
	old_backend="$(backend)"
	old_native_enabled="$(uci -q get 'hermes.@main[0].native_enabled' 2>/dev/null || echo 0)"
	other="$(other_backend "$target")"
	other_active=0
	was_active "$other" && other_active=1

	if [ "$other_active" -eq 1 ]; then
		"$(adapter "$other")" stop
	fi
	save_backend "$target"
	if "$(adapter "$target")" start && "$(adapter "$target")" health >/dev/null 2>&1; then
		echo "active:$target"
		return 0
	fi

	echo "Hermes $target failed to become healthy; restoring $old_backend" >&2
	"$(adapter "$target")" stop >/dev/null 2>&1 || true
	restore_backend "$old_backend" "$old_native_enabled"
	[ "$other_active" -eq 0 ] || "$(adapter "$other")" start
	return 1
}

install_or_upgrade() {
	operation="$1"
	old_backend="$(backend)"
	target="$(uci -q get 'hermes.@main[0].target_backend' 2>/dev/null || true)"
	case "$target" in native|docker) ;; *) target="$old_backend" ;; esac
	old_native_enabled="$(uci -q get 'hermes.@main[0].native_enabled' 2>/dev/null || echo 0)"
	other="$(other_backend "$target")"
	other_active=0
	was_active "$other" && other_active=1

	if [ "$target" = native ]; then
		# Candidate checks run without taking the selected Docker service down.
		"$NATIVE" "$operation"
		activate native
		return
	fi

	# A cold-machine pull occurs before Native is stopped. Network failure cannot
	# turn a working Native installation into avoidable downtime.
	"$DOCKER" pull
	if [ "$other_active" -eq 1 ]; then "$NATIVE" stop; fi
	save_backend docker
	if "$DOCKER" replace; then
		echo "active:docker"
		return 0
	fi

	echo "Hermes Docker replacement failed; restoring the previous backend" >&2
	[ "$old_backend" = docker ] || "$DOCKER" stop >/dev/null 2>&1 || true
	restore_backend "$old_backend" "$old_native_enabled"
	[ "$other_active" -eq 0 ] || "$NATIVE" start
	return 1
}

do_stop() {
	current="$(backend)"
	"$(adapter "$current")" stop
	if [ "$current" = native ]; then
		uci -q set 'hermes.@main[0].native_enabled=0'
		uci -q commit hermes
	fi
}

do_remove() {
	current="$(backend)"
	"$(adapter "$current")" remove
	if [ "$current" = native ]; then
		uci -q set 'hermes.@main[0].native_enabled=0'
		uci -q commit hermes
	fi
}

usage() {
	echo "usage: $0 install|upgrade|switch native|docker|start|stop|restart|status|health|port|backend|status-native|status-docker|remove|rm" >&2
}

case "${1:-}" in
	install|upgrade) install_or_upgrade "$1" ;;
	switch)
		case "${2:-}" in native|docker) ;; *) usage; exit 2 ;; esac
		[ "$(state "$2")" != uninstalled ] || { echo "Hermes $2 is not installed" >&2; exit 1; }
		activate "$2"
		;;
	start) activate "$(backend)" ;;
	stop) do_stop ;;
	restart) do_stop; activate "$(backend)" ;;
	status) state "$(backend)" ;;
	health) "$(adapter "$(backend)")" health ;;
	port)
		if [ "$(backend)" = native ]; then
			value="$(uci -q get 'hermes.@main[0].native_port' 2>/dev/null || true)"; echo "${value:-18787}"
		else
			"$DOCKER" port
		fi
		;;
	backend) backend ;;
	status-native) "$NATIVE" status ;;
	status-docker) "$DOCKER" status ;;
	remove|rm) do_remove ;;
	image) "$DOCKER" image ;;
	cancel|recover|purge) "$NATIVE" "$1" ;;
	logs) "$NATIVE" logs "${2:-200}" ;;
	*) usage; exit 2 ;;
esac
