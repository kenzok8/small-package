#!/bin/sh

. /lib/functions.sh

ISTORE_RUNTIME_DEFAULT_SUBDIR="Runtime"
ISTORE_RUNTIME_HOME_SUBDIR="home"

istore_runtime_uci_section() {
	if uci -q get mise.main >/dev/null 2>&1; then
		printf 'main\n'
		return 0
	fi

	printf ''
	return 1
}

istore_runtime_quickstart_conf_dir() {
	local main_dir conf_dir

	config_load quickstart >/dev/null 2>&1 || return 1
	config_get main_dir main main_dir ""
	[ -n "$main_dir" ] || return 1
	config_get conf_dir main conf_dir "$main_dir/Configs"
	[ -n "$conf_dir" ] || return 1

	printf '%s\n' "$conf_dir"
}

istore_runtime_linkease_conf_dir() {
	local local_home

	local_home="$(uci -q get linkease.@linkease[0].local_home 2>/dev/null || true)"
	[ -n "$local_home" ] || return 1

	printf '%s/Configs\n' "$local_home"
}

istore_runtime_env_conf_dir() {
	[ -n "$ISTORE_RUNTIME_CONF_DIR" ] || return 1
	printf '%s\n' "$ISTORE_RUNTIME_CONF_DIR"
}

istore_runtime_discover_dir() {
	local conf_dir

	conf_dir="$(istore_runtime_env_conf_dir 2>/dev/null || true)"
	if [ -z "$conf_dir" ]; then
		conf_dir="$(istore_runtime_quickstart_conf_dir 2>/dev/null || true)"
	fi
	if [ -z "$conf_dir" ]; then
		conf_dir="$(istore_runtime_linkease_conf_dir 2>/dev/null || true)"
	fi
	[ -n "$conf_dir" ] || return 1

	printf '%s/%s\n' "$conf_dir" "$ISTORE_RUNTIME_DEFAULT_SUBDIR"
}

istore_runtime_dir() {
	local section runtime_dir auto_discover

	section="$(istore_runtime_uci_section 2>/dev/null || true)"
	if [ -n "$section" ]; then
		config_load mise >/dev/null 2>&1 || true
		config_get runtime_dir "$section" runtime_dir ""
		config_get_bool auto_discover "$section" auto_discover 1
		if [ -n "$runtime_dir" ]; then
			printf '%s\n' "$runtime_dir"
			return 0
		fi
		[ "$auto_discover" = "1" ] || return 1
	fi

	istore_runtime_discover_dir
}

istore_runtime_home() {
	local runtime_dir

	runtime_dir="$(istore_runtime_dir)" || return 1
	printf '%s/%s\n' "$runtime_dir" "$ISTORE_RUNTIME_HOME_SUBDIR"
}

istore_runtime_init() {
	local runtime_dir runtime_home section

	runtime_dir="$(istore_runtime_dir)" || return 1
	runtime_home="$runtime_dir/$ISTORE_RUNTIME_HOME_SUBDIR"

	mkdir -p \
		"$runtime_home/.local/share/mise" \
		"$runtime_home/.cache/mise" \
		"$runtime_home/.config/mise" \
		"$runtime_home/.local/state/mise" \
		"$runtime_home/.local/bin" || return 1

	section="$(istore_runtime_uci_section 2>/dev/null || true)"
	if [ -n "$section" ]; then
		uci -q set "mise.$section.runtime_dir=$runtime_dir" >/dev/null 2>&1 || true
		uci -q commit mise >/dev/null 2>&1 || true
	fi

	printf '%s\n' "$runtime_home"
}

istore_runtime_export_env() {
	local runtime_home

	runtime_home="$(istore_runtime_init)" || return 1

	export HOME="$runtime_home"
	export XDG_DATA_HOME="$HOME/.local/share"
	export XDG_CACHE_HOME="$HOME/.cache"
	export XDG_CONFIG_HOME="$HOME/.config"
	export XDG_STATE_HOME="$HOME/.local/state"
	export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
	export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
	export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
	export MISE_STATE_DIR="$XDG_STATE_HOME/mise"
	export PATH="$MISE_DATA_DIR/shims:$HOME/.local/bin:$PATH"
}
