#!/bin/sh
set -eu

SHARE=/usr/share/hermes
POLICY="$SHARE/runtime-policy.json"
RUNTIME="$SHARE/shared-runtime.lua"
LOCK=/tmp/hermes-native-install.lock

CHILD_PID=''
TXN=''
CANDIDATE=''
RELEASE=''
OLD_CURRENT=''
OLD_PREVIOUS=''
WAS_RUNNING=0
ACTIVATED=0
COMMITTED=0
CACHE_RESULT=''

uci_get() { uci -q get "hermes.@main[0].$1" 2>/dev/null || true; }
json_get() { jsonfilter -i "$1" -e "$2"; }

base_dir() {
	value="$(uci_get native_base_dir)"
	case "$value" in /mnt/*) ;; *) echo "Configure a persistent Native data directory first" >&2; return 1 ;; esac
	case "$value" in *[!a-zA-Z0-9_./-]*|*/../*|*/..|*/./*|*/.|*/|/mnt) echo "Invalid Native data directory" >&2; return 1 ;; esac
	printf '%s\n' "$value"
}

account() {
	id hermes >/dev/null 2>&1 || { echo "Dedicated hermes account is missing" >&2; return 1; }
	[ "$(id -u hermes)" -gt 0 ] || return 1
}

log_line() {
	message="$1"
	line="$(date '+%Y-%m-%d %H:%M:%S') [hermes-native] $message"
	printf '%s\n' "$line"
	base="$(base_dir 2>/dev/null || true)"
	if [ -n "$base" ] && [ -d "$base/log" ] && [ ! -L "$base/log" ]; then
		printf '%s\n' "$line" >> "$base/log/installer.log" 2>/dev/null || true
	fi
}

join_child() {
	[ -n "$CHILD_PID" ] || return 0
	kill -TERM -"$CHILD_PID" 2>/dev/null || kill -TERM "$CHILD_PID" 2>/dev/null || true
	n=0
	while kill -0 "$CHILD_PID" 2>/dev/null && [ "$n" -lt 10 ]; do n=$((n + 1)); sleep 1; done
	kill -KILL -"$CHILD_PID" 2>/dev/null || kill -KILL "$CHILD_PID" 2>/dev/null || true
	wait "$CHILD_PID" 2>/dev/null || true
	CHILD_PID=''
}

run_owned() {
	setsid "$@" &
	CHILD_PID=$!
	if wait "$CHILD_PID"; then rc=0; else rc=$?; fi
	CHILD_PID=''
	return "$rc"
}

