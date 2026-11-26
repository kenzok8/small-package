#!/bin/sh

set -eu

CONTAINER=hermes
# This digest is an immutable multi-architecture index (linux/amd64 + linux/arm64).
# The release workflow updates it only after the pinned Dockerfile build is published.
IMAGE='linkease/hermes@sha256:6958262de9d71633b81866e2b17f35c8662e2aaa9a91b0444d29d795b3b08763'

uci_get() {
	uci -q get "hermes.@main[0].$1" 2>/dev/null || true
}

need_docker() {
	command -v docker >/dev/null 2>&1 || {
		echo "Docker is not installed; install it before using the Docker backend" >&2
		return 1
	}
	docker info >/dev/null 2>&1 || {
		echo "Docker is not available" >&2
		return 1
	}
}

container_exists() {
	docker inspect "$1" >/dev/null 2>&1
}

container_running() {
	[ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || true)" = true ]
}

validate_port() {
	case "$1" in ''|*[!0-9]*) return 1 ;; esac
	[ "$1" -gt 1024 ] 2>/dev/null && [ "$1" -le 65535 ] 2>/dev/null
}

validate_path() {
	value="$1"
	label="$2"
	case "$value" in
		/mnt/*) ;;
		*) echo "$label must be an absolute persistent path below /mnt" >&2; return 1 ;;
	esac
	case "/$value/" in */../*|*/./*) echo "$label is not normalized" >&2; return 1 ;; esac
	[ ! -L "$value" ] || { echo "$label must not be a symbolic link" >&2; return 1; }
}

prepare_path() {
	value="$1"
	label="$2"
	validate_path "$value" "$label" || return 1
	mkdir -p "$value"
}

configured() {
	PORT="$(uci_get port)"
	DATA="$(uci_get data_path)"
	WORKSPACE="$(uci_get workspace_path)"
	[ -n "$PORT" ] || PORT=8787
	validate_port "$PORT" || { echo "Invalid Docker port: $PORT" >&2; return 1; }
	if [ "${1:-}" = create ]; then
		prepare_path "$DATA" "Docker data path" || return 1
		prepare_path "$WORKSPACE" "Docker workspace path" || return 1
	else
		validate_path "$DATA" "Docker data path" || return 1
		validate_path "$WORKSPACE" "Docker workspace path" || return 1
	fi
}

do_pull() {
	need_docker
	echo "Pulling immutable Hermes image $IMAGE"
	docker pull "$IMAGE"
	docker image inspect "$IMAGE" >/dev/null
}

wait_healthy() {
	n=0
	while [ "$n" -lt 120 ]; do
		container_running "$CONTAINER" || return 1
		if curl --disable -fsS --noproxy '*' --max-time 3 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
			return 0
		fi
		n=$((n + 1))
		sleep 1
	done
	return 1
}

run_new() {
	set -- docker run --restart=unless-stopped -d \
		--name "$CONTAINER" \
		-v "$DATA:/data/.hermes" \
		-v "$WORKSPACE:/workspace" \
		-p "$PORT:8787"
	tz="$(uci -q get 'system.@system[0].zonename' 2>/dev/null | tr ' ' '_' || true)"
	[ -z "$tz" ] || set -- "$@" -e "TZ=$tz"
	set -- "$@" "$IMAGE"
	"$@"
}

do_install() {
	need_docker
	do_pull
	do_replace
}

do_replace() {
	need_docker
	configured create
	docker image inspect "$IMAGE" >/dev/null 2>&1 || {
		echo "Pinned Hermes image is not present; run pull first" >&2
		return 1
	}

	backup="hermes-backup-$$"
	had_old=0
	old_running=0
	if container_exists "$CONTAINER"; then
		had_old=1
		container_running "$CONTAINER" && old_running=1
		docker stop -t 20 "$CONTAINER" >/dev/null 2>&1 || true
		docker rename "$CONTAINER" "$backup"
	fi

	if run_new >/dev/null && wait_healthy; then
		[ "$had_old" -eq 0 ] || docker rm -f "$backup" >/dev/null
		echo installed
		return 0
	fi

	echo "New Hermes Docker container failed its health check; restoring the previous container" >&2
	docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
	if [ "$had_old" -eq 1 ]; then
		docker rename "$backup" "$CONTAINER" >/dev/null
		[ "$old_running" -eq 0 ] || docker start "$CONTAINER" >/dev/null
	fi
	return 1
}

do_start() {
	need_docker
	configured
	container_exists "$CONTAINER" || { echo "Hermes Docker is not installed" >&2; return 1; }
	docker start "$CONTAINER" >/dev/null
	wait_healthy
}

do_stop() {
	need_docker
	container_exists "$CONTAINER" || return 0
	docker stop -t 20 "$CONTAINER" >/dev/null
}

do_status() {
	if ! command -v docker >/dev/null 2>&1 || ! container_exists "$CONTAINER"; then
		echo uninstalled
	elif container_running "$CONTAINER"; then
		if do_health >/dev/null 2>&1; then echo running; else echo degraded; fi
	else
		echo stopped
	fi
}

do_health() {
	configured
	container_running "$CONTAINER" || return 1
	curl --disable -fsS --noproxy '*' --max-time 3 "http://127.0.0.1:$PORT/health" >/dev/null
}

do_remove() {
	need_docker
	docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
	echo removed-container-data-preserved
}

usage() {
	echo "usage: $0 pull|install|upgrade|start|stop|restart|status|health|remove|rm|port|image" >&2
}

case "${1:-}" in
	pull) do_pull ;;
	install|upgrade) do_install ;;
	replace) do_replace ;;
	start) do_start ;;
	stop) do_stop ;;
	restart) do_stop; do_start ;;
	status) do_status ;;
	health) do_health ;;
	remove|rm) do_remove ;;
	port) value="$(uci_get port)"; echo "${value:-8787}" ;;
	image) echo "$IMAGE" ;;
	*) usage; exit 2 ;;
esac
