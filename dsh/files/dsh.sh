#!/bin/sh

set -eu

CONTAINER_NAME="dsh"
ROLLBACK_NAME="dsh-rollback"
GATEWAY_NAME="dsh-gateway"
GATEWAY_ROLLBACK_NAME="dsh-gateway-rollback"
ADVANCED_NETWORK="dsh-internal"
ADVANCED_GATEWAY_CONFIG="/usr/share/dsh/advanced.Caddyfile"
STANDARD_IMAGE="ghcr.io/omdsh-dev/dsh-container:0.2.1-rc.2@sha256:a447bbfcafce5d05d1e9cc861c9170bb6907ef1e31ed53a40c588bd6e77d5705"
ADVANCED_IMAGE_AMD64="ghcr.io/runzhliu/deepseek-harness:0.2.3-alpha.2-r1@sha256:7d2ff641998577439b5b662db3d048ea3e60cd86441b91c3cc2d74ab9fcf72f7"
ADVANCED_IMAGE_ARM64="ghcr.io/runzhliu/deepseek-harness:0.2.3-alpha.2-r1@sha256:7b20e5080a8d7f7df2fb5c1f3dddf2bebd76a5cab545392b5e82735cd1197a79"
ADVANCED_CONFIG_AMD64="sha256:266e86b31e1fe05552674f12d30d99083c601c24e0987546c611e5047e8854ba"
ADVANCED_CONFIG_ARM64="sha256:3866db5dcdd619e1c28d195841728ee879b381cec1f299ace02366f02096f36d"
GATEWAY_IMAGE_AMD64="docker.io/library/caddy:2.11.4-alpine@sha256:040e9f7480b80b6d4a7e5013a21159b950a63dcbdb956e38abe2387fb28d9ec0"
GATEWAY_IMAGE_ARM64="docker.io/library/caddy:2.11.4-alpine@sha256:c802bf2721a427e961b9fd6a194c3888a180de9990b43f8530a02bd6be017e17"
GATEWAY_CONFIG_AMD64="sha256:2d8b1708bf8008935c0e2a9b6564f7f080cf9a73af3b27718f286230449b7101"
GATEWAY_CONFIG_ARM64="sha256:8b20b62e1c76d212304053dc6484bd1f2186018e2baa217ce7a35cec0ded404c"
KEY_DIRECTORY="/etc/dsh"
KEY_FILE="$KEY_DIRECTORY/admin.key"

fail() {
	printf 'dsh: %s\n' "$*" >&2
	exit 1
}

uci_get() {
	uci -q get "dsh.@main[0].$1" 2>/dev/null || true
}

machine_arch() {
	case "$(uname -m)" in
		x86_64|amd64) printf 'amd64\n' ;;
		aarch64|arm64) printf 'arm64\n' ;;
		*) fail "unsupported machine architecture: $(uname -m)" ;;
	esac
}

resolve_profile() {
	case "${1:-standard}" in
		standard|'') printf '%s\n' "$STANDARD_IMAGE" ;;
		advanced)
			case "$(machine_arch)" in
				amd64) printf '%s\n' "$ADVANCED_IMAGE_AMD64" ;;
				arm64) printf '%s\n' "$ADVANCED_IMAGE_ARM64" ;;
			esac
			;;
		*) fail "unsupported image profile: $1" ;;
	esac
}

resolve_gateway_image() {
	case "$(machine_arch)" in
		amd64) printf '%s\n' "$GATEWAY_IMAGE_AMD64" ;;
		arm64) printf '%s\n' "$GATEWAY_IMAGE_ARM64" ;;
	esac
}

validate_port() {
	case "$1" in ''|*[!0-9]*) return 1 ;; esac
	[ "${#1}" -le 5 ] && [ "$1" -ge 1024 ] && [ "$1" -le 65535 ]
}

