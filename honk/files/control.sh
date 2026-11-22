#!/bin/sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

HONK_CORE=/usr/bin/honk-core
HONK_MAINT_DIR=/etc/.honk-maintenance
HONK_MAINT_JOURNAL=$HONK_MAINT_DIR/journal
HONK_MAINT_CAP_FILE=$HONK_MAINT_DIR/capability

. /lib/functions.sh
. /usr/share/honk/lock.sh
. /usr/share/honk/lifecycle.sh
. /usr/share/honk/secrets.sh

fail() {
	echo "honk: $*" >&2
	return 1
}

load_settings() {
	config_load honk
	config_get_bool enabled main enabled 0
	config_get_bool boot_enabled main boot_enabled 0
	config_get_bool initialized main initialized 0
	config_get config_file main config_file /etc/honk/config.dae
	config_get listen_port main listen_port 9527
	config_get_bool clash_api_enabled main clash_api_enabled 0
	config_get clash_api_port main clash_api_port 9090
	config_get clash_api_secret main clash_api_secret ''
	config_get lan_network main lan_network lan
	settings_owner=$(config_owner "$config_file")
}

valid_clash_api() {
	[ "$clash_api_enabled" = 1 ] || return 0
	case "$clash_api_port" in ''|*[!0-9]*) return 1 ;; esac
	[ "$clash_api_port" -ge 1024 ] && [ "$clash_api_port" -le 65535 ] || return 1
	[ "$clash_api_port" != "$listen_port" ] || return 1
	case "$clash_api_secret" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac
	[ "${#clash_api_secret}" -ge 6 ] && [ "${#clash_api_secret}" -le 128 ]
}

valid_network_name() {
	case "$lan_network" in
		''|*[!A-Za-z0-9_.-]*) return 1 ;;
		*) return 0 ;;
	esac
}

module_loaded() {
	[ -d "/sys/module/$1" ] || grep -q "^$1 " /proc/modules
}

# check_config caches this from the parsed core output; never guess when missing.
nfqueue_enabled() {
	[ "${runtime_nfqueue_enable:-}" = true ]
}

module_available() {
	module_loaded "$1" && return 0
	module_path=$(printf '%s' "$1" | tr '_' '-')
	module_dir=/lib/modules/$(uname -r)
	[ -r "$module_dir/modules.builtin" ] && grep -Eq "/${1}\.ko$|/${module_path}\.ko$" "$module_dir/modules.builtin" && return 0
	find "$module_dir" -type f \( -name "$1.ko" -o -name "$1.ko.gz" -o -name "$1.ko.xz" -o -name "$1.ko.zst" \
		-o -name "$module_path.ko" -o -name "$module_path.ko.gz" -o -name "$module_path.ko.xz" -o -name "$module_path.ko.zst" \) -print 2>/dev/null | grep -q .
}

system_config_readonly() {
	permissions=$(ls -ldn /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$permissions" = '-rw-------' ] && return 0
	[ "$permissions" = '-r--r--r--' ] && ! grep -q 'clash_api {' /etc/honk/system.dae
}

no_honk_resources() {
	honk_lifecycle_reclaim_resources || :
	for link in dae0 dae0peer; do
		ip link show "$link" >/dev/null 2>&1 && { fail "$link 已存在（上次没有正常退出），请先停止服务或执行系统恢复"; return 1; }
	done
	ip netns list 2>/dev/null | awk '{print $1}' | grep -qx daens && { fail "daens 网络命名空间已存在，请先停止服务或执行系统恢复"; return 1; }
	return 0
}

check_port() {
	checked_port=${1:-$listen_port}
	if command -v netstat >/dev/null 2>&1; then
		netstat -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${checked_port}$" && { fail "监听端口已被占用，请换一个端口"; return 1; }
	elif command -v ss >/dev/null 2>&1; then
		ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${checked_port}$" && { fail "监听端口已被占用，请换一个端口"; return 1; }
	else
		fail "缺少 netstat/ss，无法检查端口占用（装 ip-full 或 net-tools）"
		return 1
	fi
	return 0
}

check_network() {
	valid_network_name || { fail "LAN 网络名包含非法字符"; return 1; }
	command -v ubus >/dev/null 2>&1 || { fail "ubus 不可用，无法校验网络设置"; return 1; }
	ubus call "network.interface.$lan_network" status >/dev/null 2>&1 || { fail "选择的 LAN 网络在 netifd 里不存在，请在服务设置里重新选择"; return 1; }
}

# Local addresses (IPv4+IPv6) by device, link-local skipped; never by UCI name.
# WAN device, so the local public address also stays direct; skipped when unknown.
network_wan_device() {
	. /lib/functions/network.sh 2>/dev/null || return 0
	wan_dev=
	network_get_device wan_dev wan 2>/dev/null || return 0
	case "$wan_dev" in ''|*[!A-Za-z0-9_.:-]*) return 0 ;; esac
	printf '%s\n' "$wan_dev"
}

local_direct_addresses() {
	list=''
	for dev in "$@"; do
		case "$dev" in ''|*[!A-Za-z0-9_.:-]*) continue ;; esac
		for addr in $(ip -o addr show dev "$dev" 2>/dev/null | awk '{ print $4 }' | cut -d/ -f1); do
			case "$addr" in fe80:*|169.254.*) continue ;; esac
			case "$addr" in ''|*[!0-9a-fA-F:.]*) continue ;; esac
			[ "${#addr}" -le 45 ] || continue
			case " $list " in *" $addr "*) continue ;; esac
			list="${list:+$list, }$addr"
		done
	done
	printf '%s\n' "$list"
}

# Only explicit paths (first boot, reset, merge preview) refresh the marker block.
sync_local_direct() {
	target=${1:-/etc/honk/config.dae}
	begin='    # honk:local-direct-begin'
	end='    # honk:local-direct-end'
	[ -f "$target" ] && [ ! -L "$target" ] || return 1
	grep -qxF "$begin" "$target" || return 0
	grep -qxF "$end" "$target" || return 0
	shift
	ips=$(local_direct_addresses "$@")
	[ -n "$ips" ] && rule="    dip($ips) && !dport(53) -> direct(must)" || rule=''
	# honk-core only accepts .dae, and includes resolve from this directory
	temp=$(dirname "$target")/.local-direct.$$.dae
	( umask 077; : > "$temp" ) || return 1
	awk -v begin="$begin" -v end="$end" -v rule="$rule" '
		$0 == begin { print; if (rule != "") print rule; skip = 1; next }
		skip && $0 == end { print; skip = 0; next }
		skip { next }
		{ print }
	' "$target" > "$temp" || { rm -f "$temp"; return 1; }
	cmp -s "$temp" "$target" && { rm -f "$temp"; return 0; }
	chmod 0600 "$temp"
	mv -f "$temp" "$target" || { rm -f "$temp"; return 1; }
}

check_config() {
	runtime_nfqueue_enable=
	runtime_native_api_enabled=
	runtime_native_api_listen=
	runtime_clash_api_listen=
	config_error=
	[ "$config_file" = /etc/honk/config.dae ] || { fail "配置路径必须为 /etc/honk/config.dae"; return 1; }
	[ -f /etc/honk/config.dae ] && [ ! -L /etc/honk/config.dae ] || { fail "/etc/honk/config.dae 不是普通文件（可能被替换成软链）"; return 1; }
	# A fixable hint beats the core's raw error when the store is corrupt.
	state_db=/etc/honk/state/honk.db
	if [ -f "$state_db" ] && [ ! -L "$state_db" ] && command -v sqlite3 >/dev/null 2>&1; then
		state_check=$(sqlite3 "$state_db" 'PRAGMA quick_check;' 2>/dev/null) || state_check=failed
		[ "$state_check" = ok ] || { config_error=state_database_corrupt; fail "状态数据库损坏，请到维护页执行重置"; return 1; }
	fi
	core_validation_result=$("$HONK_CORE" config validate --config /etc/honk/config.dae) || { fail "config.dae 未通过静态校验，请先修正配置"; return 1; }
	runtime_nfqueue_enable=$(printf '%s\n' "$core_validation_result" | jsonfilter -e '@.runtime.nfqueue_enable' 2>/dev/null)
	case "$runtime_nfqueue_enable" in
		true|false) ;;
		*) config_error=nfqueue_runtime_unavailable; fail "honk-core 无法报告解析后的 nfqueue_enable，请更新 Honk 核心"; return 1 ;;
	esac
	runtime_native_api_enabled=$(printf '%s\n' "$core_validation_result" | jsonfilter -e '@.runtime.native_api_enabled' 2>/dev/null)
	runtime_native_api_listen=$(printf '%s\n' "$core_validation_result" | jsonfilter -e '@.runtime.native_api_listen' 2>/dev/null)
	runtime_clash_api_listen=$(printf '%s\n' "$core_validation_result" | jsonfilter -e '@.runtime.clash_api_listen' 2>/dev/null)
	config_error=
	[ -r /usr/share/doona/index.html ] || { fail "缺少 Doona 静态文件（/usr/share/doona/index.html），请重新安装 luci-app-honk"; return 1; }
	[ "$settings_owner" = system ] || return 0
	[ -f /etc/honk/system.dae ] && [ ! -L /etc/honk/system.dae ] || { fail "/etc/honk/system.dae 不是普通文件（可能被替换成软链）"; return 1; }
	system_config_readonly || { fail "/etc/honk/system.dae 权限不对，应为 0600"; return 1; }

}

# Same order as honk-core: HONK_VMLINUX_BTF wins when set
kernel_btf_path() {
	if [ -n "${HONK_VMLINUX_BTF:-}" ]; then
		[ -r "$HONK_VMLINUX_BTF" ] && { printf '%s\n' "$HONK_VMLINUX_BTF"; return 0; }
		return 1
	fi
	for btf_file in /sys/kernel/btf/vmlinux /usr/lib/debug/boot/vmlinux; do
		[ -r "$btf_file" ] && { printf '%s\n' "$btf_file"; return 0; }
	done
	return 1
}