acquire_lock() {
	if mkdir "$LOCK" 2>/dev/null; then
		printf '%s\n' "$$" > "$LOCK/pid"
		return
	fi
	[ -d "$LOCK" ] || { echo "Invalid Hermes Native installer lock" >&2; return 1; }
	pid="$(cat "$LOCK/pid" 2>/dev/null || true)"
	case "$pid" in ''|*[!0-9]*) ;; *)
		if kill -0 "$pid" 2>/dev/null; then
			echo "Another Hermes Native operation is active (pid $pid)" >&2
			return 2
		fi
	;; esac
	for entry in "$LOCK"/*; do
		[ ! -e "$entry" ] || [ "$entry" = "$LOCK/pid" ] || {
			echo "Unknown Hermes Native lock contents" >&2; return 1;
		}
	done
	rm -f "$LOCK/pid"
	rmdir "$LOCK" || return 1
	mkdir "$LOCK" || return 1
	printf '%s\n' "$$" > "$LOCK/pid"
}

release_lock() {
	rm -f "$LOCK/pid" 2>/dev/null || true
	rmdir "$LOCK" 2>/dev/null || true
}

switch_pointer() {
	base="$1" name="$2" target="$3"
	case "$name" in current|previous) ;; *) return 1 ;; esac
	case "$target" in releases/*) ;; *) return 1 ;; esac
	tmp="$base/.$name.$$"
	[ ! -e "$tmp" ] && [ ! -L "$tmp" ] || return 1
	ln -s "$target" "$tmp" || return 1
	mv -Tf "$tmp" "$base/$name"
}

remove_pointer() {
	path="$1"
	[ ! -e "$path" ] && [ ! -L "$path" ] && return 0
	[ -L "$path" ] || return 1
	rm "$path"
}

pointer_valid() {
	base="$1" pointer="$2"
	case "$pointer" in releases/*) ;; *) return 1 ;; esac
	name="${pointer#releases/}"
	case "$name" in ''|.*|*[!a-zA-Z0-9._-]*) return 1 ;; esac
	[ -d "$base/$pointer" ] && [ ! -L "$base/$pointer" ]
}

journal_value() {
	name="$1" value="$2"
	printf '%s\n' "$value" > "$TXN/$name.new"
	mv -f "$TXN/$name.new" "$TXN/$name"
}

phase() {
	journal_phase="$1"
	journal_value phase "$journal_phase"
	log_line "Installation phase: $journal_phase"
}

download() {
	url="$1" sha="$2" output="$3"
	if [ -f "$output.part" ] && printf '%s  %s\n' "$sha" "$output.part" | sha256sum -c - >/dev/null 2>&1; then
		mv "$output.part" "$output"
		return
	fi
	run_owned curl --disable -fL -C - --retry 5 --retry-delay 2 --connect-timeout 15 \
		--speed-limit 1024 --speed-time 30 --max-time 900 -o "$output.part" "$url" || return 1
	if ! printf '%s  %s\n' "$sha" "$output.part" | sha256sum -c -; then
		rm -f "$output.part"
		return 1
	fi
	mv "$output.part" "$output" || return 1
}

cached_artifact() {
	url="$1" sha="$2" suffix="$3" cache="$4"
	mkdir -p "$cache"
	chmod 755 "$cache"
	archive="$cache/$sha.$suffix"
	if [ -f "$archive" ] && printf '%s  %s\n' "$sha" "$archive" | sha256sum -c - >/dev/null 2>&1; then
		CACHE_RESULT="$archive"
		return
	fi
	rm -f "$archive"
	download "$url" "$sha" "$archive" || return 1
	chmod 644 "$archive" || return 1
	CACHE_RESULT="$archive"
}

cached_source() { cached_artifact "$1" "$2" tar.gz "$3"; }

cached_named_artifact() {
	url="$1" sha="$2" filename="$3" cache="$4"
	case "$filename" in ''|*/*|*[!a-zA-Z0-9._-]*) echo "Invalid cached artifact filename" >&2; return 1 ;; esac
	directory="$cache/$sha"
	mkdir -p "$directory"
	chmod 755 "$cache" "$directory"
	artifact="$directory/$filename"
	if [ -f "$artifact" ] && printf '%s  %s\n' "$sha" "$artifact" | sha256sum -c - >/dev/null 2>&1; then
		CACHE_RESULT="$artifact"
		return
	fi
	rm -f "$artifact"
	download "$url" "$sha" "$artifact" || return 1
	chmod 644 "$artifact" || return 1
	CACHE_RESULT="$artifact"
}

extract() {
	archive="$1" target="$2"
	mkdir -p "$target"
	tar -xzf "$archive" -C "$target" --strip-components=1
}

service_json() {
	ubus call service list '{"name":"hermes-native"}' 2>/dev/null || printf '{}\n'
}

instance_running() {
	instance="$1"
	value="$(service_json | jsonfilter -e "@[\"hermes-native\"].instances.$instance.running" 2>/dev/null || true)"
	[ "$value" = true ]
}

installed() {
	base="$1"
	[ -L "$base/current" ] && [ -f "$base/current/receipt.json" ] || return 1
	/usr/bin/lua "$RUNTIME" inspect "$base/current/runtime.json" >/dev/null 2>&1
}

gateway_healthy() {
	base="$1"
	output="$base/log/gateway-status.log"
	timeout -k 2 20 /usr/bin/lua "$RUNTIME" as-app "$base/current/runtime.json" \
		--shell -c 'hermes gateway status' > "$output" 2>&1 || return 1
	grep -q 'Gateway is running' "$output"
}