ensure_admin_key() {
	umask 077
	if [ ! -f "$KEY_FILE" ]; then
		mkdir -p "$KEY_DIRECTORY"
		[ -d "$KEY_DIRECTORY" ] && [ ! -L "$KEY_DIRECTORY" ] || fail "invalid key directory"
		pending="$KEY_FILE.new"
		hexdump -n 32 -e '32/1 "%02x"' /dev/urandom > "$pending"
		[ "$(wc -c < "$pending" | tr -d ' ')" = 64 ] || {
			rm -f "$pending"
			fail "could not generate the DSH administrator key"
		}
		chmod 0600 "$pending"
		mv "$pending" "$KEY_FILE"
	fi
	[ -f "$KEY_FILE" ] && [ ! -L "$KEY_FILE" ] || fail "invalid administrator key file"
	[ "$(stat -c '%u' "$KEY_FILE" 2>/dev/null || true)" = 0 ] || fail "administrator key must be owned by root"
	chmod 0600 "$KEY_FILE"
	key_size="$(wc -c < "$KEY_FILE" | tr -d ' ')"
	case "$key_size" in ''|*[!0-9]*) fail "administrator key size could not be read" ;; esac
	[ "$key_size" -ge 12 ] && [ "$key_size" -le 4096 ] || fail "administrator key must contain 12 to 4096 bytes"
	if LC_ALL=C grep -q '[[:cntrl:]]' "$KEY_FILE"; then
		fail "administrator key must not contain control characters"
	fi
}

validate_storage_path() {
	path="$1"
	case "$path" in
		/mnt/*/*) ;;
		*) return 1 ;;
	esac
	case "$path" in
		*//*|*/../*|*/..|*/./*|*/.|*:*|*,*|*[[:space:]]*) return 1 ;;
	esac
	return 0
}

validate_trusted_hosts() {
	value="$1"
	[ -n "$value" ] || return 0
	[ "$value" = "*" ] && return 0
	case "$value" in
		*[!A-Za-z0-9.,:_%_-]*) return 1 ;;
	esac
	return 0
}

prepare_directory() {
	path="$1"
	created=0
	if [ ! -d "$path" ]; then
		mkdir -p "$path"
		created=1
	fi
	[ -d "$path" ] || fail "not a directory: $path"
	[ ! -L "$path" ] || fail "symbolic-link storage paths are not supported: $path"
	if [ "$created" = "1" ]; then
		chown 1000:1000 "$path"
		chmod 0750 "$path"
	else
		owner="$(stat -c '%u' "$path" 2>/dev/null || true)"
		[ "$owner" = "1000" ] || fail "existing directory must be owned by UID 1000: $path"
	fi
}

timezone() {
	value="$(uci -q get system.@system[0].zonename 2>/dev/null || true)"
	[ -n "$value" ] || value="UTC"
	printf '%s\n' "$(printf '%s' "$value" | tr ' ' '_')"
}

trusted_hosts() {
	extra="$1"
	hostname_value="$(uci -q get system.@system[0].hostname 2>/dev/null || true)"
	value="localhost,127.0.0.1"
	if [ -n "$hostname_value" ]; then
		value="$value,$hostname_value,$hostname_value.lan"
	fi
	if command -v ip >/dev/null 2>&1; then
		for address in $(ip -o -4 addr show scope global 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}'); do
			[ -z "$address" ] || value="$value,$address"
		done
	fi
	case "$extra" in
		''|'*') ;;
		*) value="$value,$extra" ;;
	esac
	printf '%s\n' "$value"
}

container_exists() {
	docker container inspect "$1" >/dev/null 2>&1
}

network_exists() {
	docker network inspect "$ADVANCED_NETWORK" >/dev/null 2>&1
}

ensure_advanced_network() {
	if ! network_exists; then
		docker network create --label io.istore.dsh.network=true "$ADVANCED_NETWORK" >/dev/null
	fi
}

disconnect_rollback() {
	container="$1"
	if network_exists && container_exists "$container"; then
		docker network disconnect -f "$ADVANCED_NETWORK" "$container" >/dev/null 2>&1 || true
	fi
}

restore_previous() {
	docker rm -f "$GATEWAY_NAME" >/dev/null 2>&1 || true
	docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

	if container_exists "$ROLLBACK_NAME"; then
		docker rename "$ROLLBACK_NAME" "$CONTAINER_NAME" >/dev/null
		previous_profile="$(docker inspect --format '{{index .Config.Labels "io.istore.dsh.profile"}}' "$CONTAINER_NAME" 2>/dev/null || true)"
		if [ "$previous_profile" = "advanced" ]; then
			ensure_advanced_network
			docker network connect --alias dsh "$ADVANCED_NETWORK" "$CONTAINER_NAME" >/dev/null
		fi
		docker start "$CONTAINER_NAME" >/dev/null
	fi
	if container_exists "$GATEWAY_ROLLBACK_NAME"; then
		docker rename "$GATEWAY_ROLLBACK_NAME" "$GATEWAY_NAME" >/dev/null
		ensure_advanced_network
		docker network connect "$ADVANCED_NETWORK" "$GATEWAY_NAME" >/dev/null
		docker start "$GATEWAY_NAME" >/dev/null
	fi
}