check_kernel() {
	kernel_error=""
	kernel=$(uname -r | cut -d- -f1)
	major=$(printf '%s' "$kernel" | cut -d. -f1)
	minor=$(printf '%s' "$kernel" | cut -d. -f2)
	if [ "$(jsonfilter -i /usr/share/honk/core-capabilities.json -e '@.lane' 2>/dev/null)" = linux66 ]; then
		expected_hash=$(jsonfilter -i /usr/share/honk/core-capabilities.json -e '@.core_sha256' 2>/dev/null)
		actual_hash=$(sha256sum "$HONK_CORE" 2>/dev/null | cut -d' ' -f1)
		[ -n "$expected_hash" ] && [ "$expected_hash" = "$actual_hash" ] || { kernel_error=core_capabilities_mismatch; fail "核心与兼容信息不匹配，请重新安装 honk"; return 1; }
		patch=$(printf '%s' "$kernel" | cut -d. -f3 | sed 's/[^0-9].*//')
		[ "$major" -gt 6 ] || { [ "$major" -eq 6 ] && { [ "$minor" -gt 6 ] || { [ "$minor" -eq 6 ] && [ "${patch:-0}" -ge 40 ]; }; }; } || { kernel_error=kernel_compat_too_old; fail "兼容核心需要 Linux 6.6.40 或更新"; return 1; }
	else
		[ "$major" -gt 6 ] || { [ "$major" -eq 6 ] && [ "$minor" -ge 12 ]; } || { kernel_error=kernel_too_old; fail "内核版本过低，需要 Linux 6.12 或更新"; return 1; }
	fi
	if ! kernel_btf_path >/dev/null; then
		if [ -n "${HONK_VMLINUX_BTF:-}" ]; then
			kernel_error=kernel_btf_override_invalid
			fail "HONK_VMLINUX_BTF 指向的 $HONK_VMLINUX_BTF 不可读，honk-core 不会回退到默认路径"
		else
			kernel_error=kernel_btf_missing
			fail "内核缺少 BTF（/sys/kernel/btf/vmlinux 或 /usr/lib/debug/boot/vmlinux），需装与 uname -r 同版本的 vmlinux-btf（https://github.com/kenzok8/vmlinux-btf/releases/tag/latest），或换用自带 BTF 的固件"
		fi
		return 1
	fi
	[ -d /sys/fs/bpf ] && grep -q ' /sys/fs/bpf bpf ' /proc/mounts || { kernel_error=bpffs_not_mounted; fail "bpffs 未挂载到 /sys/fs/bpf，请检查内核或手工挂载"; return 1; }
	command -v ip >/dev/null 2>&1 || { kernel_error=ip_full_missing; fail "缺少 ip 命令（装 ip-full）"; return 1; }
	command -v modprobe >/dev/null 2>&1 || { kernel_error=kmod_missing; fail "缺少 modprobe 命令（装 kmod）"; return 1; }
	for module in sch_ingress cls_bpf veth; do
		module_available "$module" || { kernel_error="kernel_module_missing:$module"; fail "缺少内核模块 $module，请确认 kmod-sched-core / kmod-sched-bpf / kmod-veth 已安装"; return 1; }
	done
	if nfqueue_enabled; then
		for module in nft_queue nfnetlink_queue; do
			module_available "$module" || { kernel_error="kernel_module_missing:$module"; fail "缺少内核模块 $module，装 kmod-nft-queue，或在 global 里设 nfqueue_enable: false"; return 1; }
		done
	fi
}

check_conflicts() {
	for process in dae daed clashoo mihomo sing-box; do
		pidof "$process" >/dev/null 2>&1 && { fail "检测到冲突进程 $process 正在运行，请先停掉它（多代理同时开会互相抢流量）"; return 1; }
	done
	for service in dae daed clashoo mihomo sing-box; do
		if [ -x "/etc/init.d/$service" ] && "/etc/init.d/$service" running >/dev/null 2>&1; then
			fail "检测到冲突服务 $service 正在运行，请先停用它（多代理同时开会互相抢流量）"
			return 1
		fi
	done
}

maintenance_value() {
	awk -F= -v key="$1" '$1 == key { value = substr($0, length($1) + 2); count++ } END { if (count == 1) print value; else exit 1 }' "$2"
}

proc_starttime() {
	[ -r "/proc/$1/stat" ] || return 1
	awk '{ sub(/^.*\) /, ""); split($0, fields, /[[:space:]]+/); if (fields[20] ~ /^[0-9]+$/) print fields[20]; else exit 1 }' "/proc/$1/stat" 2>/dev/null
}

protected_root_file() {
	[ -f "$1" ] && [ ! -L "$1" ] || return 1
	protected_permissions=$(ls -ln "$1" 2>/dev/null | awk 'NR == 1 { print $1 ":" $3 ":" $4 }')
	[ "$protected_permissions" = '-rw-------:0:0' ]
}

consume_maintenance_capability() {
	[ -n "${HONK_MAINT_CAP:-}" ] || return 1
	[ -d "$HONK_MAINT_DIR" ] && [ ! -L "$HONK_MAINT_DIR" ] || return 1
	protected_root_file "$HONK_MAINT_JOURNAL" && protected_root_file "$HONK_MAINT_CAP_FILE" || return 1
	awk -F= 'BEGIN { split("format nonce txn_id phase owner_pid owner_starttime", keys, " ") } NR > 6 || index($0, "=") == 0 || $1 != keys[NR] { exit 1 } END { if (NR != 6) exit 1 }' "$HONK_MAINT_CAP_FILE" || return 1
	consumed_cap=$HONK_MAINT_DIR/.capability-consumed.$$
	[ ! -e "$consumed_cap" ] || return 1
	mv "$HONK_MAINT_CAP_FILE" "$consumed_cap" 2>/dev/null || return 1
	# Chain with any existing EXIT trap instead of overwriting it.
	_prev_exit_trap=$(trap -p EXIT | sed "s/^trap -- '//;s/' EXIT$//")
	trap 'rm -f "$consumed_cap"; [ -n "$_prev_exit_trap" ] && eval "$_prev_exit_trap"' 0
	cap_format=$(maintenance_value format "$consumed_cap") || return 1
	cap_nonce=$(maintenance_value nonce "$consumed_cap") || return 1
	cap_txn=$(maintenance_value txn_id "$consumed_cap") || return 1
	cap_phase=$(maintenance_value phase "$consumed_cap") || return 1
	cap_pid=$(maintenance_value owner_pid "$consumed_cap") || return 1
	cap_starttime=$(maintenance_value owner_starttime "$consumed_cap") || return 1
	journal_format=$(maintenance_value format "$HONK_MAINT_JOURNAL") || return 1
	journal_operation=$(maintenance_value operation "$HONK_MAINT_JOURNAL") || return 1
	journal_phase=$(maintenance_value phase "$HONK_MAINT_JOURNAL") || return 1
	journal_txn=$(maintenance_value txn_id "$HONK_MAINT_JOURNAL") || return 1
	case "$cap_nonce:$cap_txn:$cap_pid:$cap_starttime" in *[!0-9a-f:]*|::*|:|'' ) return 1 ;; esac
	case "$cap_nonce" in *[!0-9a-f]*|'') return 1 ;; esac
	[ "${#cap_nonce}" -eq 32 ] && [ "${#cap_txn}" -eq 32 ] || return 1
	[ "$cap_format" = 1 ] && [ "$journal_format" = 1 ] || return 1
	case "$cap_pid:$cap_starttime" in *[!0-9:]*) return 1 ;; esac
	[ "$cap_pid" -gt 1 ] && [ "$cap_starttime" -gt 0 ] || return 1
	[ "$HONK_MAINT_CAP" = "$cap_nonce" ] && [ "$cap_txn" = "$journal_txn" ] || return 1
	case "$cap_phase:$journal_operation:$journal_phase" in
		candidate_health_start:restore:new_installed|candidate_health_start:import_apply:new_installed|rollback_old_start:restore:rollback_old_start|rollback_old_start:reset:rollback_old_start|rollback_old_start:import_apply:rollback_old_start) ;;
		*) return 1 ;;
	esac
	read -r lock_pid lock_starttime < "$HONK_LOCK_DIR/pid" || return 1
	[ "$lock_pid:$lock_starttime" = "$cap_pid:$cap_starttime" ] || return 1
	[ "$(proc_starttime "$cap_pid")" = "$cap_starttime" ] || return 1
	return 0
}

maintenance_start_guard() {
	if [ -e "$HONK_MAINT_JOURNAL" ] || [ -L "$HONK_MAINT_JOURNAL" ]; then
		consume_maintenance_capability || { fail "maintenance_recovery_required"; return 1; }
	elif [ -n "${HONK_MAINT_CAP:-}" ]; then
		fail "maintenance_capability_without_journal"
		return 1
	fi
	if lock_owner_invalid || honk_lock_is_stale; then
		# The recorded owner is gone, so nothing is in flight. Reclaim the lock
		# instead of refusing every later start: a caller that timed out cannot
		# release it, and leaving it wedges the service until someone SSHes in.
		# A live lock still blocks below through honk_lock_acquire.
		logger -t honk "reclaiming stale operation lock" 2>/dev/null || :
		rm -rf "$HONK_LOCK_DIR"
	fi
}

lock_owner_invalid() {
	[ -d "$HONK_LOCK_DIR" ] || return 1
	lock_owner=$(cat "$HONK_LOCK_DIR/pid" 2>/dev/null)
	# pid file now stores "pid starttime"; only the leading PID matters here.
	lock_owner=${lock_owner%% *}
	case "$lock_owner" in ''|*[!0-9]*) return 0 ;; esac
	return 1
}

check_runtime_ports() {
	runtime_port_error=
	if [ "$runtime_native_api_enabled" = true ]; then
		runtime_port=$(printf '%s\n' "$runtime_native_api_listen" | awk -F: '{print $NF}')
		case "$runtime_port" in ''|*[!0-9]*) runtime_port_error=invalid_package_config; return 1 ;; esac
		check_port "$runtime_port" || { runtime_port_error=listen_port_occupied; return 1; }
	fi
	if [ -n "$runtime_clash_api_listen" ]; then
		runtime_port=$(printf '%s\n' "$runtime_clash_api_listen" | awk -F: '{print $NF}')
		case "$runtime_port" in ''|*[!0-9]*) runtime_port_error=invalid_package_config; return 1 ;; esac
		check_port "$runtime_port" || { runtime_port_error=clash_api_port_occupied; return 1; }
	fi
}