health_now() {
	base="$1"
	port="$(uci_get native_port)"; case "$port" in ''|*[!0-9]*) port=18787 ;; esac
	instance_running gateway && instance_running webui || return 1
	curl --disable -fsS --noproxy '*' --max-time 3 "http://127.0.0.1:$port/health" >/dev/null 2>&1 || return 1
	gateway_healthy "$base"
}

wait_healthy() {
	base="$1" n=0
	while [ "$n" -lt 60 ]; do
		if health_now "$base"; then return 0; fi
		n=$((n + 1)); sleep 1
	done
	return 1
}

wait_stopped() {
	n=0
	while [ "$n" -lt 20 ]; do
		if ! instance_running gateway && ! instance_running webui; then return 0; fi
		n=$((n + 1)); sleep 1
	done
	return 1
}

service_stop() {
	/etc/init.d/hermes-native stop >/dev/null 2>&1 || true
	wait_stopped
}

service_start() {
	HERMES_NATIVE_FORCE_START=1 /etc/init.d/hermes-native start >/dev/null 2>&1
}

health_candidate() {
	binding="$1" webui="$2" base="$3" port="$4"
	log="$base/log/candidate-health.log"
	if curl --disable -fsS --noproxy '*' --max-time 2 "http://127.0.0.1:$port/health" >/dev/null 2>&1; then
		echo "Hermes Native candidate health port $port is already in use" >&2
		return 1
	fi
	HERMES_WEBUI_AGENT_DIR="$(dirname "$webui")/agent" \
	HERMES_WEBUI_HOST=127.0.0.1 HERMES_WEBUI_PORT="$port" \
	HERMES_WEBUI_STATE_DIR="$base/data/.hermes/webui" \
	HERMES_WEBUI_DEFAULT_WORKSPACE="$base/data/workspace" \
	HERMES_WEBUI_PYTHON="$(dirname "$binding")/venv/bin/python" \
	HERMES_WEBUI_SHUTDOWN_DRAIN_SECONDS=2 \
	HERMES_DISABLE_LAZY_INSTALLS=1 HERMES_WEBUI_AUTO_INSTALL=0 \
		setsid /usr/bin/lua "$RUNTIME" as-app "$binding" \
		python "$webui/server.py" >"$log" 2>&1 &
	CHILD_PID=$!
	n=0 ok=0
	while [ "$n" -lt 60 ]; do
		if curl --disable -fsS --noproxy '*' --max-time 2 "http://127.0.0.1:$port/health" >/dev/null 2>&1; then ok=1; break; fi
		kill -0 "$CHILD_PID" 2>/dev/null || break
		n=$((n + 1)); sleep 1
	done
	kill -TERM -"$CHILD_PID" 2>/dev/null || true
	n=0
	while [ "$n" -lt 5 ] && curl --disable -fsS --noproxy '*' --max-time 1 \
		"http://127.0.0.1:$port/health" >/dev/null 2>&1; do
		n=$((n + 1)); sleep 1
	done
	if [ "$n" -ge 5 ]; then kill -KILL -"$CHILD_PID" 2>/dev/null || true; fi
	wait "$CHILD_PID" 2>/dev/null || true
	CHILD_PID=''
	[ "$ok" = 1 ] || { echo "Hermes WebUI candidate health check failed; inspect $log" >&2; return 1; }
	! curl --disable -fsS --noproxy '*' --max-time 1 \
		"http://127.0.0.1:$port/health" >/dev/null 2>&1 || {
		echo "Hermes WebUI candidate health process did not stop" >&2; return 1;
	}
}