wait_healthy() {
	container="$1"
	count=0
	while [ "$count" -lt 90 ]; do
		state="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"
		case "$state" in
			healthy) return 0 ;;
			unhealthy|exited|dead) return 1 ;;
		esac
		count=$((count + 1))
		sleep 2
	done
	return 1
}

wait_advanced_gateway() {
	port="$1"
	count=0
	while [ "$count" -lt 30 ]; do
		status="$(curl -sS -o /dev/null -w '%{http_code}' -H "Host: 127.0.0.1:$port" "http://127.0.0.1:$port/" 2>/dev/null || true)"
		[ "$status" = "401" ] && return 0
		container_state="$(docker inspect --format '{{.State.Status}}' "$GATEWAY_NAME" 2>/dev/null || true)"
		case "$container_state" in exited|dead) return 1 ;; esac
		count=$((count + 1))
		sleep 1
	done
	return 1
}

pull_or_use_cached() {
	image_ref="$1"
	PULLED_IMAGE_REF="$image_ref"
	if docker image inspect "$image_ref" >/dev/null 2>&1; then
		printf 'Using the already cached exact image: %s\n' "$image_ref" >&2
		return 0
	fi
	case "$image_ref" in
		"$ADVANCED_IMAGE_AMD64") expected_config="$ADVANCED_CONFIG_AMD64" ;;
		"$ADVANCED_IMAGE_ARM64") expected_config="$ADVANCED_CONFIG_ARM64" ;;
		"$GATEWAY_IMAGE_AMD64") expected_config="$GATEWAY_CONFIG_AMD64" ;;
		"$GATEWAY_IMAGE_ARM64") expected_config="$GATEWAY_CONFIG_ARM64" ;;
		*) expected_config="" ;;
	esac
	if [ -n "$expected_config" ]; then
		cached_tag="${image_ref%@sha256:*}"
		actual_config="$(docker image inspect --format '{{.Id}}' "$cached_tag" 2>/dev/null || true)"
		if [ "$actual_config" = "$expected_config" ]; then
			PULLED_IMAGE_REF="$cached_tag"
			printf 'Using the cached image after config-digest verification: %s\n' "$cached_tag" >&2
			return 0
		fi
	fi
	docker pull "$image_ref"
}

prepare_previous() {
	docker rm -f "$ROLLBACK_NAME" "$GATEWAY_ROLLBACK_NAME" >/dev/null 2>&1 || true
	had_core=0
	had_gateway=0
	container_exists "$CONTAINER_NAME" && had_core=1
	container_exists "$GATEWAY_NAME" && had_gateway=1

	if [ "$had_core" = "1" ] && ! docker stop -t 20 "$CONTAINER_NAME" >/dev/null; then
		fail "failed to stop the current DSH container"
	fi
	if [ "$had_gateway" = "1" ] && ! docker stop -t 10 "$GATEWAY_NAME" >/dev/null; then
		[ "$had_core" = "1" ] && docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
		fail "failed to stop the current DSH gateway"
	fi
	if [ "$had_core" = "1" ] && ! docker rename "$CONTAINER_NAME" "$ROLLBACK_NAME" >/dev/null; then
		docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
		[ "$had_gateway" = "1" ] && docker start "$GATEWAY_NAME" >/dev/null 2>&1 || true
		fail "failed to prepare the current DSH container for rollback"
	fi
	if [ "$had_gateway" = "1" ] && ! docker rename "$GATEWAY_NAME" "$GATEWAY_ROLLBACK_NAME" >/dev/null; then
		if [ "$had_core" = "1" ]; then
			docker rename "$ROLLBACK_NAME" "$CONTAINER_NAME" >/dev/null 2>&1 || true
			docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
		fi
		docker start "$GATEWAY_NAME" >/dev/null 2>&1 || true
		fail "failed to prepare the current DSH gateway for rollback"
	fi
	disconnect_rollback "$ROLLBACK_NAME"
	disconnect_rollback "$GATEWAY_ROLLBACK_NAME"
}