# Move a listener secret still in config.dae into secrets.dae.
# Any doubt leaves files untouched: read-only beats a service that will not start.
migrate_listener_secret() {
	_mig_cfg=/etc/honk/config.dae
	_inc=
	[ "$(config_owner "$_mig_cfg")" = file ] || return 0
	config_includes_secrets "$_mig_cfg" >/dev/null && _inc=1
	_mig_dir=$(mktemp -d /tmp/honk-secrets.XXXXXX) || return 0
	honk_secrets_split "$_mig_cfg" "$_mig_dir/config.dae" "$_mig_dir/native" "$_mig_dir/clash"
	_mig_status=$?
	case "$_mig_status" in
		0) ;;
		1) rm -rf "$_mig_dir"; return 0 ;;
		*) rm -rf "$_mig_dir"; logger -t honk "listener secret stays in config.dae: unsupported layout"; return 0 ;;
	esac
	_mig_native=$(cat "$_mig_dir/native" 2>/dev/null)
	_mig_clash=$(cat "$_mig_dir/clash" 2>/dev/null)
	{ [ -z "$_mig_native" ] || honk_secret_value_ok "$_mig_native"; } || { rm -rf "$_mig_dir"; logger -t honk "listener secret stays in config.dae: unsupported value"; return 0; }
	{ [ -z "$_mig_clash" ] || honk_secret_value_ok "$_mig_clash"; } || { rm -rf "$_mig_dir"; logger -t honk "listener secret stays in config.dae: unsupported value"; return 0; }
	if [ -z "$_inc" ]; then
		{ printf 'include {\n    %s\n}\n' "$HONK_SECRETS_FILE"; cat "$_mig_dir/config.dae"; } > "$_mig_dir/config.inc" || { rm -rf "$_mig_dir"; return 0; }
		mv -f "$_mig_dir/config.inc" "$_mig_dir/config.dae" || { rm -rf "$_mig_dir"; return 0; }
	fi
	# Validate inside /etc/honk: includes resolve from the entry directory.
	_mig_candidate=/etc/honk/.config-secrets.$$.dae
	cp "$_mig_dir/config.dae" "$_mig_candidate" && chmod 0600 "$_mig_candidate" || { rm -rf "$_mig_dir"; rm -f "$_mig_candidate"; return 0; }
	if [ -z "$_inc" ]; then
		_mig_secrets=/etc/honk/secrets.dae
		cp -p "$_mig_secrets" "$_mig_dir/secrets.prev" 2>/dev/null && _mig_had=1
		honk_secrets_render "$_mig_clash" "$_mig_native" > "$_mig_dir/secrets.new" || { rm -rf "$_mig_dir"; rm -f "$_mig_candidate"; return 0; }
		_mig_temp=$(mktemp /etc/honk/.secrets.dae.XXXXXX) || { rm -rf "$_mig_dir"; rm -f "$_mig_candidate"; return 0; }
		cp "$_mig_dir/secrets.new" "$_mig_temp" && chmod 0600 "$_mig_temp" && mv -f "$_mig_temp" "$_mig_secrets" || {
			rm -f "$_mig_temp"
			rm -rf "$_mig_dir"
			rm -f "$_mig_candidate"
			return 0
		}
	fi
	if ! "$HONK_CORE" config validate --config "$_mig_candidate" >/dev/null 2>&1; then
		if [ -z "$_inc" ] && [ "${_mig_had:-0}" = 1 ]; then
			mv -f "$_mig_dir/secrets.prev" "$_mig_secrets" 2>/dev/null
		elif [ -z "$_inc" ]; then
			rm -f "$_mig_secrets"
		fi
		rm -rf "$_mig_dir"
		rm -f "$_mig_candidate"
		return 0
	fi
	if [ ! -e /etc/honk/config-before-secrets.dae ]; then
		cp -p "$_mig_cfg" /etc/honk/config-before-secrets.dae 2>/dev/null && chmod 0600 /etc/honk/config-before-secrets.dae 2>/dev/null
	fi
	if ! mv -f "$_mig_candidate" "$_mig_cfg"; then
		rm -f "$_mig_candidate"
		rm -rf "$_mig_dir"
		return 0
	fi
	chmod 0600 "$_mig_cfg" 2>/dev/null
	# Only the secret is recorded; whether the API is enabled stays the user's choice.
	[ -z "$_mig_clash" ] || uci -q set "honk.main.clash_api_secret=$_mig_clash" || :
	[ -z "$_mig_clash" ] || uci -q commit honk || :
	logger -t honk "listener secret moved to $HONK_SECRETS_FILE; config.dae is writable again"
	rm -rf "$_mig_dir"
	return 0
}

# A clash_api without a credential off loopback stays open to the whole LAN; close it.
# Any doubt leaves the file alone, and a failed validation puts the original back.
close_open_clash_api() {
	_oc_cfg=/etc/honk/config.dae
	[ -f "$_oc_cfg" ] && [ ! -L "$_oc_cfg" ] || return 0
	# Nothing to do when a non-empty secret is already configured, here or in the include.
	if grep -qE "^[[:space:]]*secret[[:space:]]*:[[:space:]]*['\"]?[^'\"[:space:]]" "$_oc_cfg" 2>/dev/null; then return 0; fi
	if [ -f /etc/honk/secrets.dae ] && [ ! -L /etc/honk/secrets.dae ] &&
		grep -qE "^[[:space:]]*secret[[:space:]]*:[[:space:]]*['\"]?[^'\"[:space:]]" /etc/honk/secrets.dae 2>/dev/null; then
		return 0
	fi
	_oc_dir=$(mktemp -d /tmp/honk-clash.XXXXXX) || return 0
	cp -p "$_oc_cfg" "$_oc_dir/orig.dae" || { rm -rf "$_oc_dir"; return 0; }
	_oc_candidate=/etc/honk/.config-clash.$$.dae
	cp -p "$_oc_cfg" "$_oc_candidate" && chmod 0600 "$_oc_candidate" || { rm -rf "$_oc_dir"; rm -f "$_oc_candidate"; return 0; }
	_oc_bind=$(honk_secrets_blank_open_clash "$_oc_candidate") || { rm -rf "$_oc_dir"; rm -f "$_oc_candidate"; return 0; }
	if ! "$HONK_CORE" config validate --config "$_oc_candidate" >/dev/null 2>&1; then
		rm -rf "$_oc_dir"
		rm -f "$_oc_candidate"
		return 0
	fi
	if [ ! -e /etc/honk/config-before-clash.dae ]; then
		cp -p "$_oc_dir/orig.dae" /etc/honk/config-before-clash.dae 2>/dev/null &&
			chmod 0600 /etc/honk/config-before-clash.dae 2>/dev/null
	fi
	mv -f "$_oc_candidate" "$_oc_cfg" || { rm -rf "$_oc_dir"; rm -f "$_oc_candidate"; return 0; }
	chmod 0600 "$_oc_cfg" 2>/dev/null
	logger -t honk "clash API had no secret on $_oc_bind; disabled it (enable it from the panel with a secret)"
	rm -rf "$_oc_dir"
	return 0
}

preflight() {
	load_settings
	[ "$enabled" = 1 ] && [ "$initialized" = 1 ] || { fail "请先在 LuCI 里启用并完成初始化"; return 1; }
	migrate_listener_secret
	close_open_clash_api
	maintenance_start_guard && check_config && check_kernel && no_honk_resources && check_conflicts && check_runtime_ports
}

prepare_runtime() {
	preflight || return 1
	for module in sch_ingress cls_bpf veth; do
		module_loaded "$module" || modprobe "$module" || { fail "无法加载内核模块 $module，请确认对应 kmod 包已安装"; return 1; }
	done
	if nfqueue_enabled; then
		for module in nft_queue nfnetlink_queue; do
			module_loaded "$module" || modprobe "$module" || { fail "无法加载内核模块 $module，请确认对应 kmod 包已安装"; return 1; }
		done
	fi
	mkdir -p /etc/honk/state || { fail "无法创建状态目录（/etc/honk/state），请检查磁盘空间与权限"; return 1; }
	chmod 0700 /etc/honk/state || return 1
}

valid_username() {
	case "$1" in
		''|*[!A-Za-z0-9_.-]*) return 1 ;;
	esac
	[ "$(printf '%s' "$1" | wc -c)" -le 64 ]
}

valid_password() {
	password_bytes=$(printf '%s' "$1" | wc -c)
	[ "$password_bytes" -ge 8 ] && [ "$password_bytes" -le 512 ]
}

read_credentials() {
	json_file=$(mktemp /tmp/honk-credentials.XXXXXX) || return 1
	chmod 0600 "$json_file" || { rm -f "$json_file"; return 1; }
	cat > "$json_file" || { rm -f "$json_file"; return 1; }
	json_bytes=$(wc -c < "$json_file")
	[ "$json_bytes" -le 2048 ] || { rm -f "$json_file"; return 1; }
	grep -Fq '\u0000' "$json_file" && { rm -f "$json_file"; return 1; }
	newline='
'
	username_raw=$(jsonfilter -i "$json_file" -e '@.username' 2>/dev/null; printf '__HNK_END__')
	password_raw=$(jsonfilter -i "$json_file" -e '@.password' 2>/dev/null; printf '__HNK_END__')
	username=${username_raw%__HNK_END__}
	password=${password_raw%__HNK_END__}
	username=${username%"$newline"}
	password=${password%"$newline"}
	rm -f "$json_file"
	[ -n "$username" ] && [ -n "$password" ] || return 1
	valid_username "$username" && valid_password "$password"
}

network_settings() {
	. /lib/functions/network.sh
	network_get_device lan_device "$lan_network" || return 1
	network_get_ipaddr lan_ip "$lan_network" || return 1
	case "$lan_device" in
		''|*[!A-Za-z0-9_.-]*) return 1 ;;
	esac
	[ "$(printf '%s' "$lan_device" | wc -c)" -le 15 ] || return 1
	printf '%s\n' "$lan_ip" | awk -F. 'NF == 4 { for (i=1;i<=4;i++) if ($i !~ /^[0-9]+$/ || $i > 255) exit 1; exit 0 } { exit 1 }' || return 1
}

initialize_install_main() {
	install_source=$1
	install_target=$2
	install_expected_hash=$3
	install_dir=$(dirname "$install_target")
	install_name=$(basename "$install_target")
	[ -f "$install_source" ] && [ ! -L "$install_source" ] && [ -f "$install_target" ] && [ ! -L "$install_target" ] || { initialize_error=write_failed; return 1; }
	install_temp=$(mktemp "$install_dir/.$install_name.XXXXXX") || { initialize_error=write_failed; return 1; }
	cp -p "$install_source" "$install_temp" && chmod 0600 "$install_temp" || { rm -f "$install_temp"; initialize_error=write_failed; return 1; }
	[ -f "$install_target" ] && [ ! -L "$install_target" ] || { rm -f "$install_temp"; initialize_error=main_changed; return 1; }
	install_current_hash=$(sha256sum "$install_target" 2>/dev/null | awk '{print $1}')
	[ "$install_current_hash" = "$install_expected_hash" ] || { rm -f "$install_temp"; initialize_error=main_changed; return 1; }
	candidate_hash=$(sha256sum "$install_temp" | awk '{print $1}')
	main_install_pending=1
	mv -f "$install_temp" "$install_target" || { rm -f "$install_temp"; initialize_error=write_failed; return 1; }
	main_install_pending=0
	main_written=1
}