restore_pointers() {
	base="$1"
	service_stop || true
	if [ -n "$OLD_CURRENT" ]; then
		pointer_valid "$base" "$OLD_CURRENT" || return 1
		switch_pointer "$base" current "$OLD_CURRENT" || return 1
	else
		remove_pointer "$base/current" || return 1
	fi
	if [ -n "$OLD_PREVIOUS" ]; then
		pointer_valid "$base" "$OLD_PREVIOUS" || return 1
		switch_pointer "$base" previous "$OLD_PREVIOUS" || return 1
	else
		remove_pointer "$base/previous" || return 1
	fi
	if [ "$WAS_RUNNING" = 1 ] && [ -n "$OLD_CURRENT" ]; then
		service_start || return 1
		wait_healthy "$base" || return 1
	fi
}

prune_previous() {
	base="$1"
	previous="$(readlink "$base/previous" 2>/dev/null || true)"
	[ -n "$previous" ] || return 0
	pointer_valid "$base" "$previous" || return 1
	[ "$(readlink "$base/current" 2>/dev/null || true)" != "$previous" ] || return 1
	remove_pointer "$base/previous" || return 1
	rm -rf "$base/$previous"
}

cleanup_install() {
	rc=$?
	trap - EXIT HUP INT TERM
	join_child
	ok=1
	if [ -n "$TXN" ] && [ -d "$TXN" ] && [ "$COMMITTED" != 1 ]; then
		/usr/bin/lua "$RUNTIME" cancel "$TXN" >/dev/null 2>&1 || ok=0
	fi
	if [ "$ACTIVATED" = 1 ] && [ "$COMMITTED" != 1 ]; then
		base="$(base_dir)"
		restore_pointers "$base" || ok=0
	fi
	if [ "$COMMITTED" != 1 ] && [ -n "$CANDIDATE" ] && [ -d "$CANDIDATE" ]; then
		base="$(base_dir)"
		current="$(readlink "$base/current" 2>/dev/null || true)"
		previous="$(readlink "$base/previous" 2>/dev/null || true)"
		if [ "$current" != "releases/$RELEASE" ] && [ "$previous" != "releases/$RELEASE" ]; then
			rm -rf "$CANDIDATE"
		else ok=0
		fi
	fi
	if [ "$ok" = 1 ] && [ -n "$TXN" ] && [ -d "$TXN" ]; then rm -rf "$TXN"; fi
	release_lock
	[ "$ok" = 1 ] || rc=1
	exit "$rc"
}

signal_exit() {
	code="$1"
	join_child
	exit "$code"
}