run_standard() {
	admin_key="$(cat "$KEY_FILE")"
	if ! docker run -d \
		--name "$CONTAINER_NAME" \
		--hostname dsh-workbench \
		--label "io.istore.dsh.profile=standard" \
		--label "io.istore.dsh.image=$expected_image" \
		--restart unless-stopped \
		--init \
		--read-only \
		--cap-drop ALL \
		--security-opt no-new-privileges:true \
		--stop-timeout 20 \
		--pids-limit 1024 \
		--publish "$port:3080" \
		--env "DSH_HOME=/home/node/.dsh" \
		--env "DSH_CONTAINER_KEY=$admin_key" \
		--env "DSH_PERMISSION_MODE=danger-full-access" \
		--env "DSH_TELEMETRY_DISABLED=1" \
		--env "DSH_CONTAINER_TRUSTED_HOSTS=$(trusted_hosts "$extra_hosts")" \
		--env "NODE_USE_ENV_PROXY=1" \
		--env "TZ=$(timezone)" \
		--tmpfs /tmp:rw,exec,nosuid,nodev,size=512m,mode=1777 \
		--mount "type=bind,src=$workspace_path,dst=/home/node" \
		--mount "type=bind,src=$data_path,dst=/home/node/.dsh" \
		"$image"; then
		unset admin_key
		return 1
	fi
	unset admin_key
	return 0
}

run_advanced_core() {
	set -- web --patch /opt/deepseek-harness/web.cordis.patch.yml --no-open
	trusted_hosts_value="$(trusted_hosts "$extra_hosts")"
	previous_ifs="$IFS"
	IFS=,
	for trusted_host in $trusted_hosts_value; do
		set -- "$@" --trusted-host "$trusted_host"
	done
	IFS="$previous_ifs"
	unset trusted_hosts_value

	docker run -d \
		--name "$CONTAINER_NAME" \
		--hostname dsh-workbench \
		--network "$ADVANCED_NETWORK" \
		--network-alias dsh \
		--label "io.istore.dsh.profile=advanced" \
		--label "io.istore.dsh.image=$expected_image" \
		--restart unless-stopped \
		--read-only \
		--cap-drop ALL \
		--security-opt no-new-privileges:true \
		--stop-timeout 20 \
		--pids-limit 512 \
		--shm-size 1g \
		--health-cmd "node -e \"Promise.all([fetch('http://127.0.0.1:3080/'),fetch('http://127.0.0.1:6080/vnc.html'),fetch('http://127.0.0.1:9222/json/version')]).then(([web,desktop,cdp])=>{if(web.status!==401||!desktop.ok||!cdp.ok)process.exit(1)}).catch(()=>process.exit(1))\"" \
		--health-interval 15s \
		--health-timeout 3s \
		--health-start-period 20s \
		--health-retries 4 \
		--env "DSH_HOME=/home/node/.dsh" \
		--env "DSH_DESKTOP_ENABLED=1" \
		--env "DSH_BROWSER_USE_ENABLED=1" \
		--env "DSH_DESKTOP_PUBLIC_PORT=$port" \
		--env "DSH_TELEMETRY_DISABLED=1" \
		--env "NODE_USE_ENV_PROXY=1" \
		--env "TZ=$(timezone)" \
		--tmpfs /tmp:rw,noexec,nosuid,nodev,size=512m,mode=1777 \
		--mount "type=bind,src=$workspace_path,dst=/workspace" \
		--mount "type=bind,src=$advanced_data_path,dst=/home/node/.dsh" \
		"$image" "$@"
}

run_advanced_gateway() {
	docker run -d \
		--name "$GATEWAY_NAME" \
		--hostname dsh-gateway \
		--network "$ADVANCED_NETWORK" \
		--label "io.istore.dsh.profile=advanced" \
		--restart unless-stopped \
		--read-only \
		--cap-drop ALL \
		--cap-add NET_BIND_SERVICE \
		--security-opt no-new-privileges:true \
		--stop-timeout 10 \
		--pids-limit 128 \
		--publish "$port:13080" \
		--env "DSH_PASSWORD_HASH=$password_hash" \
		--env "DSH_LAUNCH_TOKEN=$launch_token" \
		--tmpfs /config:rw,noexec,nosuid,nodev,size=1m,mode=0700 \
		--tmpfs /data:rw,noexec,nosuid,nodev,size=1m,mode=0700 \
		--tmpfs /tmp:rw,noexec,nosuid,nodev,size=8m,mode=1777 \
		--mount "type=bind,src=$ADVANCED_GATEWAY_CONFIG,dst=/etc/caddy/Caddyfile,readonly" \
		"$gateway_image"
}