initialize_restore_main() {
	_restore_target=$1
	_restore_backup=$2
	_restore_candidate_hash=$3
	_restore_original_hash=$4
	[ -f "$_restore_backup" ] && [ ! -L "$_restore_backup" ] && [ -f "$_restore_target" ] && [ ! -L "$_restore_target" ] || return 1
	_restore_backup_hash=$(sha256sum "$_restore_backup" 2>/dev/null | awk '{print $1}')
	[ "$_restore_backup_hash" = "$_restore_original_hash" ] || return 1
	_restore_current_hash=$(sha256sum "$_restore_target" 2>/dev/null | awk '{print $1}')
	[ "$_restore_current_hash" != "$_restore_original_hash" ] || return 0
	[ "$_restore_current_hash" = "$_restore_candidate_hash" ] || return 1
	_restore_dir=$(dirname "$_restore_target")
	_restore_name=$(basename "$_restore_target")
	_restore_temp=$(mktemp "$_restore_dir/.$_restore_name.restore.XXXXXX") || return 1
	cp -p "$_restore_backup" "$_restore_temp" || { rm -f "$_restore_temp"; return 1; }
	[ -f "$_restore_target" ] && [ ! -L "$_restore_target" ] || { rm -f "$_restore_temp"; return 1; }
	_restore_current_hash=$(sha256sum "$_restore_target" 2>/dev/null | awk '{print $1}')
	[ "$_restore_current_hash" = "$_restore_candidate_hash" ] || { rm -f "$_restore_temp"; return 1; }
	mv -f "$_restore_temp" "$_restore_target" || { rm -f "$_restore_temp"; return 1; }
}

# Initialization writes the secret to secrets.dae; config.dae keeps the include.
initialize_install_secrets() {
	_sec_source=$1
	_sec_target=/etc/honk/secrets.dae
	[ -f "$_sec_source" ] && [ ! -L "$_sec_source" ] || { initialize_error=write_failed; return 1; }
	if [ -e "$_sec_target" ] || [ -L "$_sec_target" ]; then
		[ -f "$_sec_target" ] && [ ! -L "$_sec_target" ] || { initialize_error=write_failed; return 1; }
		cp -p "$_sec_target" "$temp_dir/secrets.prev" || { initialize_error=write_failed; return 1; }
		secrets_had_previous=1
	fi
	_sec_temp=$(mktemp /etc/honk/.secrets.dae.XXXXXX) || { initialize_error=write_failed; return 1; }
	cp "$_sec_source" "$_sec_temp" && chmod 0600 "$_sec_temp" || { rm -f "$_sec_temp"; initialize_error=write_failed; return 1; }
	mv -f "$_sec_temp" "$_sec_target" || { rm -f "$_sec_temp"; initialize_error=write_failed; return 1; }
	secrets_written=1
}

initialize_restore_secrets() {
	_sec_target=/etc/honk/secrets.dae
	if [ "${secrets_had_previous:-0}" = 1 ] && [ -f "$temp_dir/secrets.prev" ]; then
		_sec_temp=$(mktemp /etc/honk/.secrets.dae.XXXXXX) || return 1
		cp -p "$temp_dir/secrets.prev" "$_sec_temp" && chmod 0600 "$_sec_temp" || { rm -f "$_sec_temp"; return 1; }
		mv -f "$_sec_temp" "$_sec_target" || { rm -f "$_sec_temp"; return 1; }
		return 0
	fi
	rm -f "$_sec_target"
}

cleanup_initialize() {
	if mock_stop >/dev/null 2>&1; then
		retain_snapshot=0
		if [ "${initialize_committed:-0}" != 1 ]; then
			if [ "${secrets_written:-0}" = 1 ]; then
				initialize_restore_secrets || retain_snapshot=1
			fi
			if [ "${main_written:-0}" = 1 ] || [ "${main_install_pending:-0}" = 1 ]; then
				initialize_restore_main "${main_config_path:-/etc/honk/config.dae}" "$old_main" "$candidate_hash" "$original_main_hash" || retain_snapshot=1
				if [ ! -f "$old_uci" ] || { ! uci import honk < "$old_uci" || ! uci commit honk || ! chmod 0600 /etc/config/honk; }; then
					retain_snapshot=1
				fi
			fi
		fi
		if [ "$retain_snapshot" = 1 ]; then
			logger -t honk "initialization rollback incomplete; snapshot retained at $temp_dir"
		else
			rm -rf "$temp_dir"
		fi
		honk_lock_release >/dev/null 2>&1
	else
		logger -t honk "mock process cleanup failed; keeping operation lock and temporary files"
	fi
}

# Also used when handing the layout back, so both paths render it the same.
render_runtime_system() {
	_nfq=$(sed -n 's/^    nfqueue_enable: \(true\|false\)$/\1/p' /etc/honk/system.dae 2>/dev/null | head -n 1)
	case "$_nfq" in true|false) ;; *) _nfq=true ;; esac
	printf "global {\n    wan_interface: auto\n    lan_interface: '%s'\n" "$1"
	printf "    log_level: info\n    dial_mode: domain\n    allow_insecure: false\n"
	printf "    auto_config_kernel_parameter: true\n    data_dir: '/etc/honk'\n"
	printf "    store_subscribe: true\n    nfqueue_enable: %s\n}\n\n" "$_nfq"
	printf "experimental {\n    native_api {\n        enabled: true\n        listen: '%s:%s'\n" "$2" "$3"
	printf "        password_auth: true\n        allow_anonymous_loopback: false\n"
	printf "        config_write: true\n        ui: '/usr/share/doona'\n    }\n"
	if [ "$clash_api_enabled" = 1 ]; then
		printf "    clash_api {\n        external_controller: '%s:%s'\n        external_ui: '/usr/share/honk/zashboard'\n        secret: '%s'\n        default_mode: Rule\n    }\n" "$2" "$clash_api_port" "$clash_api_secret"
	fi
	printf "}\n"
}

# With a user-managed system.dae the panel does not touch it.
system_is_managed() {
	_managed=$(uci -q get honk.main.system_managed)
	[ -z "$_managed" ] || [ "$_managed" = 1 ]
}

managed_core_pid() {
	honk_lifecycle_managed_pid
}

configured_system_port() {
	sed -n "s/^[[:space:]]*listen:[[:space:]]*'[^:]*:\([0-9][0-9]*\)'.*/\1/p" /etc/honk/system.dae 2>/dev/null | head -n 1
}

configured_clash_port() {
	sed -n "s/^[[:space:]]*external_controller:[[:space:]]*'[^:]*:\([0-9][0-9]*\)'.*/\1/p" /etc/honk/system.dae 2>/dev/null | head -n 1
}

sync_boot_link() {
	if [ "$1" = 1 ]; then
		/etc/init.d/honk enable
	else
		/etc/init.d/honk disable
	fi
}

settings_rollback() {
	uci import honk < "$old_uci" && uci commit honk || return 1
	sync_boot_link "$old_boot_enabled"
}

# Return 0 when pre-init runtime intent needs checks, 1 for flag-only, 2 for a forbidden live edit.
settings_runtime_plan() {
	runtime_settings_changed=0
	[ "$new_network" = "$lan_network" ] && [ "$new_port" = "$listen_port" ] && \
		[ "$new_clash_enabled" = "$clash_api_enabled" ] && [ "$new_clash_port" = "$clash_api_port" ] && \
		[ "$new_clash_secret" = "$clash_api_secret" ] || runtime_settings_changed=1
	if [ "$initialized" = 1 ]; then
		[ "$runtime_settings_changed" = 0 ] || return 2
		return 1
	fi
	[ "${runtime_fields_provided:-0}" = 1 ] || return 1
	return 0
}

settings_network_preflight() {
	[ "$runtime_checks" = 1 ] || return 0
	check_network || { settings_network_error=lan_network_unavailable; return 1; }
	network_settings || { settings_network_error=lan_ipv4_unavailable; return 1; }
}