do_install() {
	mode="$1"
	account
	base="$(base_dir)"
	/usr/bin/lua "$RUNTIME" preflight "$base"
	if [ "$mode" = install ] && installed "$base"; then
		echo already-installed
		return
	fi
	acquire_lock
	trap cleanup_install EXIT
	trap 'signal_exit 129' HUP
	trap 'signal_exit 130' INT
	trap 'signal_exit 143' TERM
	for old in "$base"/.install.*; do
		[ ! -d "$old" ] || { echo "Interrupted Hermes Native transaction; run recover first" >&2; return 1; }
	done
	mkdir -p "$base/releases" "$base/data/.hermes" "$base/data/workspace" "$base/log" "$base/cache/sources"
	[ ! -L "$base/releases" ] && [ ! -L "$base/data" ] && [ ! -L "$base/log" ] && [ ! -L "$base/cache" ] || return 1
	chown -R hermes:hermes "$base/data"
	chmod 700 "$base/data" "$base/data/.hermes"
	chmod 755 "$base" "$base/releases" "$base/log" "$base/cache" "$base/cache/sources"
	available="$(df -kP "$base" | awk 'NR==2{print $4}')"
	[ "${available:-0}" -ge 1572864 ] || { echo "Hermes Native requires at least 1.5 GiB free during installation" >&2; return 1; }
	TXN="$(mktemp -d "$base/.install.XXXXXX")"
	chmod 700 "$TXN"
	RELEASE="$(date +%Y%m%d%H%M%S)-${TXN##*.}"
	CANDIDATE="$base/releases/$RELEASE"
	[ ! -e "$CANDIDATE" ] || { echo "Hermes release identifier collision" >&2; return 1; }
	mkdir "$CANDIDATE"
	chown hermes:hermes "$CANDIDATE"
	chmod 755 "$CANDIDATE"
	OLD_CURRENT="$(readlink "$base/current" 2>/dev/null || true)"
	OLD_PREVIOUS="$(readlink "$base/previous" 2>/dev/null || true)"
	[ -z "$OLD_CURRENT" ] || pointer_valid "$base" "$OLD_CURRENT"
	[ -z "$OLD_PREVIOUS" ] || pointer_valid "$base" "$OLD_PREVIOUS"
	if instance_running gateway || instance_running webui; then WAS_RUNNING=1; fi
	journal_value release "$RELEASE"
	journal_value old-current "$OLD_CURRENT"
	journal_value old-previous "$OLD_PREVIOUS"
	journal_value was-running "$WAS_RUNNING"
	phase preparing

	agent_url="$(json_get "$POLICY" '@.agent.url')"
	agent_sha="$(json_get "$POLICY" '@.agent.sha256')"
	webui_url="$(json_get "$POLICY" '@.webui.url')"
	webui_sha="$(json_get "$POLICY" '@.webui.sha256')"
	arch="$(uname -m)"
	case "$arch" in x86_64|aarch64) ;; *) echo "Unsupported Hermes Native architecture: $arch" >&2; return 1 ;; esac
	uv_url="$(json_get "$POLICY" "@.uv.artifacts.$arch.url")"
	uv_sha="$(json_get "$POLICY" "@.uv.artifacts.$arch.sha256")"
	pyyaml_url="$(json_get "$POLICY" "@.webui.pyyaml.artifacts.$arch.url")"
	pyyaml_sha="$(json_get "$POLICY" "@.webui.pyyaml.artifacts.$arch.sha256")"
	pyyaml_name="$(json_get "$POLICY" "@.webui.pyyaml.artifacts.$arch.filename")"
	agent_version="$(json_get "$POLICY" '@.agent.version')"
	webui_version="$(json_get "$POLICY" '@.webui.version')"
	[ -n "$agent_url" ] && [ -n "$agent_sha" ] && [ -n "$webui_url" ] && [ -n "$webui_sha" ] &&
		[ -n "$uv_url" ] && [ -n "$uv_sha" ] && [ -n "$pyyaml_url" ] && [ -n "$pyyaml_sha" ] &&
		[ -n "$pyyaml_name" ]

	source=origin
	[ "$(uci_get native_install_accelerated)" = 1 ] && source=ks-cli
	run_owned /usr/bin/lua "$RUNTIME" ensure "$TXN" "$source" "$CANDIDATE" \
		> "$base/log/runtime-prepare.log" 2>&1 || {
		cat "$base/log/runtime-prepare.log" >&2; return 1;
	}
	cat "$base/log/runtime-prepare.log"
	cache="$base/cache/sources"
	cached_source "$agent_url" "$agent_sha" "$cache"; agent_archive="$CACHE_RESULT"
	cached_source "$webui_url" "$webui_sha" "$cache"; webui_archive="$CACHE_RESULT"
	cached_source "$uv_url" "$uv_sha" "$cache"; uv_archive="$CACHE_RESULT"
	cached_named_artifact "$pyyaml_url" "$pyyaml_sha" "$pyyaml_name" "$cache"; pyyaml_wheel="$CACHE_RESULT"
	extract "$agent_archive" "$CANDIDATE/agent"
	extract "$webui_archive" "$CANDIDATE/webui"
	extract "$uv_archive" "$CANDIDATE/tools"
	chown -R hermes:hermes "$CANDIDATE/agent" "$CANDIDATE/webui"
	chmod -R u+rwX,go-rwx "$CANDIDATE/agent" "$CANDIDATE/webui"
	uv_bin="$CANDIDATE/tools/uv"
	[ -x "$uv_bin" ] || { echo "Verified Hermes uv binary is missing" >&2; return 1; }

	binding="$CANDIDATE/runtime.json"
	runtime_ref="$TXN/venv-runtime.json"
	cp "$CANDIDATE/venv/.istore-python-runtime.json" "$runtime_ref"
	chown root:root "$runtime_ref"
	chmod 600 "$runtime_ref"
	install_log="$base/log/dependency-install.log"
	run_owned env UV_PROJECT_ENVIRONMENT="$CANDIDATE/venv" UV_CACHE_DIR="$base/data/.cache/uv" \
		UV_PYTHON_DOWNLOADS=never UV_LINK_MODE=copy UV_COMPILE_BYTECODE=0 \
		ISTORE_RUNTIME_ACCELERATION="$source" /usr/bin/lua "$RUNTIME" as-app "$binding" --shell -c \
		"exec '$uv_bin' sync --frozen --all-packages --no-dev --python '$CANDIDATE/venv/bin/python' --project '$CANDIDATE/agent'" \
		>"$install_log" 2>&1 || {
		echo "Hermes Agent locked dependency installation failed; inspect $install_log" >&2; return 1;
	}
	cp "$runtime_ref" "$CANDIDATE/venv/.istore-python-runtime.json"
	chown root:root "$CANDIDATE/venv/.istore-python-runtime.json"
	chmod 644 "$CANDIDATE/venv/.istore-python-runtime.json"
	run_owned env UV_CACHE_DIR="$base/data/.cache/uv" UV_PYTHON_DOWNLOADS=never UV_LINK_MODE=copy \
		ISTORE_RUNTIME_ACCELERATION="$source" /usr/bin/lua "$RUNTIME" as-app "$binding" --shell -c \
		"exec '$uv_bin' pip install --python '$CANDIDATE/venv/bin/python' --no-deps '$pyyaml_wheel'" \
		>>"$install_log" 2>&1 || {
		echo "Hermes WebUI pinned dependency installation failed; inspect $install_log" >&2; return 1;
	}
	cp "$runtime_ref" "$CANDIDATE/venv/.istore-python-runtime.json"
	chown root:root "$CANDIDATE/venv/.istore-python-runtime.json"
	chmod 644 "$CANDIDATE/venv/.istore-python-runtime.json"
	chown -R root:root "$CANDIDATE/agent" "$CANDIDATE/webui"
	chmod -R a+rX,go-w "$CANDIDATE/agent" "$CANDIDATE/webui"
	chown root:root "$CANDIDATE"
	chmod 755 "$CANDIDATE"
	/usr/bin/lua "$RUNTIME" inspect "$binding" >"$base/log/binding.log"
	run_owned /usr/bin/lua "$RUNTIME" as-app "$binding" python -c \
		'import hermes_cli,openai,httpx,yaml,cryptography; print("hermes-imports-ok")' >"$base/log/import.log"
	run_owned /usr/bin/lua "$RUNTIME" as-app "$binding" --shell -c 'hermes --version' >"$base/log/cli-version.log"
	health_port="$(uci_get native_health_port)"; case "$health_port" in ''|*[!0-9]*) health_port=18788 ;; esac
	[ "$health_port" -gt 1024 ] 2>/dev/null && [ "$health_port" -le 65535 ] 2>/dev/null || return 1
	[ "$health_port" != "$(uci_get native_port)" ] || { echo "Candidate health port must differ from Native service port" >&2; return 1; }
	health_candidate "$binding" "$CANDIDATE/webui" "$base" "$health_port"

	printf '{"schema_version":1,"agent":"%s","webui":"%s","verified":true,"installed_at":%s}\n' \
		"$agent_version" "$webui_version" "$(date +%s)" >"$CANDIDATE/receipt.json"
	chmod 644 "$CANDIDATE/receipt.json"
	printf '%s\n' managed-by=hermes-native >"$base/.hermes-native.managed"
	phase ready
	if [ -n "$OLD_CURRENT" ]; then switch_pointer "$base" previous "$OLD_CURRENT"; else remove_pointer "$base/previous"; fi
	switch_pointer "$base" current "releases/$RELEASE"
	ACTIVATED=1
	phase activated
	service_stop || return 1
	service_start || return 1
	wait_healthy "$base" || { echo "Activated Hermes Native services failed health checks" >&2; return 1; }
	phase committed
	COMMITTED=1
	if [ "$WAS_RUNNING" != 1 ] && [ "$(uci_get native_enabled)" != 1 ]; then service_stop || return 1; fi
	# The old release exists only for transactional rollback. Reclaim it after
	# the replacement has passed both service health checks so a 2 GiB-free
	# appliance can perform the next upgrade as well.
	prune_previous "$base"
	if [ -n "$OLD_PREVIOUS" ] && [ "$OLD_PREVIOUS" != "$OLD_CURRENT" ] &&
		[ "$(readlink "$base/current" 2>/dev/null || true)" != "$OLD_PREVIOUS" ] &&
		[ "$(readlink "$base/previous" 2>/dev/null || true)" != "$OLD_PREVIOUS" ]; then
		if pointer_valid "$base" "$OLD_PREVIOUS"; then rm -rf "$base/$OLD_PREVIOUS"; fi
	fi
	echo "Hermes Native $mode completed: $RELEASE"
}

