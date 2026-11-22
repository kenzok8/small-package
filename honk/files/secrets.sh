#!/bin/sh
# Listener secrets live in their own include (secrets.dae).
#
# The core decides writability per file: a source that declares a
# native_api / clash_api secret (even an empty one) is read-only, so Doona
# cannot add subscriptions or nodes there. Keeping the secret in this include
# keeps config.dae writable.

HONK_SECRETS_FILE=secrets.dae

# A single-quoted dae string cannot hold quotes, backslashes, tabs or newlines.
honk_secret_value_ok() {
	case "$1" in ''|*"'"*|*\\*) return 1 ;; esac
	[ "$(printf '%s' "$1" | wc -l)" -eq 0 ] || return 1
	[ "$(printf '%s' "$1" | tr -d '\t')" = "$1" ] || return 1
	[ "$(printf '%s' "$1" | wc -c)" -le 512 ]
}

# honk_secrets_render [clash secret] [native secret]
# With no value the file keeps comments only: it must be includable yet carry no secret key.
honk_secrets_render() {
	_secrets_clash=${1:-}
	_secrets_native=${2:-}
	if [ -z "$_secrets_clash" ] && [ -z "$_secrets_native" ]; then
		cat <<'EOF'
# 监听器密钥专用文件，由面板按 UCI 的 Clash API 设置生成。
# 现在没有密钥。不要把 secret 写回 config.dae：主配置出现 secret 字段，
# 核心就会把整份配置标成只读，doona 里新增订阅和节点会被拒绝。
EOF
		return 0
	fi
	printf '# 监听器密钥专用文件，由面板生成；不要写回 config.dae，否则整份配置会变成只读。\n'
	printf 'experimental {\n'
	if [ -n "$_secrets_native" ]; then
		printf "    native_api {\n        secret: '%s'\n    }\n" "$_secrets_native"
	fi
	if [ -n "$_secrets_clash" ]; then
		printf "    clash_api {\n        secret: '%s'\n    }\n" "$_secrets_clash"
	fi
	printf '}\n'
}

# honk_secrets_split <source> <main out> <native out> <clash out>
# Pulls the native_api / clash_api secret lines out of a config file.
#   0 split; 1 no secret line; 2 layout not understood (nested block); 3 unreadable.
# <main out> is always written: secret lines removed, every other byte kept.
honk_secrets_split() {
	_hs_src=$1
	_hs_main=$2
	_hs_native=$3
	_hs_clash=$4
	[ -f "$_hs_src" ] && [ ! -L "$_hs_src" ] || return 3
	: > "$_hs_native" && : > "$_hs_clash" || return 3
	awk -v main_out="$_hs_main" -v native_out="$_hs_native" -v clash_out="$_hs_clash" '
		BEGIN {
			q = sprintf("%c", 39)
			sect = ""; found = 0; bad = 0; native = ""; clash = ""
		}
		{
			line = $0
			if (sect == "") {
				if (line ~ /^[ \t]*native_api[ \t]*\{[ \t]*(#.*)?$/) { sect = "native_api"; print; next }
				if (line ~ /^[ \t]*clash_api[ \t]*\{[ \t]*(#.*)?$/) { sect = "clash_api"; print; next }
				print; next
			}
			if (line ~ /^[ \t]*secret[ \t]*:/) {
				value = line
				sub(/^[ \t]*secret[ \t]*:[ \t]*/, "", value)
				sub(/[ \t]+$/, "", value)
				if (substr(value, 1, 1) == q) {
					value = substr(value, 2)
					idx = index(value, q)
					if (idx) value = substr(value, 1, idx - 1)
				}
				else if (substr(value, 1, 1) == "\"") {
					value = substr(value, 2)
					idx = index(value, "\"")
					if (idx) value = substr(value, 1, idx - 1)
				}
				else {
					sub(/[ \t#].*$/, "", value)
				}
				if (sect == "native_api") native = value
				else clash = value
				found++
				next
			}
			if (line ~ /\{/) { bad = 1; print; next }
			if (line ~ /^[ \t]*\}[ \t]*(#.*)?$/) { sect = ""; print; next }
			print; next
		}
		END {
			printf "%s", native > native_out
			printf "%s", clash > clash_out
			if (bad) exit 2
			if (!found) exit 1
		}
	' "$_hs_src" > "$_hs_main"
	_hs_status=$?
	case "$_hs_status" in
		0) return 0 ;;
		1) return 1 ;;
		2) return 2 ;;
		*) return 3 ;;
	esac
}

# Blank a clash_api bind that serves without a credential off loopback.
# Prints the previous bind address when it changed the file; exits 1 when nothing changed.
honk_secrets_blank_open_clash() {
	_bs_file=$1
	[ -f "$_bs_file" ] && [ ! -L "$_bs_file" ] || return 1
	_bs_temp=$(mktemp "$(dirname "$_bs_file")/.clash-bind.XXXXXX") || return 1
	_bs_hint=$(awk -v out="$_bs_temp" '
		BEGIN { in_clash = 0; changed = 0; q = sprintf("%c", 39) }
		{
			line = $0
			if (line ~ /^[ \t]*clash_api[ \t]*\{[ \t]*(#.*)?$/) { in_clash = 1; print > out; next }
			if (in_clash && line ~ /^[ \t]*\}[ \t]*(#.*)?$/) { in_clash = 0; print > out; next }
			if (in_clash && line ~ /^[ \t]*external_controller[ \t]*:/) {
				value = line
				sub(/^[ \t]*external_controller[ \t]*:[ \t]*/, "", value)
				sub(/[ \t]+$/, "", value)
				if (substr(value, 1, 1) == q) {
					value = substr(value, 2)
					idx = index(value, q)
					if (idx) value = substr(value, 1, idx - 1)
				}
				else if (substr(value, 1, 1) == "\"") {
					value = substr(value, 2)
					idx = index(value, "\"")
					if (idx) value = substr(value, 1, idx - 1)
				}
				# Loopback and already-empty binds stay as they are.
				if (value == "" || value ~ /^(127\.|\[::1\]|::1:|localhost)/) { print > out; next }
				match($0, /^[ \t]*/)
				printf "%sexternal_controller: %c%c\n", substr($0, 1, RLENGTH), q, q > out
				print value > "/dev/stdout"
				changed = 1
				next
			}
			print > out
		}
		END { exit (changed ? 0 : 1) }
	' "$_bs_file") || { rm -f "$_bs_temp"; return 1; }
	chmod 0600 "$_bs_temp" && mv -f "$_bs_temp" "$_bs_file" || { rm -f "$_bs_temp"; return 1; }
	printf '%s\n' "$_bs_hint"
	return 0
}