hash_admin_password() {
	{
		cat "$KEY_FILE"
		printf '\n'
	} | docker run --rm -i --entrypoint caddy "$gateway_image" \
		hash-password --algorithm bcrypt 2>/dev/null
}

read_launch_token() {
	token="$(docker logs --tail 300 "$CONTAINER_NAME" 2>&1 | sed -n 's|.*[?&]token=\([A-Za-z0-9._~%-][A-Za-z0-9._~%-]*\).*|\1|p' | tail -n 1)"
	[ -n "$token" ] || return 1
	[ "${#token}" -le 512 ] || return 1
	printf '%s\n' "$token"
}

prepare_gateway_credentials() {
	launch_token="$(read_launch_token 2>/dev/null || true)"
	password_hash="$(hash_admin_password || true)"
	case "$password_hash" in '$2a$'*|'$2b$'*|'$2y$'*) ;; *) password_hash="" ;; esac
	[ -n "$launch_token" ] && [ -n "$password_hash" ]
}

do_install() {
	command -v docker >/dev/null 2>&1 || fail "docker is not installed"
	command -v curl >/dev/null 2>&1 || fail "curl is not installed"
	docker info >/dev/null 2>&1 || fail "docker daemon is not available"

	profile="$(uci_get image_profile)"
	[ -n "$profile" ] || profile="standard"
	image="$(resolve_profile "$profile")"
	port="$(uci_get port)"
	[ -n "$port" ] || port="13080"
	data_path="$(uci_get data_path)"
	workspace_path="$(uci_get workspace_path)"
	extra_hosts="$(uci_get extra_trusted_hosts)"
	advanced_data_path="${data_path}-advanced"

	validate_port "$port" || fail "port must be between 1024 and 65535"
	validate_storage_path "$data_path" || fail "data path must be a dedicated directory below /mnt"
	validate_storage_path "$workspace_path" || fail "workspace path must be a dedicated directory below /mnt"
	validate_storage_path "$advanced_data_path" || fail "advanced data path must be a dedicated directory below /mnt"
	[ "$data_path" != "$workspace_path" ] || fail "data and workspace paths must be different"
	[ "$advanced_data_path" != "$workspace_path" ] || fail "advanced data and workspace paths must be different"
	validate_trusted_hosts "$extra_hosts" || fail "extra trusted hosts contain unsupported characters"

	prepare_directory "$workspace_path"
	ensure_admin_key
	if [ "$profile" = "advanced" ]; then
		[ -r "$ADVANCED_GATEWAY_CONFIG" ] || fail "advanced gateway configuration is missing"
		prepare_directory "$advanced_data_path"
	else
		prepare_directory "$data_path"
	fi

	printf 'Pulling pinned DSH image: %s\n' "$image"
	expected_image="$image"
	pull_or_use_cached "$image" || fail "could not pull the selected DSH image and no verified cached copy exists"
	image="$PULLED_IMAGE_REF"
	if [ "$profile" = "advanced" ]; then
		gateway_image="$(resolve_gateway_image)"
		printf 'Pulling advanced gateway image: %s\n' "$gateway_image"
		pull_or_use_cached "$gateway_image" || fail "could not pull the advanced gateway image and no verified cached copy exists"
		gateway_image="$PULLED_IMAGE_REF"
		ensure_advanced_network
	fi

	prepare_previous

	if [ "$profile" = "advanced" ]; then
		if ! run_advanced_core; then
			restore_previous
			fail "failed to create the advanced DSH container; previous deployment restored"
		fi
	else
		if ! run_standard; then
			restore_previous
			fail "failed to create the standard DSH container; previous deployment restored"
		fi
	fi

	if ! wait_healthy "$CONTAINER_NAME"; then
		restore_previous
		fail "DSH health check failed; previous deployment restored (startup logs are not copied because they may contain a launch token)"
	fi

	if [ "$profile" = "advanced" ]; then
		if ! prepare_gateway_credentials \
			|| ! run_advanced_gateway || ! wait_advanced_gateway "$port"; then
			unset launch_token password_hash
			restore_previous
			fail "advanced DSH administrator-key gateway failed; previous deployment restored"
		fi
		unset launch_token password_hash
	fi

	docker rm -f "$ROLLBACK_NAME" "$GATEWAY_ROLLBACK_NAME" >/dev/null 2>&1 || true
	if [ "$profile" != "advanced" ]; then
		docker network rm "$ADVANCED_NETWORK" >/dev/null 2>&1 || true
	fi
	legacy_index="$data_path/.istoreos/dsh-index.html"
	if [ -f "$legacy_index" ] && [ ! -L "$legacy_index" ]; then
		rm -f "$legacy_index"
		rmdir "$data_path/.istoreos" 2>/dev/null || true
	fi
	printf 'DSH is healthy on the dedicated authenticated port.\n'
}