do_status() {
	base="$(base_dir)"
	if ! installed "$base"; then echo uninstalled; return 0; fi
	if instance_running gateway && instance_running webui; then echo running
	elif instance_running gateway || instance_running webui; then echo degraded
	else echo stopped
	fi
}

do_health() {
	base="$(base_dir)"
	installed "$base" || { echo uninstalled; return 1; }
	health_now "$base" || { echo unhealthy; return 1; }
	echo healthy
}

do_start() {
	base="$(base_dir)"
	installed "$base" || { echo "Hermes Native is not installed" >&2; return 1; }
	if health_now "$base"; then echo already-running; return; fi
	service_stop || return 1
	service_start || return 1
	wait_healthy "$base" || { echo "Hermes Native failed to become healthy" >&2; return 1; }
	echo started
}

do_stop() {
	service_stop || { echo "Hermes Native failed to stop" >&2; return 1; }
	echo stopped
}

do_restart() {
	do_stop >/dev/null
	do_start >/dev/null
	echo restarted
}

do_cancel() {
	[ -d "$LOCK" ] || { echo no-active-install; return 0; }
	pid="$(cat "$LOCK/pid" 2>/dev/null || true)"
	case "$pid" in ''|*[!0-9]*) echo "Invalid installer pid" >&2; return 1 ;; esac
	[ -r "/proc/$pid/cmdline" ] || { echo "Installer lock is stale; run recover" >&2; return 1; }
	cmdline="$(tr '\000' ' ' < "/proc/$pid/cmdline")"
	case "$cmdline" in *hermes-native.sh*install*|*hermes-native.sh*upgrade*) ;; *) echo "Lock owner is not a Hermes installer" >&2; return 1 ;; esac
	kill -TERM "$pid"
	n=0
	while [ -d "$LOCK" ] && [ "$n" -lt 90 ]; do n=$((n + 1)); sleep 1; done
	[ ! -d "$LOCK" ] || { echo "Hermes Native cancellation did not settle" >&2; return 1; }
	echo cancelled
}

