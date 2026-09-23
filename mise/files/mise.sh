#!/bin/sh

. /lib/functions.sh

istore_runtime_quickstart_conf_dir() {
	local main_dir conf_dir

	config_load quickstart >/dev/null 2>&1 || return 1
	config_get conf_dir main conf_dir ""
	if [ -z "$conf_dir" ]; then
		config_get main_dir main main_dir ""
		[ -n "$main_dir" ] || return 1
		conf_dir="$main_dir/Configs"
	fi

	printf '%s\n' "$conf_dir"
}

istore_runtime_set_runtime_dir() {
	local conf_dir runtime_dir

	config_load mise >/dev/null 2>&1 || return 1
	config_get runtime_dir main runtime_dir ""
	[ -z "$runtime_dir" ] || return 0

	conf_dir="$(istore_runtime_quickstart_conf_dir)" || return 1
	runtime_dir="$conf_dir/Runtime/home"

	uci -q set "mise.main.runtime_dir=$runtime_dir" >/dev/null 2>&1 || return 1
	uci -q commit mise >/dev/null 2>&1
}

istore_runtime_init() {
	local runtime_dir

	config_load mise >/dev/null 2>&1 || return 1
	config_get runtime_dir main runtime_dir ""
	[ -n "$runtime_dir" ] || istore_runtime_set_runtime_dir
}

istore_runtime_env() {
	local runtime_dir

	config_load mise >/dev/null 2>&1 || return 1
	config_get runtime_dir main runtime_dir ""
	[ -n "$runtime_dir" ] || runtime_dir="${HOME:-}"
	[ -n "$runtime_dir" ] || return 1
	mkdir -p "$runtime_dir" || return 1

	export HOME="$runtime_dir"
	export PATH="$HOME/.local/share/mise/shims${PATH:+:$PATH}"
	istore_runtime_mise_accel_env
}

istore_runtime_url_available() {
	local url

	url="$1"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 3 -O /dev/null "$url" >/dev/null 2>&1
		return $?
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -fsS --max-time 3 -o /dev/null "$url" >/dev/null 2>&1
		return $?
	fi
	return 1
}

istore_runtime_mise_accel_env() {
	local download_gateway_available github_release_replacements go_mirror_url node_mirror_url port

	command -v iStoreEnhance >/dev/null 2>&1 || command -v kspeeder >/dev/null 2>&1 || return 0

	port="${KSPEEDER_PORT:-5443}"
	download_gateway_available=0
	if istore_runtime_url_available "http://127.0.0.1:5003/api/download-gateway/routes"; then
		download_gateway_available=1
	fi

	node_mirror_url="https://dl-node-unofficial.linkease.net:${port}/"
	if [ -z "${MISE_NODE_MIRROR_URL:-}" ] && istore_runtime_url_available "${node_mirror_url}index.json"; then
		export MISE_NODE_MIRROR_URL="$node_mirror_url"
		: "${MISE_NODE_VERIFY:=0}"
		export MISE_NODE_VERIFY
	fi

	go_mirror_url="https://dl-go-sdk.linkease.net:${port}"
	if [ -z "${MISE_GO_DOWNLOAD_MIRROR:-}" ] && [ "$download_gateway_available" = "1" ]; then
		export MISE_GO_DOWNLOAD_MIRROR="$go_mirror_url"
	fi

	github_release_replacements="{\"regex:^https://github\\\\.com/(.+/.+/releases/download/.+)$\":\"https://dl-github.linkease.net:${port}/\$1\"}"
	if [ -z "${MISE_URL_REPLACEMENTS:-}" ] && [ "$download_gateway_available" = "1" ]; then
		export MISE_URL_REPLACEMENTS="$github_release_replacements"
	fi
}