published_bindings() {
	container="$1"
	container_port="$2"
	docker inspect --format "{{range (index .NetworkSettings.Ports \"$container_port/tcp\")}}{{printf \"%s %s\\n\" .HostIp .HostPort}}{{end}}" "$container" 2>/dev/null
}

do_profile() {
	docker inspect --format '{{index .Config.Labels "io.istore.dsh.profile"}}' "$CONTAINER_NAME" 2>/dev/null || true
}

do_port() {
	profile="$(do_profile)"
	if [ "$profile" = "advanced" ]; then
		bindings="$(published_bindings "$GATEWAY_NAME" 13080)" || return 1
	else
		bindings="$(published_bindings "$CONTAINER_NAME" 3080)" || return 1
	fi
	port=""
	while read -r address candidate extra; do
		[ -n "$address$candidate$extra" ] || continue
		[ -z "$extra" ] || return 1
		case "$address" in 0.0.0.0|::) ;; *) return 1 ;; esac
		validate_port "$candidate" || return 1
		[ -z "$port" ] || [ "$port" = "$candidate" ] || return 1
		port="$candidate"
	done <<EOF
$bindings
EOF
	[ -z "$port" ] || printf '%s\n' "$port"
}

do_address() {
	profile="$(do_profile)"
	if [ "$profile" = "advanced" ]; then
		bindings="$(published_bindings "$GATEWAY_NAME" 13080)" || return 1
	else
		bindings="$(published_bindings "$CONTAINER_NAME" 3080)" || return 1
	fi
	printf '%s\n' "$bindings" | awk 'NF {print $1; exit}'
}

do_status() {
	state="$(docker inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || true)"
	if [ "$(do_profile)" = "advanced" ] && [ "$state" = "running" ]; then
		gateway_state="$(docker inspect --format '{{.State.Status}}' "$GATEWAY_NAME" 2>/dev/null || true)"
		[ "$gateway_state" = "running" ] || state="degraded"
	fi
	[ -z "$state" ] || printf '%s\n' "$state"
}

do_health() {
	core_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || true)"
	if [ "$(do_profile)" != "advanced" ]; then
		[ -z "$core_health" ] || printf '%s\n' "$core_health"
		return
	fi
	[ "$core_health" = "healthy" ] || {
		[ -z "$core_health" ] || printf '%s\n' "$core_health"
		return
	}
	port="$(do_port)"
	status="$(curl -sS -o /dev/null -w '%{http_code}' -H "Host: 127.0.0.1:$port" "http://127.0.0.1:$port/" 2>/dev/null || true)"
	if [ "$status" = "401" ]; then printf 'healthy\n'; else printf 'unhealthy\n'; fi
}

do_key_status() {
	if [ -f "$KEY_FILE" ] && [ ! -L "$KEY_FILE" ]; then
		printf 'configured\n'
	else
		printf 'missing\n'
	fi
}

do_launch_token() {
	[ "$(do_profile)" = "advanced" ] || return 1
	read_launch_token
}