settings() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	load_settings
	. /usr/share/libubox/jshn.sh || { echo '{"ok":false,"message":"jshn_unavailable"}'; return 1; }
	# Bound stdin to 64KiB (DoS protection); read one extra byte to detect truncation.
	settings_json=$(head -c 65537)
	if [ "${#settings_json}" -gt 65536 ]; then
		echo '{"ok":false,"message":"settings_too_large"}'; return 1
	fi
	json_load "$settings_json" || { echo '{"ok":false,"message":"invalid_settings_json"}'; return 1; }
	json_get_var new_network lan_network
	json_get_type network_type lan_network
	json_get_var new_port listen_port
	json_get_type port_type listen_port
	json_get_var new_boot_enabled boot_enabled
	json_get_type boot_enabled_type boot_enabled
	json_get_var new_clash_enabled clash_api_enabled
	json_get_type clash_enabled_type clash_api_enabled
	json_get_var new_clash_port clash_api_port
	json_get_type clash_port_type clash_api_port
	json_get_var new_clash_secret clash_api_secret
	json_get_type clash_secret_type clash_api_secret
	# boot_enabled is implicit (always 1) and no longer submitted; keep the value
	case "$boot_enabled_type" in ''|null|boolean) ;; *) echo '{"ok":false,"message":"invalid_boolean_settings"}'; return 1 ;; esac
	case "$clash_enabled_type" in ''|null|boolean) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_port_type" in ''|null|int|integer) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_secret_type" in ''|null|string) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	load_settings
	runtime_fields_provided=0
	case "$network_type" in
		''|null) new_network=$lan_network ;;
		string) runtime_fields_provided=1 ;;
		*) echo '{"ok":false,"message":"invalid_lan_network"}'; return 1 ;;
	esac
	case "$port_type" in
		''|null) new_port=$listen_port ;;
		int|integer) runtime_fields_provided=1 ;;
		*) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;;
	esac
	case "$boot_enabled_type" in ''|null) new_boot_enabled=1 ;; esac
	new_boot_enabled=1
	case "$clash_enabled_type" in ''|null) new_clash_enabled=$clash_api_enabled ;; boolean) runtime_fields_provided=1 ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_port_type" in ''|null) new_clash_port=$clash_api_port ;; int|integer) runtime_fields_provided=1 ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_secret_type" in ''|null) new_clash_secret=$clash_api_secret ;; string) runtime_fields_provided=1 ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	[ -n "$new_clash_secret" ] || new_clash_secret=$clash_api_secret
	settings_runtime_plan
	settings_plan=$?
	if [ "$settings_plan" = 2 ]; then
		echo '{"ok":false,"message":"runtime_settings_owned_by_file"}'
		return 1
	fi
	runtime_checks=0
	[ "$settings_plan" = 1 ] || runtime_checks=1
	if [ "$runtime_checks" = 1 ]; then
		case "$new_network" in ''|*[!A-Za-z0-9_.-]*) echo '{"ok":false,"message":"invalid_lan_network"}'; return 1 ;; esac
		case "$new_port" in ''|*[!0-9]*) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;; esac
		[ "$new_port" -ge 1024 ] && [ "$new_port" -le 65535 ] || { echo '{"ok":false,"message":"invalid_listen_port"}'; return 1; }
	fi
	new_enabled=$enabled
	old_network=$lan_network
	old_port=$listen_port
	old_enabled=$enabled
	old_boot_enabled=$boot_enabled
	old_initialized=$initialized
	old_clash_enabled=$clash_api_enabled
	old_clash_port=$clash_api_port
	old_clash_secret=$clash_api_secret
	[ "$initialized" = 1 ] || { [ "$new_enabled" = 0 ] || { echo '{"ok":false,"message":"initialize_before_enabling_service"}'; return 1; }; }
	if [ "$runtime_checks" = 1 ]; then
		lan_network=$new_network
		listen_port=$new_port
		clash_api_enabled=$new_clash_enabled
		clash_api_port=$new_clash_port
		clash_api_secret=$new_clash_secret
		valid_clash_api || { echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1; }
		settings_network_preflight || { echo "{\"ok\":false,\"message\":\"$settings_network_error\"}"; return 1; }
	fi
	old_running=0
	if [ "$runtime_checks" = 1 ]; then
		if managed_core_pid >/dev/null 2>&1; then
			old_running=1
		elif pidof honk-core >/dev/null 2>&1; then
			echo '{"ok":false,"message":"unmanaged_core_running"}'
			return 1
		fi
	fi
	if [ "$runtime_checks" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$new_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$runtime_checks" = 1 ] && [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$new_clash_port" ]; }; then
		check_port "$new_clash_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	honk_lock_acquire || { echo '{"ok":false,"message":"operation_in_progress"}'; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1' 0
	load_settings
	[ "$lan_network" = "$old_network" ] && [ "$listen_port" = "$old_port" ] && [ "$enabled" = "$old_enabled" ] && [ "$boot_enabled" = "$old_boot_enabled" ] && [ "$initialized" = "$old_initialized" ] && [ "$clash_api_enabled" = "$old_clash_enabled" ] && [ "$clash_api_port" = "$old_clash_port" ] && [ "$clash_api_secret" = "$old_clash_secret" ] || { echo '{"ok":false,"message":"settings_changed_concurrently"}'; return 1; }
	new_enabled=$enabled
	if [ "$runtime_checks" = 1 ]; then
		managed_core_pid >/dev/null 2>&1 && recheck_running=1 || recheck_running=0
		[ "$recheck_running" = "$old_running" ] || { echo '{"ok":false,"message":"service_state_changed_concurrently"}'; return 1; }
		old_running=$recheck_running
		lan_network=$new_network
		listen_port=$new_port
		clash_api_enabled=$new_clash_enabled
		clash_api_port=$new_clash_port
		clash_api_secret=$new_clash_secret
		settings_network_preflight || { echo '{"ok":false,"message":"lan_network_changed_during_settings"}'; return 1; }
	fi
	if [ "$runtime_checks" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$new_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$runtime_checks" = 1 ] && [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$new_clash_port" ]; }; then
		check_port "$new_clash_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	# This RPC stores configuration intent and boot policy; it never changes live service state.
	umask 077
	settings_dir=$(mktemp -d /tmp/honk-settings.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	old_uci=$settings_dir/honk.uci
	uci export honk > "$old_uci" || { rm -rf "$settings_dir"; echo '{"ok":false,"message":"uci_snapshot_failed"}'; return 1; }
	uci set "honk.main.lan_network=$new_network" && uci set "honk.main.listen_port=$new_port" && uci set "honk.main.enabled=$new_enabled" && uci set "honk.main.boot_enabled=$new_boot_enabled" && uci set "honk.main.clash_api_enabled=$new_clash_enabled" && uci set "honk.main.clash_api_port=$new_clash_port" && uci set "honk.main.clash_api_secret=$new_clash_secret" && uci commit honk && chmod 0600 /etc/config/honk || {
		settings_rollback; rollback_status=$?
		if [ "$rollback_status" = 0 ]; then rm -rf "$settings_dir"; echo '{"ok":false,"message":"settings_commit_failed_rolled_back"}'; else logger -t honk "settings rollback failed; snapshot retained at $settings_dir"; echo '{"ok":false,"message":"settings_commit_and_rollback_failed_snapshot_retained"}'; fi
		return 1
	}
	if ! sync_boot_link "$new_boot_enabled"; then
		settings_rollback; rollback_status=$?
		if [ "$rollback_status" = 0 ]; then rm -rf "$settings_dir"; echo '{"ok":false,"message":"boot_link_update_failed_rolled_back"}'; else logger -t honk "settings rollback failed; snapshot retained at $settings_dir"; echo '{"ok":false,"message":"boot_link_update_and_rollback_failed_snapshot_retained"}'; fi
		return 1
	fi
	rm -rf "$settings_dir"
	echo '{"ok":true,"message":"settings_saved"}'
}

# Flatten global/experimental into path=value lines, shared by lookup and compare.
system_entries() {
	# Scan character by character: a brace may share the line with a value.
	awk '
		function flush(stmt,   key, val, p, i, fields) {
			gsub(/^[[:space:]]+|[[:space:]]+$/, "", stmt)
			if (stmt == "" || d == 0) return
			if (path[1] != "global" && path[1] != "experimental") return
			if (stmt !~ /^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:/) return
			# Several fields on one line cannot be split reliably; the caller refuses.
			fields = stmt
			gsub(/"[^"]*"/, "", fields)
			gsub(/\047[^\047]*\047/, "", fields)
			if (gsub(/[A-Za-z_][A-Za-z0-9_]*[[:space:]]*:/, ":", fields) > 1) {
				print "!unsupported"
				return
			}
			key = stmt
			sub(/[[:space:]]*:.*/, "", key)
			val = stmt
			sub(/^[^:]*:[[:space:]]*/, "", val)
			if (val ~ /^\047/) { val = substr(val, 2); sub(/\047.*/, "", val) }
			else if (val ~ /^"/) { val = substr(val, 2); sub(/".*/, "", val) }
			p = path[1]
			for (i = 2; i <= d; i++) p = p "." path[i]
			print p "." key "=" val
		}
		{
			line = $0
			sub(/\r$/, "", line)
			n = length(line)
			for (i = 1; i <= n; i++) {
				c = substr(line, i, 1)
				if (quote != "") {
					buf = buf c
					if (c == quote) quote = ""
					continue
				}
				if (c == "\047" || c == "\"") { quote = c; buf = buf c; continue }
				if (c == "#") break
				if (c == "{") {
					name = buf
					sub(/[[:space:]]*:.*/, "", name)
					gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
					path[++d] = name
					buf = ""
					continue
				}
				if (c == "}") {
					flush(buf)
					buf = ""
					if (d > 0) d--
					continue
				}
				buf = buf c
			}
			flush(buf)
			buf = ""
		}
	' "$1"
}

entry_value() {
	awk -v key="$1" 'index($0, key "=") == 1 { print substr($0, length(key) + 2); exit }' "$2"
}