do_recover() {
	base="$(base_dir)"
	acquire_lock
	trap release_lock EXIT HUP INT TERM
	count=0 recover_txn=''
	for item in "$base"/.install.*; do
		[ -d "$item" ] || continue
		[ ! -L "$item" ] || return 1
		count=$((count + 1)); recover_txn="$item"
	done
	[ "$count" -le 1 ] || { echo "Multiple interrupted Hermes transactions require manual inspection" >&2; return 1; }
	if [ "$count" = 0 ]; then echo no-interrupted-install; return 0; fi
	TXN="$recover_txn"
	RELEASE="$(cat "$TXN/release")"
	OLD_CURRENT="$(cat "$TXN/old-current")"
	OLD_PREVIOUS="$(cat "$TXN/old-previous")"
	WAS_RUNNING="$(cat "$TXN/was-running")"
	recover_phase="$(cat "$TXN/phase")"
	case "$RELEASE" in ''|.*|*[!a-zA-Z0-9._-]*) return 1 ;; esac
	case "$WAS_RUNNING" in 0|1) ;; *) return 1 ;; esac
	[ -z "$OLD_CURRENT" ] || pointer_valid "$base" "$OLD_CURRENT"
	[ -z "$OLD_PREVIOUS" ] || pointer_valid "$base" "$OLD_PREVIOUS"
	CANDIDATE="$base/releases/$RELEASE"
	/usr/bin/lua "$RUNTIME" cancel "$TXN" || return 1
	case "$recover_phase" in
		committed)
			[ "$(readlink "$base/current" 2>/dev/null || true)" = "releases/$RELEASE" ] || return 1
			installed "$base" || return 1
			prune_previous "$base"
			;;
		preparing|ready|activated)
			if [ "$(readlink "$base/current" 2>/dev/null || true)" = "releases/$RELEASE" ]; then
				ACTIVATED=1
				restore_pointers "$base" || return 1
			fi
			if [ -d "$CANDIDATE" ] &&
				[ "$(readlink "$base/current" 2>/dev/null || true)" != "releases/$RELEASE" ] &&
				[ "$(readlink "$base/previous" 2>/dev/null || true)" != "releases/$RELEASE" ]; then
				rm -rf "$CANDIDATE"
			fi
			;;
		*) echo "Unknown Hermes recovery phase" >&2; return 1 ;;
	esac
	rm -rf "$TXN"
	TXN=''
	echo recovered
}