do_refresh_gateway() {
	command -v docker >/dev/null 2>&1 || fail "docker is not installed"
	[ "$(do_profile)" = "advanced" ] || return 0
	[ "$(do_status)" = "running" ] || fail "advanced DSH core is not running"
	wait_healthy "$CONTAINER_NAME" || fail "advanced DSH core is not healthy"
	[ -r "$ADVANCED_GATEWAY_CONFIG" ] || fail "advanced gateway configuration is missing"
	port="$(uci_get port)"
	[ -n "$port" ] || port="13080"
	validate_port "$port" || fail "port must be between 1024 and 65535"
	ensure_admin_key
	gateway_image="$(resolve_gateway_image)"
	pull_or_use_cached "$gateway_image" || fail "could not pull the advanced gateway image and no verified cached copy exists"
	gateway_image="$PULLED_IMAGE_REF"
	prepare_gateway_credentials || fail "could not prepare advanced gateway credentials"

	docker rm -f "$GATEWAY_ROLLBACK_NAME" >/dev/null 2>&1 || true
	if container_exists "$GATEWAY_NAME"; then
		docker stop -t 10 "$GATEWAY_NAME" >/dev/null 2>&1 || true
		docker rename "$GATEWAY_NAME" "$GATEWAY_ROLLBACK_NAME" >/dev/null
		disconnect_rollback "$GATEWAY_ROLLBACK_NAME"
	fi
	if run_advanced_gateway && wait_advanced_gateway "$port"; then
		docker rm -f "$GATEWAY_ROLLBACK_NAME" >/dev/null 2>&1 || true
		unset launch_token password_hash
		return 0
	fi

	docker rm -f "$GATEWAY_NAME" >/dev/null 2>&1 || true
	if container_exists "$GATEWAY_ROLLBACK_NAME"; then
		docker rename "$GATEWAY_ROLLBACK_NAME" "$GATEWAY_NAME" >/dev/null
		ensure_advanced_network
		docker network connect "$ADVANCED_NETWORK" "$GATEWAY_NAME" >/dev/null 2>&1 || true
		docker start "$GATEWAY_NAME" >/dev/null 2>&1 || true
	fi
	unset launch_token password_hash
	fail "could not refresh the advanced DSH gateway"
}

do_boot() {
	count=0
	while [ "$count" -lt 120 ]; do
		if docker info >/dev/null 2>&1 && container_exists "$CONTAINER_NAME"; then
			if [ "$(do_profile)" = "advanced" ]; then
				core_health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || true)"
				if [ "$core_health" = "healthy" ]; then
					do_refresh_gateway
					return 0
				fi
			elif [ "$(do_status)" = "running" ]; then
				return 0
			fi
		fi
		count=$((count + 1))
		sleep 1
	done
	fail "timed out waiting for DSH during boot"
}

do_start() {
	docker start "$CONTAINER_NAME"
	if [ "$(do_profile)" = "advanced" ]; then
		wait_healthy "$CONTAINER_NAME" || fail "advanced DSH core did not become healthy"
		do_refresh_gateway
	fi
}

do_stop() {
	if [ "$(do_profile)" = "advanced" ] && container_exists "$GATEWAY_NAME"; then
		docker stop "$GATEWAY_NAME"
	fi
	docker stop "$CONTAINER_NAME"
}

do_rm() {
	docker rm -f "$GATEWAY_NAME" "$CONTAINER_NAME" "$GATEWAY_ROLLBACK_NAME" "$ROLLBACK_NAME" >/dev/null 2>&1 || true
	docker network rm "$ADVANCED_NETWORK" >/dev/null 2>&1 || true
}

usage() {
	printf '%s\n' \
		"usage: $0 sub-command" \
		"sub-commands: install upgrade rm start stop restart refresh-gateway boot status health port address key-status image profile launch-token"
}

ACTION="${1:-}"
case "$ACTION" in
	install|upgrade) do_install ;;
	rm) do_rm ;;
	start) do_start ;;
	stop) do_stop ;;
	restart) do_install ;;
	refresh-gateway) do_refresh_gateway ;;
	boot) do_boot ;;
	status) do_status ;;
	health) do_health ;;
	port) do_port ;;
	address) do_address ;;
	key-status) do_key_status ;;
	image) docker inspect --format '{{if index .Config.Labels "io.istore.dsh.image"}}{{index .Config.Labels "io.istore.dsh.image"}}{{else}}{{.Config.Image}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || true ;;
	profile) do_profile ;;
	launch-token) do_launch_token ;;
	*) usage; exit 1 ;;
esac