# Drop only top-level global/experimental; insert the include before the first block.
strip_system_blocks() {
	# First pass probes only: a duplicate include is a cycle for the core.
	awk '
		NR == FNR { if ($0 ~ /^[[:space:]]*include[[:space:]]*\{/) added = 1; next }
		skip {
			n = length($0)
			for (i = 1; i <= n; i++) {
				c = substr($0, i, 1)
				if (q != "") { if (c == q) q = ""; continue }
				if (c == "\047" || c == "\"") { q = c; continue }
				if (c == "#") break
				if (c == "{") depth++
				else if (c == "}") depth--
			}
			if (depth <= 0) skip = 0
			next
		}
		/^(global|experimental)[[:space:]]*\{/ {
			if (!added) { print "include {\n    system.dae\n}"; added = 1 }
			depth = gsub(/\{/, "{")
			depth -= gsub(/\}/, "}")
			skip = depth > 0
			next
		}
		{ print }
	' "$1" "$1"
}

device_network() {
	. /lib/functions/network.sh
	network_get_device dn_dev "$lan_network" && [ "$dn_dev" = "$1" ] && { echo "$lan_network"; return 0; }
	for dn_iface in $(ubus list 'network.interface.*' 2>/dev/null | sed 's/^network\.interface\.//'); do
		network_get_device dn_dev "$dn_iface" || continue
		[ "$dn_dev" = "$1" ] && { echo "$dn_iface"; return 0; }
	done
	return 1
}

valid_port() {
	case "$1" in ''|*[!0-9]*) return 1 ;; esac
	[ "$1" -ge 1024 ] && [ "$1" -le 65535 ]
}

detach_fail() {
	echo "{\"ok\":false,\"message\":\"$1\"}"
	return 1
}

detach_rollback() {
	dr_ok=1
	honk_lifecycle_stop 30 >/dev/null 2>&1 || dr_ok=0
	cp -p "$detach_dir/old-system.dae" /etc/honk/.system.dae.rollback && mv -f /etc/honk/.system.dae.rollback /etc/honk/system.dae || dr_ok=0
	cp -p "$detach_dir/old-config.dae" /etc/honk/.config.dae.rollback && mv -f /etc/honk/.config.dae.rollback /etc/honk/config.dae || dr_ok=0
	{ uci import honk < "$detach_dir/old.uci" && uci commit honk && chmod 0600 /etc/config/honk; } || dr_ok=0
	if [ "$dr_ok" = 1 ] && [ "$old_running" = 1 ]; then honk_lifecycle_start 30 || dr_ok=0; fi
	[ "$dr_ok" = 1 ]
}

# Hand global/experimental back to system.dae; dry_run only reports changes.
detach() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then detach_fail update_recovery_required; return 1; fi
	detach_fail configuration_page_merge_preview_required
	return 1
	. /usr/share/libubox/jshn.sh || { detach_fail jshn_unavailable; return 1; }
	detach_request=$(head -c 4096)
	dry_run=
	[ -z "$detach_request" ] || json_load "$detach_request" 2>/dev/null || { detach_fail invalid_request; return 1; }
	[ -z "$detach_request" ] || json_get_var dry_run dry_run
	case "$dry_run" in 1|true) dry_run=1 ;; *) dry_run=0 ;; esac
	load_settings
	[ "$initialized" = 1 ] || { detach_fail not_initialized; return 1; }
	# Mixed layouts can switch too; anything irregular is refused below.
	case "$settings_owner" in file|unknown) ;; *) detach_fail config_not_file_owned; return 1 ;; esac
	[ -f /etc/honk/system.dae ] && [ ! -L /etc/honk/system.dae ] || { detach_fail system_config_unavailable; return 1; }
	umask 077
	detach_dir=$(mktemp -d /etc/honk/.detach.XXXXXX) || { detach_fail config_write_failed; return 1; }
	trap 'rm -rf "$detach_dir"' 0
	old_hash=$(sha256sum /etc/honk/config.dae | awk '{print $1}')
	system_entries /etc/honk/config.dae > "$detach_dir/old.entries"
	grep -q '^!unsupported$' "$detach_dir/old.entries" && { detach_fail detach_layout_unsupported; return 1; }

	# Copy values that map onto panel fields; keep the panel value for the rest.
	file_device=$(entry_value global.lan_interface "$detach_dir/old.entries")
	if [ -n "$file_device" ] && detach_network=$(device_network "$file_device"); then lan_network=$detach_network; fi
	file_port=$(entry_value experimental.native_api.listen "$detach_dir/old.entries")
	file_port=${file_port##*:}
	valid_port "$file_port" && listen_port=$file_port
	old_clash_port=$clash_api_port
	old_clash_secret=$clash_api_secret
	clash_api_enabled=0
	if grep -q '^experimental\.clash_api\.' "$detach_dir/old.entries"; then
		clash_api_enabled=1
		file_clash=$(entry_value experimental.clash_api.external_controller "$detach_dir/old.entries")
		clash_api_port=${file_clash##*:}
		clash_api_secret=$(entry_value experimental.clash_api.secret "$detach_dir/old.entries")
		valid_clash_api || { clash_api_enabled=0; clash_api_port=$old_clash_port; clash_api_secret=$old_clash_secret; }
	fi
	check_network && network_settings || { detach_fail lan_network_unavailable; return 1; }

	render_runtime_system "$lan_device" "$lan_ip" "$listen_port" > "$detach_dir/system.dae" || { detach_fail config_write_failed; return 1; }
	strip_system_blocks /etc/honk/config.dae > "$detach_dir/config.dae" || { detach_fail config_write_failed; return 1; }
	[ "$(config_owner "$detach_dir/config.dae")" = system ] || { detach_fail detach_layout_unsupported; return 1; }
	detach_check=$("$HONK_CORE" config validate --config "$detach_dir/config.dae" 2>/dev/null)
	[ "$(printf '%s' "$detach_check" | jsonfilter -e '@.ok' 2>/dev/null)" = true ] || { detach_fail detach_validation_failed; return 1; }

	if [ "$dry_run" = 1 ]; then
		system_entries "$detach_dir/system.dae" > "$detach_dir/new.entries"
		json_init
		json_add_boolean ok 1
		json_add_string message detach_preview
		json_add_string lan_network "$lan_network"
		json_add_int listen_port "$listen_port"
		json_add_boolean clash_api_enabled "$clash_api_enabled"
		json_add_int clash_api_port "$clash_api_port"
		json_add_array changes
		awk '
			{ i = index($0, "="); k = substr($0, 1, i - 1); v = substr($0, i + 1) }
			NR == FNR { seen[k] = 1; val[k] = v; next }
			k ~ /\.secret$/ { if (!seen[k]) print k "\t***\t"; else if (val[k] != v) print k "\t***\t***"; next }
			!seen[k] { print k "\t" v "\t"; next }
			val[k] != v { print k "\t" v "\t" val[k] }
		' "$detach_dir/new.entries" "$detach_dir/old.entries" > "$detach_dir/changes"
		while IFS='	' read -r change_key change_old change_new; do
			json_add_object ""
			json_add_string key "$change_key"
			json_add_string old "$change_old"
			json_add_string new "$change_new"
			json_close_object
		done < "$detach_dir/changes"
		json_close_array
		json_dump
		return 0
	fi

	honk_lock_acquire || { detach_fail operation_in_progress; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1; rm -rf "$detach_dir"' 0
	[ "$(sha256sum /etc/honk/config.dae | awk '{print $1}')" = "$old_hash" ] || { detach_fail config_changed_concurrently; return 1; }
	old_running=0
	if managed_core_pid >/dev/null 2>&1; then
		old_running=1
	elif pidof honk-core >/dev/null 2>&1; then
		detach_fail unmanaged_core_running
		return 1
	fi
	cp -p /etc/honk/config.dae "$detach_dir/old-config.dae" && cp -p /etc/honk/system.dae "$detach_dir/old-system.dae" && uci export honk > "$detach_dir/old.uci" || { detach_fail config_write_failed; return 1; }
	cp -p /etc/honk/config.dae /etc/honk/.config-before-detach.tmp && mv -f /etc/honk/.config-before-detach.tmp /etc/honk/config-before-detach.dae || { detach_fail config_write_failed; return 1; }
	if [ "$old_running" = 1 ]; then honk_lifecycle_stop 30 || { detach_fail service_stop_unconfirmed; return 1; }; fi
	chmod 0600 "$detach_dir/system.dae" "$detach_dir/config.dae"
	if ! { cp -p "$detach_dir/system.dae" /etc/honk/.system.dae.detach && mv -f /etc/honk/.system.dae.detach /etc/honk/system.dae && \
		cp -p "$detach_dir/config.dae" /etc/honk/.config.dae.detach && mv -f /etc/honk/.config.dae.detach /etc/honk/config.dae && \
		uci set "honk.main.lan_network=$lan_network" && uci set "honk.main.listen_port=$listen_port" && \
		uci set "honk.main.clash_api_enabled=$clash_api_enabled" && uci set "honk.main.clash_api_port=$clash_api_port" && \
		uci set "honk.main.clash_api_secret=$clash_api_secret" && uci commit honk && chmod 0600 /etc/config/honk; } || \
		{ [ "$old_running" = 1 ] && ! honk_lifecycle_start 30; }; then
		if detach_rollback; then detach_fail detach_failed_rolled_back; else logger -t honk "detach rollback failed; snapshot kept at $detach_dir"; trap 'honk_lock_release >/dev/null 2>&1' 0; detach_fail detach_rollback_failed; fi
		return 1
	fi
	# Retarget the draft when it held the old file, so the page stops warning.
	if [ -f /etc/honk/config-draft.dae ] && [ "$(sha256sum /etc/honk/config-draft.dae | awk '{print $1}')" = "$old_hash" ]; then
		cp -p /etc/honk/config.dae /etc/honk/.config-draft.detach && mv -f /etc/honk/.config-draft.detach /etc/honk/config-draft.dae
	fi
	echo '{"ok":true,"message":"config_detached"}'
}

diagnose() {
	load_settings
	errors=""
	managed_core_pid >/dev/null 2>&1 && running=1 || running=0
	check_config >/dev/null 2>&1 || errors="$errors ${config_error:-invalid_package_config}"
	# Let the kernel check name the missing piece so the panel can act
	check_kernel >/dev/null 2>&1 || errors="$errors ${kernel_error:-kernel_requirements_unmet}"
	if [ "$running" != 1 ]; then
		no_honk_resources >/dev/null 2>&1 || errors="$errors honk_resources_occupied"
		pidof honk-core >/dev/null 2>&1 && errors="$errors unmanaged_core_running"
		check_runtime_ports >/dev/null 2>&1 || errors="$errors $runtime_port_error"
	fi
	check_conflicts >/dev/null 2>&1 || errors="$errors proxy_conflict"
	if [ -d "$HONK_LOCK_DIR" ]; then
		if lock_owner_invalid || honk_lock_is_stale; then
			errors="$errors stale_operation_lock maintenance_recovery_required"
		else
			errors="$errors operation_in_progress"
		fi
	fi
	{ [ -e "$HONK_MAINT_JOURNAL" ] || [ -L "$HONK_MAINT_JOURNAL" ]; } && errors="$errors maintenance_recovery_required"
	if [ -n "$errors" ]; then
		printf '%s\n' "$errors" | sed 's/^ *//'
		return 1
	fi
	return 0
}

repair() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	load_settings
	check_config && { echo '{"ok":true,"message":"config_valid"}'; return 0; }
	echo '{"ok":false,"message":"config_invalid"}'
	return 1
}

api_discovery() {
	curl -fsS --noproxy '*' --connect-timeout 1 --max-time 3 "$1/api" -o "$2"
}

mock_start() {
	mock_config=$1
	mock_log=$2
	DAE_LOCATION_ASSET=/usr/share/v2ray "$HONK_CORE" --config "$mock_config" --mock-ebpf > "$mock_log" 2>&1 &
	mock_pid=$!
	mock_identity=""
	attempt=0
	while [ "$attempt" -lt 20 ]; do
		if ! kill -0 "$mock_pid" 2>/dev/null; then
			return 1
		fi
		if api_discovery "$3" "$4" 2>/dev/null; then
			mock_identity=$(tr '\000' ' ' < "/proc/$mock_pid/cmdline" 2>/dev/null)
			case "$mock_identity" in
				*"$mock_config"*--mock-ebpf*)
					[ "$(readlink -f "/proc/$mock_pid/exe" 2>/dev/null)" = "$HONK_CORE" ] && return 0
					;;
			esac
			return 1
		fi
		sleep 1
		attempt=$((attempt + 1))
	done
	return 1
}

mock_stop() {
	[ -n "$mock_pid" ] || return 0
	[ -r "/proc/$mock_pid/cmdline" ] || { mock_pid=""; return 0; }
	current=$(tr '\000' ' ' < "/proc/$mock_pid/cmdline" 2>/dev/null)
	case "$current" in
		*"$mock_config"*--mock-ebpf*)
			[ "$(readlink -f "/proc/$mock_pid/exe" 2>/dev/null)" = "$HONK_CORE" ] || return 1
			kill -TERM "$mock_pid" 2>/dev/null || return 1
			;;
		*) return 1 ;;
	esac
	attempt=0
	while kill -0 "$mock_pid" 2>/dev/null && [ "$attempt" -lt 10 ]; do sleep 1; attempt=$((attempt + 1)); done
	if kill -0 "$mock_pid" 2>/dev/null; then return 1; fi
	wait "$mock_pid" 2>/dev/null || true
	mock_pid=""
}

post_credentials() {
	endpoint=$1
	response_file=$2
	json_init
	json_add_string username "$username"
	json_add_string password "$password"
	json_dump | curl -sS --noproxy '*' --connect-timeout 1 --max-time 5 -o "$response_file" -w '%{http_code}' \
		-H 'Content-Type: application/json' --data-binary @- "$endpoint"
}