do_remove() {
	base="$(base_dir)"
	acquire_lock
	trap release_lock EXIT HUP INT TERM
	for item in "$base"/.install.*; do
		[ ! -d "$item" ] || { echo "Recover interrupted installation before removal" >&2; return 1; }
	done
	service_stop || return 1
	remove_pointer "$base/current"
	remove_pointer "$base/previous"
	[ ! -e "$base/releases" ] || { [ -d "$base/releases" ] && [ ! -L "$base/releases" ]; }
	rm -rf "$base/releases"
	uci -q set 'hermes.@main[0].native_enabled=0'
	uci -q commit hermes
	echo "removed-runtime-data-preserved"
}

do_purge() {
	base="$(base_dir)"
	acquire_lock
	trap release_lock EXIT HUP INT TERM
	service_stop || return 1
	[ ! -L "$base" ] && [ "$(readlink -f "$base")" = "$base" ] || return 1
	[ "$(cat "$base/.hermes-native.managed" 2>/dev/null || true)" = managed-by=hermes-native ] || {
		echo "Refusing to purge an unmanaged directory" >&2; return 1;
	}
	for item in "$base"/.install.*; do
		[ ! -d "$item" ] || { echo "Recover interrupted installation before purge" >&2; return 1; }
	done
	rm -rf "$base"
	uci -q set 'hermes.@main[0].native_enabled=0'
	uci -q commit hermes
	echo purged
}

do_logs() {
	base="$(base_dir)"
	lines="${1:-200}"
	case "$lines" in ''|*[!0-9]*) return 1 ;; esac
	[ "$lines" -ge 1 ] && [ "$lines" -le 2000 ] || return 1
	if [ -f "$base/log/installer.log" ]; then tail -n "$lines" "$base/log/installer.log"; fi
	logread 2>/dev/null | grep -i 'hermes-native\|gateway.run' | tail -n "$lines" || true
}

usage() {
	echo "usage: $0 install|upgrade|start|stop|restart|status|health|port|logs [lines]|cancel|recover|remove|rm|purge" >&2
}

case "${1:-}" in
	install) do_install install ;;
	upgrade) do_install upgrade ;;
	start) do_start ;;
	stop) do_stop ;;
	restart) do_restart ;;
	status) do_status ;;
	health) do_health ;;
	port) value="$(uci_get native_port)"; echo "${value:-18787}" ;;
	logs) do_logs "${2:-200}" ;;
	cancel) do_cancel ;;
	recover) do_recover ;;
	remove) do_remove ;;
	rm) do_remove ;;
	purge) do_purge ;;
	*) usage; exit 2 ;;
esac
