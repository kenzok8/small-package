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
	local conf_dir runtime_dir storage_root

	config_load mise >/dev/null 2>&1 || return 1
	config_get runtime_dir main runtime_dir ""
	[ -z "$runtime_dir" ] || return 0
	config_get storage_root main storage_root ""

	if [ -n "$storage_root" ]; then
		runtime_dir="$storage_root/home"
	else
		conf_dir="$(istore_runtime_quickstart_conf_dir)" || return 1
		runtime_dir="$conf_dir/Runtime/home"
	fi

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
	local runtime_dir storage_root nearest

	config_load mise >/dev/null 2>&1 || return 1
	config_get runtime_dir main runtime_dir ""
	# Keep explicitly configured legacy HOME values. New installations use the
	# selected shared root; resolving HOME does not write UCI or contact network.
	if [ -z "$runtime_dir" ]; then
		config_get storage_root main storage_root ""
		[ -z "$storage_root" ] || runtime_dir="$storage_root/home"
	fi
	[ -n "$runtime_dir" ] || { logger -t mise 'Configure a persistent runtime_dir; HOME fallback is disabled'; return 1; }
	case "$runtime_dir" in /mnt/*) ;; *) return 1 ;; esac
	case "$runtime_dir" in *[!a-zA-Z0-9_./-]*|*/../*|*/..|*/./*|*/.|*//*|*/) return 1 ;; esac
	nearest="$runtime_dir"
	while [ ! -d "$nearest" ]; do nearest="${nearest%/*}"; [ -n "$nearest" ] || return 1; done
	[ "$(readlink -f "$nearest")" = "$nearest" ] || return 1
	# Validate before mkdir: an absent data mount must never consume overlay.
	awk -v target="$runtime_dir" '
		($2 == target || index(target, $2 "/") == 1) && length($2) > best {
			best=length($2);dev=$1;point=$2;kind=$3;opts="," $4 ","
		}
		END { exit !(index(point,"/mnt/")==1 && index(dev,"/dev/")==1 && kind!="tmpfs" && kind!="overlay" && index(opts,",ro,")==0 && index(opts,",noexec,")==0) }
	' /proc/mounts || return 1
	mkdir -p "$runtime_dir" || return 1

	export HOME="$runtime_dir"
	export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache" XDG_DATA_HOME="$HOME/.local/share"
	export XDG_STATE_HOME="$HOME/.local/state"
	export PATH="$HOME/.local/share/mise/shims${PATH:+:$PATH}"
	# Local SDK execution and shell startup must never depend on the network.
	return 0
}

istore_runtime_mise_exec() {
	local acceleration

	# Only explicit acquisition commands opt into ks-cli. Its current generic
	# mise profile also preflights `exec`, which would couple local apps to the
	# accelerator's availability. Everything else keeps native mise semantics.
	case "${1:-}" in
		install|i|upgrade|up|ls-remote|latest|outdated)
			config_load mise >/dev/null 2>&1 || return 1
			config_get acceleration main acceleration "1"
			if [ "$acceleration" != "0" ] &&
				[ -z "${MISE_NODE_MIRROR_URL:-}${MISE_GO_DOWNLOAD_MIRROR:-}${MISE_URL_REPLACEMENTS:-}" ] &&
				command -v ks-cli >/dev/null 2>&1; then
				exec ks-cli mise "$@"
			fi
			;;
	esac
	exec /usr/bin/mise "$@"
}