initialize_preflight() {
	load_settings
	[ "$enabled" = 0 ] && [ "$initialized" = 0 ] || { echo '{"ok":false,"message":"disable_service_before_initialization"}'; return 1; }
	[ "$config_file" = /etc/honk/config.dae ] || { echo '{"ok":false,"message":"invalid_config_path"}'; return 1; }
	[ -f /usr/share/honk/default-config.dae ] && [ ! -L /usr/share/honk/default-config.dae ] || { echo '{"ok":false,"message":"default_config_unavailable"}'; return 1; }
	[ -r /usr/share/doona/index.html ] || { echo '{"ok":false,"message":"ui_assets_missing"}'; return 1; }
	if [ "$1" = read_credentials ]; then
		read_credentials || { echo '{"ok":false,"message":"invalid_credentials"}'; return 1; }
	fi
	[ -x "$HONK_CORE" ] || { echo '{"ok":false,"message":"core_missing"}'; return 1; }
	command -v curl >/dev/null 2>&1 || { echo '{"ok":false,"message":"curl_missing"}'; return 1; }
	pidof honk-core >/dev/null 2>&1 && { echo '{"ok":false,"message":"core_already_running"}'; return 1; }
	no_honk_resources || { echo '{"ok":false,"message":"honk_resources_already_exist"}'; return 1; }
	case "$listen_port" in ''|*[!0-9]*) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;; esac
	[ "$listen_port" -ge 1024 ] && [ "$listen_port" -le 65535 ] || { echo '{"ok":false,"message":"invalid_listen_port"}'; return 1; }
	valid_clash_api || { echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1; }
	[ "$clash_api_enabled" != 1 ] || check_port "$clash_api_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	check_network || { echo '{"ok":false,"message":"lan_network_unavailable"}'; return 1; }
	network_settings || { echo '{"ok":false,"message":"lan_ipv4_unavailable"}'; return 1; }
	[ -f /etc/honk/config.dae ] && [ ! -L /etc/honk/config.dae ] || { echo '{"ok":false,"message":"main_config_unavailable"}'; return 1; }
	default_config_matches /etc/honk/config.dae || { echo '{"ok":false,"message":"custom_config_requires_configuration_page"}'; return 1; }
	check_config || { echo '{"ok":false,"message":"invalid_package_config"}'; return 1; }
	return 0
}

# Tolerate changes only inside the local-direct marker block the syncer owns.
# Normalize only the runtime fields the renderer writes back; rules compare verbatim.
normalize_default_config() {
	awk '
		/^    # honk:local-direct-begin$/ { print; inside = 1; next }
		inside && /^    # honk:local-direct-end$/ { print; inside = 0; next }
		inside { next }
		/^    clash_api \{$/ { in_clash = 1; print; next }
		in_clash && /^    \}$/ { in_clash = 0; print; next }
		in_clash && /^        (external_controller|secret): / { print "        " substr($0, 9, index($0, ":") - 9) ": <managed>"; next }
		/^    lan_interface: / { print "    lan_interface: <managed>"; next }
		/^    nfqueue_enable: (true|false)$/ { print "    nfqueue_enable: <managed>"; next }
		/^        listen: / { print "        listen: <managed>"; next }
		{ print }
		END { if (inside) exit 1 }
	' "$1"
}

default_config_matches() {
	match_main=$(mktemp /tmp/honk-init-main.XXXXXX) || return 1
	match_default=$(mktemp /tmp/honk-init-default.XXXXXX) || { rm -f "$match_main"; return 1; }
	normalize_default_config "$1" > "$match_main" && normalize_default_config "${2:-/usr/share/honk/default-config.dae}" > "$match_default"
	match_status=$?
	[ "$match_status" = 0 ] && cmp -s "$match_main" "$match_default"
	match_status=$?
	rm -f "$match_main" "$match_default"
	return "$match_status"
}

# Initialization only rewrites runtime fields of the installed template.
render_initial_config() {
	awk -v device="$1" -v host="$2" -v nfq="$3" -v port="$listen_port" \
		-v api_enabled="$clash_api_enabled" -v api_port="$clash_api_port" '
		/^    lan_interface: .*$/ { print "    lan_interface: " device; lan++; next }
		/^    nfqueue_enable: (true|false)$/ { print "    nfqueue_enable: " nfq; queue++; next }
		/^        listen: .*$/ { print "        listen: '\''" host ":" port "'\''"; listen++; next }
		/^    clash_api \{$/ { in_clash = 1; clash++; print; next }
		in_clash && /^        external_controller:/ {
			# Disabled writes an empty value: no listener, but the block stays for re-enabling.
			if (api_enabled == 1) print "        external_controller: '\''" host ":" api_port "'\''"
			else print "        external_controller: '\'''\''"
			controller++; next
		}
		# No secret here: a secret field makes this file read-only for Doona.
		in_clash && /^        secret:/ { next }
		in_clash && /^    }$/ { in_clash = 0; print; next }
		/^experimental \{$/ { in_experimental = 1; depth = 1; print; next }
		in_experimental {
			if ($0 ~ /^[[:space:]]*}$/) {
				if (depth == 1 && api_enabled == 1 && clash == 0) {
					print "    clash_api {"
					print "        external_controller: '\''" host ":" api_port "'\''"
					print "        external_ui: '\''/usr/share/honk/zashboard'\''"
					print "        default_mode: Rule"
					print "    }"
					clash = 1; controller = 1; secret = 1
				}
				depth--
				if (depth == 0) in_experimental = 0
			} else if ($0 ~ /\{$/) depth++
			print
			next
		}
		{ print }
		END {
			if (lan != 1 || queue != 1 || listen != 1) exit 1
			if (api_enabled == 1 && (clash != 1 || controller != 1)) exit 1
			# A disabled clash block may stay; its controller renders empty.
		}
	' "${4:-/etc/honk/config.dae}"
}

initialize() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	. /usr/share/libubox/jshn.sh || return 1
	initialize_preflight read_credentials || return 1
	honk_lock_acquire || { echo '{"ok":false,"message":"operation_in_progress"}'; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1' 0
	initialize_preflight || return 1

	umask 077
	temp_dir=$(mktemp -d /tmp/honk-init.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	mock_pid=""
	trap cleanup_initialize 0
	trap 'exit 1' HUP INT TERM
	initialize_committed=0
	main_written=0
	main_install_pending=0
	main_config_path=/etc/honk/config.dae
	[ -f "$main_config_path" ] && [ ! -L "$main_config_path" ] || { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
	old_main=$temp_dir/config.dae
	cp -p "$main_config_path" "$old_main" || { echo '{"ok":false,"message":"main_config_backup_failed"}'; return 1; }
	original_main_hash=$(sha256sum "$old_main" | awk '{print $1}')
	[ -f "$main_config_path" ] && [ ! -L "$main_config_path" ] || { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
	main_hash=$(sha256sum "$main_config_path" | awk '{print $1}')
	[ "$main_hash" = "$original_main_hash" ] || { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
	default_config_matches "$old_main" || { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
	old_uci=$temp_dir/honk.uci
	uci export honk > "$old_uci" && chmod 0600 "$old_uci" || { echo '{"ok":false,"message":"uci_snapshot_failed"}'; return 1; }
	mock_config=$temp_dir/candidate.dae
	mock_log=$temp_dir/core.log
	response_file=$temp_dir/response.json
	cat > "$mock_config" <<EOF
global {
    wan_interface: auto
    lan_interface: ''
    data_dir: '/etc/honk'
    nfqueue_enable: false
    store_subscribe: false
}
 routing {
    fallback: direct
}
 experimental {
    native_api {
        enabled: true
        listen: '127.0.0.1:$listen_port'
        password_auth: true
        allow_anonymous_loopback: false
        config_write: true
    }
}
EOF
	chmod 0600 "$mock_config" 2>/dev/null || true
	loopback_url="http://127.0.0.1:$listen_port"
	if ! mock_start "$mock_config" "$mock_log" "$loopback_url" "$response_file"; then
		echo '{"ok":false,"message":"mock_core_start_failed"}'
		return 1
	fi
	setup_required=$(jsonfilter -i "$response_file" -e '@.auth.setup_required' 2>/dev/null)
	case "$setup_required" in
		true)
			status=$(post_credentials "$loopback_url/api/v1/auth/setup" "$response_file")
			[ "$status" = 201 ] || { echo '{"ok":false,"message":"administrator_setup_failed"}'; return 1; }
			;;
		false)
			status=$(post_credentials "$loopback_url/api/v1/auth/login" "$response_file")
			[ "$status" = 200 ] || { echo '{"ok":false,"message":"administrator_exists_reuse_credentials_or_reset_state"}'; return 1; }
			;;
		*) echo '{"ok":false,"message":"native_api_setup_state_unavailable"}'; return 1 ;;
	esac
	api_discovery "$loopback_url" "$response_file" || { echo '{"ok":false,"message":"setup_verification_failed"}'; return 1; }
	setup_required=$(jsonfilter -i "$response_file" -e '@.auth.setup_required' 2>/dev/null)
	[ "$setup_required" = false ] || { echo '{"ok":false,"message":"setup_verification_failed"}'; return 1; }
	mock_stop || { echo '{"ok":false,"message":"mock_core_stop_failed"}'; return 1; }
	if ! mock_start "$mock_config" "$mock_log" "$loopback_url" "$response_file"; then
		echo '{"ok":false,"message":"mock_core_restart_failed"}'
		return 1
	fi
	api_discovery "$loopback_url" "$response_file" || { echo '{"ok":false,"message":"persistence_verification_failed"}'; return 1; }
	setup_required=$(jsonfilter -i "$response_file" -e '@.auth.setup_required' 2>/dev/null)
	[ "$setup_required" = false ] || { echo '{"ok":false,"message":"persistence_verification_failed"}'; return 1; }
	status=$(post_credentials "$loopback_url/api/v1/auth/login" "$response_file")
	[ "$status" = 200 ] || { echo '{"ok":false,"message":"persistence_login_failed"}'; return 1; }
	mock_stop || { echo '{"ok":false,"message":"mock_core_stop_failed"}'; return 1; }

	# After auth is set and the mock stops, render and check the full LAN candidate.
	[ "$runtime_nfqueue_enable" = true ] || [ "$runtime_nfqueue_enable" = false ] || { echo '{"ok":false,"message":"nfqueue_runtime_unavailable"}'; return 1; }
	mock_config=$temp_dir/candidate.dae
	render_initial_config "$lan_device" "$lan_ip" "$runtime_nfqueue_enable" "$old_main" > "$mock_config" || { echo '{"ok":false,"message":"default_config_render_failed"}'; return 1; }
	# Secrets get their own file: in config.dae they would make it read-only.
	honk_secrets_render "$clash_api_secret" > "$temp_dir/secrets.dae" || { echo '{"ok":false,"message":"secrets_render_failed"}'; return 1; }
	chmod 0600 "$temp_dir/secrets.dae" || { echo '{"ok":false,"message":"secrets_render_failed"}'; return 1; }
	wan_device=$(network_wan_device)
	sync_local_direct "$mock_config" "$lan_device" "$wan_device" || { echo '{"ok":false,"message":"local_direct_render_failed"}'; return 1; }
	"$HONK_CORE" config validate --config "$mock_config" >/dev/null 2>&1 || { echo '{"ok":false,"message":"candidate_config_invalid"}'; return 1; }
	lan_url="http://$lan_ip:$listen_port"
	if ! mock_start "$mock_config" "$mock_log" "$lan_url" "$response_file"; then
		echo '{"ok":false,"message":"candidate_config_invalid"}'
		return 1
	fi
	api_discovery "$lan_url" "$response_file" || {
		mock_stop >/dev/null 2>&1
		echo '{"ok":false,"message":"lan_api_verification_failed"}'
		return 1
	}
	mock_stop || {
		echo '{"ok":false,"message":"mock_core_stop_failed"}'
		return 1
	}
	"$HONK_CORE" config validate --config "$mock_config" >/dev/null 2>&1 || { echo '{"ok":false,"message":"candidate_config_invalid"}'; return 1; }
	if ! initialize_install_main "$mock_config" "$main_config_path" "$original_main_hash"; then
		[ "$initialize_error" = main_changed ] && { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
		echo '{"ok":false,"message":"main_config_write_failed"}'
		return 1
	fi
	if ! initialize_install_secrets "$temp_dir/secrets.dae"; then
		echo '{"ok":false,"message":"secrets_write_failed"}'
		return 1
	fi
	uci set honk.main.initialized='1' && uci commit honk || {
		echo '{"ok":false,"message":"uci_commit_failed_main_restore_pending"}'
		return 1
	}
	initialize_committed=1
	password=""
	username=""
	echo '{"ok":true,"message":"administrator_initialized"}'
}

# Finish an interrupted maintenance transaction: clear a stale lock, then let
# maintenance.sh roll back. Only when no honk-core runs, so no live lock is lost.
recover() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then
		echo '{"ok":false,"message":"update_recovery_required"}'
		return 1
	fi
	if [ -d "$HONK_LOCK_DIR" ]; then
		lock_readable=0
		[ -r "$HONK_LOCK_DIR/pid" ] && lock_readable=1
		if [ "$lock_readable" = 1 ] && ! honk_lock_is_stale; then
			echo '{"ok":false,"message":"operation_in_progress"}'
			return 1
		fi
		if pidof honk-core >/dev/null 2>&1; then
			echo '{"ok":false,"message":"unmanaged_core_running"}'
			return 1
		fi
		rm -rf "$HONK_LOCK_DIR" || { echo '{"ok":false,"message":"lock_clear_failed"}'; return 1; }
	fi
	if [ -d /etc/.honk-maintenance ]; then
		if ! maint_out=$(/usr/share/honk/maintenance.sh recover 2>/dev/null); then
			echo "${maint_out:-{\"ok\":false,\"message\":\"recovery_failed\"}}"
			return 1
		fi
	fi
	honk_lifecycle_reclaim_resources || :
	echo '{"ok":true,"message":"transaction_recovered"}'
}

# Verify file, flags and service after rollback; otherwise never report rolled_back.
system_rollback() {
	_rs_file=$1; _rs_backup=$2; _rs_hash=$3; _rs_managed=$4; _rs_running=$5
	rollback_state=incomplete
	if ! cp -p "$_rs_backup" "$_rs_file" 2>/dev/null; then
		_rs_keep=/tmp/honk-rollback-$(date +%s)-$(basename "$_rs_file")
		cp -p "$_rs_backup" "$_rs_keep" 2>/dev/null && chmod 0600 "$_rs_keep" 2>/dev/null
		logger -t honk "rollback: restore file failed; backup=$_rs_keep"
		return 1
	fi
	uci set honk.main.system_managed="$_rs_managed" >/dev/null 2>&1 && uci commit honk >/dev/null 2>&1 || :
	_rs_ready=0
	if [ "$_rs_running" = 1 ]; then honk_lifecycle_start 15 >/dev/null 2>&1 && _rs_ready=1; fi
	_rs_now=$(sha256sum "$_rs_file" 2>/dev/null | awk '{print $1}')
	_rs_flag=$(uci -q get honk.main.system_managed); [ -n "$_rs_flag" ] || _rs_flag=1
	if [ "$_rs_now" = "$_rs_hash" ] && [ "$_rs_flag" = "$_rs_managed" ] &&
		{ [ "$_rs_running" != 1 ] || [ "$_rs_ready" = 1 ]; }; then
		rollback_state=rolled_back
	else
		# Keep the backup when the rollback is incomplete
		_rs_keep=/tmp/honk-rollback-$(date +%s)-$(basename "$_rs_file")
		cp -p "$_rs_backup" "$_rs_keep" 2>/dev/null && chmod 0600 "$_rs_keep" 2>/dev/null
		logger -t honk "rollback incomplete: hash=$_rs_now managed=$_rs_flag ready=$_rs_ready backup=$_rs_keep"
	fi
}

system_rollback_state() { printf '%s\n' "${rollback_state:-incomplete}"; }


# User-managed mode: the candidate arrives by path and validates as a full tree.
write_system_config() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	sys=/etc/honk/system.dae
	[ -f "$sys" ] && [ ! -L "$sys" ] || { echo '{"ok":false,"message":"system_config_unavailable"}'; return 1; }
	candidate=$1
	[ -f "$candidate" ] && [ ! -L "$candidate" ] || { echo '{"ok":false,"message":"system_config_unavailable"}'; return 1; }
	[ "$(wc -c < "$candidate" 2>/dev/null)" -le 262144 ] 2>/dev/null || { echo '{"ok":false,"message":"content_too_large"}'; return 1; }
	[ -s "$candidate" ] || { echo '{"ok":false,"message":"content_empty"}'; return 1; }

	honk_lock_acquire || { echo '{"ok":false,"message":"operation_in_progress"}'; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1' 0

	umask 077
	work=$(mktemp -d /tmp/honk-syssave.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	# Backups live at a stable path so an interrupted process can still restore
	committed=0
	prev=/etc/honk/.system-prev.dae
	cp -p "$sys" "$prev" || { rm -rf "$work"; echo '{"ok":false,"message":"system_config_backup_failed"}'; return 1; }
	trap 'if [ "$committed" != 1 ]; then cp -p "$prev" "$sys" 2>/dev/null; [ -z "${old_managed:-}" ] || uci set honk.main.system_managed="$old_managed" >/dev/null 2>&1; uci commit honk >/dev/null 2>&1; logger -t honk "save interrupted, restored system.dae"; fi; rm -f "$prev"; rm -rf "$work"; honk_lock_release >/dev/null 2>&1' 0
	cp -p "$sys" "$work/orig-system.dae" || { echo '{"ok":false,"message":"system_config_backup_failed"}'; return 1; }
	# Copy the whole tree so includes into subdirectories validate for real
	find /etc/honk -path /etc/honk/state -prune -o -type f -print > "$work/files.txt" || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	while IFS= read -r cfg_src; do
		cfg_rel=${cfg_src#/etc/honk/}
		[ "$cfg_rel" = system.dae ] && continue
		cfg_dir=$(dirname "$cfg_rel")
		[ "$cfg_dir" = . ] || mkdir -p "$work/$cfg_dir" || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
		cp -p "$cfg_src" "$work/$cfg_rel" || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	done < "$work/files.txt"
	cp "$candidate" "$work/system.dae" || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	# Refuse when config.dae does not include system.dae: saving would change nothing.
	[ -n "$(config_includes_system "$work/config.dae")" ] || { echo '{"ok":false,"message":"system_config_not_included"}'; return 1; }
	"$HONK_CORE" config validate --config "$work/config.dae" >/dev/null 2>&1 || { echo '{"ok":false,"message":"config_invalid"}'; return 1; }

	system_written_hash=$(sha256sum "$sys" | awk '{print $1}')
	pending=$(mktemp /etc/honk/.system.dae.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	cp "$candidate" "$pending" && chmod 0600 "$pending" || { rm -f "$pending"; echo '{"ok":false,"message":"system_config_write_failed"}'; return 1; }
	[ "$(sha256sum "$sys" | awk '{print $1}')" = "$system_written_hash" ] || { rm -f "$pending"; echo '{"ok":false,"message":"system_config_changed"}'; return 1; }

	old_managed=$(uci -q get honk.main.system_managed)
	[ -n "$old_managed" ] || old_managed=1
	was_running=0
	managed_core_pid >/dev/null 2>&1 && was_running=1
	mv -f "$pending" "$sys" || { rm -f "$pending"; echo '{"ok":false,"message":"system_config_write_failed"}'; return 1; }
	uci set honk.main.system_managed=0 && uci commit honk || {
		system_rollback "$sys" "$work/orig-system.dae" "$system_written_hash" "$old_managed" "$was_running"
		printf '{"ok":false,"message":"settings_commit_failed_%s"}\n' "$(system_rollback_state)"; return 1
	}

	if [ "$was_running" = 1 ] && ! honk_lifecycle_restart 12 >/dev/null 2>&1; then
		system_rollback "$sys" "$work/orig-system.dae" "$system_written_hash" "$old_managed" "$was_running"
		printf '{"ok":false,"message":"system_config_start_failed_%s"}\n' "$(system_rollback_state)"; return 1
	fi
	committed=1
	echo '{"ok":true,"message":"system_config_saved"}'
}

# Switch back to panel management: dry_run returns the result, apply replaces it.
panel_managed_system() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	echo '{"ok":false,"message":"runtime_settings_owned_by_file"}'
	return 1
}

case "$1" in
	check)
		preflight
		;;
	diagnose)
		diagnose
		;;
	preflight)
		prepare_runtime
		;;
	local-direct)
		load_settings
		network_settings >/dev/null 2>&1 || :
		sync_local_direct /etc/honk/config.dae "$lan_device" "$(network_wan_device)"
		;;
	local-direct-file)
		load_settings
		shift
		sync_local_direct "$@"
		;;
	initialize)
		initialize
		;;
	settings)
		settings
		;;
	repair)
		repair
		;;
	detach)
		detach
		;;
	write-system)
		write_system_config "$2"
		;;
	panel-managed)
		panel_managed_system
		;;
	recover)
		recover
		;;
	*)
		echo "usage: $0 {check|diagnose|preflight|local-direct|local-direct-file|initialize|settings|repair|detach|recover|write-system|panel-managed}" >&2
		exit 2
		;;
esac
