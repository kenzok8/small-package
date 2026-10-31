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

fail() {
	echo "honk: $*" >&2
	return 1
}

load_settings() {
	config_load honk
	config_get_bool enabled main enabled 0
	config_get_bool boot_enabled main boot_enabled 0
	config_get_bool initialized main initialized 0
	config_get config_mode main config_mode managed
	config_get config_file main config_file /etc/honk/config.dae
	config_get listen_port main listen_port 9527
	config_get_bool clash_api_enabled main clash_api_enabled 0
	config_get clash_api_port main clash_api_port 9090
	config_get clash_api_secret main clash_api_secret ''
	config_get lan_network main lan_network lan
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
	# honk-core removes dae0/dae0peer and the daens netns when it exits cleanly. A
	# crash or SIGKILL leaves them behind, and preflight then refuses every later
	# start, so the service can never come back without hand surgery. Reclaim them
	# here, but only when no core is running to own them.
	if ! pidof honk-core >/dev/null 2>&1; then
		for stale_link in dae0 dae0peer; do
			ip link show "$stale_link" >/dev/null 2>&1 && ip link del "$stale_link" >/dev/null 2>&1
		done
		if ip netns list 2>/dev/null | awk '{print $1}' | grep -qx daens; then
			ip netns del daens >/dev/null 2>&1
		fi
	fi
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

# 本机 LAN/WAN 设备地址（跳过链路本地），与 honk 的 local_direct_cidrs 对齐
local_direct_addresses() {
	list=''
	. /lib/functions/network.sh
	for net in "$lan_network" wan; do
		network_get_device dev "$net" || continue
		case "$dev" in ''|*[!A-Za-z0-9_.-]*) continue ;; esac
		for addr in $(ip -o addr show dev "$dev" 2>/dev/null | awk '/inet6? / { split($4, a, "/"); print a[1] }'); do
			case "$addr" in fe80:*|169.254.*) continue ;; esac
			case "$addr" in ''|*[!0-9a-fA-F:.]*) continue ;; esac
			[ "${#addr}" -le 45 ] || continue
			case " $list " in *" $addr "*) continue ;; esac
			list="${list:+$list, }$addr"
		done
	done
	printf '%s\n' "$list"
}

# 把标记区块换成当前本机地址，honk 的 LAN self-protection 检查才认
sync_local_direct() {
	begin='    # honk:local-direct-begin'
	end='    # honk:local-direct-end'
	grep -qxF "$begin" /etc/honk/config.dae || return 0
	grep -qxF "$end" /etc/honk/config.dae || return 0
	ips=$(local_direct_addresses)
	[ -n "$ips" ] && rule="    dip($ips) && !dport(53) -> direct(must)" || rule=''
	# honk-core 只认 .dae 后缀，临时文件必须带它
	temp=/etc/honk/.config.$$.dae
	( umask 077; : > "$temp" ) || return 1
	awk -v begin="$begin" -v end="$end" -v rule="$rule" '
		$0 == begin { print; if (rule != "") print rule; skip = 1; next }
		skip && $0 == end { print; skip = 0; next }
		skip { next }
		{ print }
	' /etc/honk/config.dae > "$temp" || { rm -f "$temp"; return 1; }
	cmp -s "$temp" /etc/honk/config.dae && { rm -f "$temp"; return 0; }
	"$HONK_CORE" config validate --config "$temp" >/dev/null 2>&1 || { rm -f "$temp"; return 1; }
	chmod 0600 "$temp"
	mv -f "$temp" /etc/honk/config.dae || { rm -f "$temp"; return 1; }
}

check_config() {
	[ "$config_file" = /etc/honk/config.dae ] || { fail "配置路径必须为 /etc/honk/config.dae"; return 1; }
	[ -f /etc/honk/config.dae ] && [ ! -L /etc/honk/config.dae ] || { fail "/etc/honk/config.dae 不是普通文件（可能被替换成软链）"; return 1; }
	case "$config_mode" in
		manual)
			"$HONK_CORE" config validate --config /etc/honk/config.dae >/dev/null || { fail "手动模式的 config.dae 未通过静态校验，请先修正配置"; return 1; }
			return 0
			;;
		managed) ;;
		*) fail "配置模式取值非法（应为 managed 或 manual）"; return 1 ;;
	esac
	[ -f /etc/honk/system.dae ] && [ ! -L /etc/honk/system.dae ] || { fail "/etc/honk/system.dae 不是普通文件（可能被替换成软链）"; return 1; }
	system_config_readonly || { fail "/etc/honk/system.dae 权限不对，应为 0600"; return 1; }
	[ -r /usr/share/doona/index.html ] || { fail "缺少 Doona 静态文件（/usr/share/doona/index.html），请重新安装 luci-app-honk"; return 1; }
	case "$listen_port" in
		''|*[!0-9]*) fail "监听端口必须是数字"; return 1 ;;
	esac
	[ "$listen_port" -ge 1024 ] && [ "$listen_port" -le 65535 ] || { fail "监听端口必须在 1024-65535 之间"; return 1; }
	valid_clash_api || { fail "Clash API 设置不合法（端口 1024-65535，密钥 6-128 位）"; return 1; }
}

check_kernel() {
	kernel=$(uname -r | cut -d- -f1)
	major=$(printf '%s' "$kernel" | cut -d. -f1)
	minor=$(printf '%s' "$kernel" | cut -d. -f2)
	[ "$major" -gt 6 ] || { [ "$major" -eq 6 ] && [ "$minor" -ge 12 ]; } || { fail "内核版本过低，需要 Linux 6.12 或更新"; return 1; }
	[ -r /sys/kernel/btf/vmlinux ] || { fail "内核缺少 BTF（/sys/kernel/btf/vmlinux），请换用带 BTF 的固件"; return 1; }
	[ -d /sys/fs/bpf ] && grep -q ' /sys/fs/bpf bpf ' /proc/mounts || { fail "bpffs 未挂载到 /sys/fs/bpf，请检查内核或手工挂载"; return 1; }
	command -v ip >/dev/null 2>&1 || { fail "缺少 ip 命令（装 ip-full）"; return 1; }
	command -v modprobe >/dev/null 2>&1 || { fail "缺少 modprobe 命令（装 kmod）"; return 1; }
	[ -r /sys/kernel/btf/vmlinux ] || { fail "内核缺少 BTF（/sys/kernel/btf/vmlinux），请换用带 BTF 的固件"; return 1; }
	for module in sch_ingress cls_bpf veth nft_queue nfnetlink_queue; do
		module_available "$module" || { fail "缺少内核模块 $module，请确认 kmod-sched-core / kmod-sched-bpf / kmod-veth / kmod-nft-queue 已安装"; return 1; }
	done
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

preflight() {
	load_settings
	[ "$enabled" = 1 ] && [ "$initialized" = 1 ] || { fail "请先在 LuCI 里启用并完成初始化"; return 1; }
	if [ "$config_mode" = manual ]; then
		maintenance_start_guard && check_config && check_kernel && no_honk_resources && check_conflicts
		return $?
	fi
	maintenance_start_guard && check_config && check_network && check_kernel && no_honk_resources && check_conflicts && check_port && {
		[ "$clash_api_enabled" = 0 ] || check_port "$clash_api_port"
	}
}

prepare_runtime() {
	preflight || return 1
	for module in sch_ingress cls_bpf veth nft_queue nfnetlink_queue; do
		module_loaded "$module" || modprobe "$module" || { fail "无法加载内核模块 $module，请确认对应 kmod 包已安装"; return 1; }
	done
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

ensure_loopback_system() {
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { fail "初始化期间 system.dae 被其他进程改动，已中止"; return 1; }
	current_listen=$(sed -n "s/^[[:space:]]*listen:[[:space:]]*'\([^']*\)'.*/\1/p" /etc/honk/system.dae | head -n 1)
	[ "$current_listen" = "127.0.0.1:$listen_port" ] && return 0
	temp_system=$(mktemp /etc/honk/.system.dae.XXXXXX) || return 1
	sed "s/^[[:space:]]*listen:[[:space:]]*'[^']*'.*/        listen: '127.0.0.1:$listen_port'/" /etc/honk/system.dae > "$temp_system" || { rm -f "$temp_system"; return 1; }
	chmod 0600 "$temp_system" || { rm -f "$temp_system"; return 1; }
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { rm -f "$temp_system"; fail "初始化期间 system.dae 被其他进程改动，已中止"; return 1; }
	mv -f "$temp_system" /etc/honk/system.dae || { rm -f "$temp_system"; return 1; }
	system_written_hash=$(sha256sum /etc/honk/system.dae | awk '{print $1}')
}

restore_system() {
	[ -n "$system_written_hash" ] || return 0
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { fail "回滚期间 system.dae 被其他进程改动，已中止"; return 1; }
	[ "$current_hash" != "$original_system_hash" ] || { system_written_hash=""; return 0; }
	if [ -z "$original_system_hash" ]; then
		rm -f /etc/honk/system.dae || return 1
		system_written_hash=""
		return 0
	fi
	temp_restore=$(mktemp /etc/honk/.system.dae.restore.XXXXXX) || return 1
	cp -p "$old_system" "$temp_restore" || { rm -f "$temp_restore"; return 1; }
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { rm -f "$temp_restore"; fail "回滚期间 system.dae 被其他进程改动，已中止"; return 1; }
	mv -f "$temp_restore" /etc/honk/system.dae || { rm -f "$temp_restore"; return 1; }
	system_written_hash=""
}

cleanup_initialize() {
	if mock_stop >/dev/null 2>&1; then
		if [ -n "$system_written_hash" ] && ! restore_system; then
			logger -t honk "system config rollback refused or failed; inspect /etc/honk/system.dae"
		fi
		rm -rf "$temp_dir"
		honk_lock_release >/dev/null 2>&1
	else
		logger -t honk "mock process cleanup failed; keeping operation lock and temporary files"
	fi
}

write_runtime_system() {
	lan_device=$1
	lan_ip=$2
	system_port=${3:-$listen_port}
	system_listen=${4:-$lan_ip}
	valid_clash_api || { fail "Clash API 设置不合法（端口 1024-65535，密钥 6-128 位）"; return 1; }
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { fail "写入运行配置时 system.dae 被其他进程改动，已中止"; return 1; }
	temp_system=$(mktemp /etc/honk/.system.dae.XXXXXX) || return 1
	{
		printf "global {\n    wan_interface: auto\n    lan_interface: '%s'\n" "$lan_device"
		printf "    log_level: info\n    dial_mode: domain\n    allow_insecure: false\n"
		printf "    auto_config_kernel_parameter: true\n    data_dir: '/etc/honk'\n"
		printf "    store_subscribe: true\n    nfqueue_enable: true\n}\n\n"
		printf "experimental {\n    native_api {\n        enabled: true\n        listen: '%s:%s'\n" "$system_listen" "$system_port"
		printf "        password_auth: true\n        allow_anonymous_loopback: false\n"
		printf "        config_write: true\n        ui: '/usr/share/doona'\n    }\n"
		if [ "$clash_api_enabled" = 1 ]; then
			printf "    clash_api {\n        external_controller: '%s:%s'\n        external_ui: '/usr/share/honk/zashboard'\n        secret: '%s'\n        default_mode: Rule\n    }\n" "$system_listen" "$clash_api_port" "$clash_api_secret"
		fi
		printf "}\n"
	} > "$temp_system" || { rm -f "$temp_system"; return 1; }
	chmod 0600 "$temp_system" || { rm -f "$temp_system"; return 1; }
	current_hash=$(sha256sum /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$current_hash" = "$system_written_hash" ] || { rm -f "$temp_system"; fail "写入运行配置时 system.dae 被其他进程改动，已中止"; return 1; }
	mv -f "$temp_system" /etc/honk/system.dae || { rm -f "$temp_system"; return 1; }
	system_written_hash=$(sha256sum /etc/honk/system.dae | awk '{print $1}')
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

restore_old_runtime() {
	[ "$old_running" = 1 ] || return 0
	runtime_enabled=$(uci -q get honk.main.enabled || echo 0)
	if [ "$runtime_enabled" != 1 ]; then uci set honk.main.enabled=1 && uci commit honk || return 1; fi
	honk_lifecycle_start 30 || {
		[ "$runtime_enabled" = 1 ] || { uci set "honk.main.enabled=$runtime_enabled" && uci commit honk; }
		return 1
	}
	if [ "$runtime_enabled" != 1 ]; then uci set "honk.main.enabled=$runtime_enabled" && uci commit honk || return 1; fi
}

settings_rollback() {
	rollback_ok=1
	honk_lifecycle_stop 30 || return 1
	if [ -n "$system_written_hash" ] && ! restore_system; then rollback_ok=0; fi
	if ! uci import honk < "$old_uci" || ! uci commit honk; then rollback_ok=0; fi
	if ! sync_boot_link "$old_boot_enabled"; then rollback_ok=0; fi
	restore_old_runtime || rollback_ok=0
	[ "$rollback_ok" = 1 ]
}

settings() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	load_settings
	[ "$config_mode" = manual ] && { echo '{"ok":false,"message":"settings_unavailable_in_manual_mode"}'; return 1; }
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
	[ "$network_type" = string ] || { echo '{"ok":false,"message":"invalid_lan_network"}'; return 1; }
	case "$port_type" in int|integer) ;; *) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;; esac
	# boot_enabled 已内置（恒为 1），前端不再提交，缺省就按当前值处理
	case "$boot_enabled_type" in ''|null|boolean) ;; *) echo '{"ok":false,"message":"invalid_boolean_settings"}'; return 1 ;; esac
	case "$clash_enabled_type" in ''|null|boolean) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_port_type" in ''|null|int|integer) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$clash_secret_type" in ''|null|string) ;; *) echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1 ;; esac
	case "$new_network" in ''|*[!A-Za-z0-9_.-]*) echo '{"ok":false,"message":"invalid_lan_network"}'; return 1 ;; esac
	case "$new_port" in ''|*[!0-9]*) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;; esac
	[ "$new_port" -ge 1024 ] && [ "$new_port" -le 65535 ] || { echo '{"ok":false,"message":"invalid_listen_port"}'; return 1; }
	load_settings
	case "$boot_enabled_type" in ''|null) new_boot_enabled=1 ;; esac
	new_boot_enabled=1
	case "$clash_enabled_type" in ''|null) new_clash_enabled=$clash_api_enabled ;; esac
	case "$clash_port_type" in ''|null) new_clash_port=$clash_api_port ;; esac
	[ -n "$new_clash_secret" ] || new_clash_secret=$clash_api_secret
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
	lan_network=$new_network
	listen_port=$new_port
	clash_api_enabled=$new_clash_enabled
	clash_api_port=$new_clash_port
	clash_api_secret=$new_clash_secret
	valid_clash_api || { echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1; }
	check_network || { echo '{"ok":false,"message":"lan_network_unavailable"}'; return 1; }
	network_settings || { echo '{"ok":false,"message":"lan_ipv4_unavailable"}'; return 1; }
	old_running=0
	if managed_core_pid >/dev/null 2>&1; then
		old_running=1
	elif pidof honk-core >/dev/null 2>&1; then
		echo '{"ok":false,"message":"unmanaged_core_running"}'
		return 1
	fi
	if ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$new_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$new_clash_port" ]; }; then
		check_port "$new_clash_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	honk_lock_acquire || { echo '{"ok":false,"message":"operation_in_progress"}'; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1' 0
	load_settings
	[ "$lan_network" = "$old_network" ] && [ "$listen_port" = "$old_port" ] && [ "$enabled" = "$old_enabled" ] && [ "$boot_enabled" = "$old_boot_enabled" ] && [ "$initialized" = "$old_initialized" ] && [ "$clash_api_enabled" = "$old_clash_enabled" ] && [ "$clash_api_port" = "$old_clash_port" ] && [ "$clash_api_secret" = "$old_clash_secret" ] || { echo '{"ok":false,"message":"settings_changed_concurrently"}'; return 1; }
	new_enabled=$enabled
	managed_core_pid >/dev/null 2>&1 && recheck_running=1 || recheck_running=0
	[ "$recheck_running" = "$old_running" ] || { echo '{"ok":false,"message":"service_state_changed_concurrently"}'; return 1; }
	old_running=$recheck_running
	lan_network=$new_network
	listen_port=$new_port
	clash_api_enabled=$new_clash_enabled
	clash_api_port=$new_clash_port
	clash_api_secret=$new_clash_secret
	check_network && network_settings || { echo '{"ok":false,"message":"lan_network_changed_during_settings"}'; return 1; }
	if ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$new_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$new_clash_port" ]; }; then
		check_port "$new_clash_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	if [ "$initialized" = 1 ] && ! check_config; then echo '{"ok":false,"message":"package_config_unavailable"}'; return 1; fi
	umask 077
	settings_dir=$(mktemp -d /tmp/honk-settings.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	old_uci=$settings_dir/honk.uci
	uci export honk > "$old_uci" || { rm -rf "$settings_dir"; echo '{"ok":false,"message":"uci_snapshot_failed"}'; return 1; }
	old_system=$settings_dir/system.dae
	system_written_hash=""
	if [ "$initialized" = 1 ]; then
		[ -f /etc/honk/system.dae ] && [ ! -L /etc/honk/system.dae ] || { rm -rf "$settings_dir"; echo '{"ok":false,"message":"system_config_unavailable"}'; return 1; }
		cp -p /etc/honk/system.dae "$old_system" || { rm -rf "$settings_dir"; echo '{"ok":false,"message":"system_snapshot_failed"}'; return 1; }
		original_system_hash=$(sha256sum "$old_system" | awk '{print $1}')
		system_written_hash=$original_system_hash
	fi
	if [ "$old_running" = 1 ]; then
		honk_lifecycle_stop 30 || {
			settings_rollback; rollback_status=$?
			if [ "$rollback_status" = 0 ]; then rm -rf "$settings_dir"; echo '{"ok":false,"message":"service_stop_failed_rolled_back"}'; else logger -t honk "settings rollback failed; snapshot retained at $settings_dir"; echo '{"ok":false,"message":"service_stop_and_rollback_failed_snapshot_retained"}'; fi
			return 1
		}
	fi
	if [ "$initialized" = 1 ] && ! write_runtime_system "$lan_device" "$lan_ip" "$new_port"; then
		settings_rollback; rollback_status=$?
		if [ "$rollback_status" = 0 ]; then rm -rf "$settings_dir"; echo '{"ok":false,"message":"system_config_write_failed_rolled_back"}'; else logger -t honk "settings rollback failed; snapshot retained at $settings_dir"; echo '{"ok":false,"message":"system_config_write_and_rollback_failed_snapshot_retained"}'; fi
		return 1
	fi
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
	if [ "$initialized" = 1 ]; then
		service_ok=0
		if [ "$new_enabled" = 1 ]; then
			honk_lifecycle_start 30 || service_ok=1
		else
			honk_lifecycle_stop 30 || service_ok=1
		fi
		if [ "$service_ok" != 0 ]; then
			settings_rollback; rollback_status=$?
			if [ "$rollback_status" = 0 ]; then rm -rf "$settings_dir"; echo '{"ok":false,"message":"service_apply_failed_rolled_back"}'; else logger -t honk "settings rollback failed; snapshot retained at $settings_dir"; echo '{"ok":false,"message":"service_apply_and_rollback_failed_snapshot_retained"}'; fi
			return 1
		fi
	fi
	system_written_hash=""
	rm -rf "$settings_dir"
	echo '{"ok":true,"message":"settings_saved"}'
}

diagnose() {
	load_settings
	errors=""
	managed_core_pid >/dev/null 2>&1 && running=1 || running=0
	check_config >/dev/null 2>&1 || errors="$errors invalid_package_config"
	check_kernel >/dev/null 2>&1 || errors="$errors kernel_requirements_unmet"
	if [ "$config_mode" = manual ]; then
		if [ "$running" != 1 ]; then
			no_honk_resources >/dev/null 2>&1 || errors="$errors honk_resources_occupied"
			pidof honk-core >/dev/null 2>&1 && errors="$errors unmanaged_core_running"
		fi
	else
		check_network >/dev/null 2>&1 || errors="$errors lan_network_unavailable"
		network_settings >/dev/null 2>&1 || errors="$errors lan_ipv4_unavailable"
		command -v curl >/dev/null 2>&1 || errors="$errors curl_missing"
		if [ "$running" != 1 ]; then
			no_honk_resources >/dev/null 2>&1 || errors="$errors honk_resources_occupied"
			pidof honk-core >/dev/null 2>&1 && errors="$errors unmanaged_core_running"
			check_port >/dev/null 2>&1 || errors="$errors listen_port_occupied"
			if [ "$clash_api_enabled" = 1 ]; then
				check_port "$clash_api_port" >/dev/null 2>&1 || errors="$errors clash_api_port_occupied"
			fi
		fi
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

main_has_system_include() {
	awk '
		/^[[:space:]]*include[[:space:]]*\{/ { inside = 1 }
		inside && /(^|[^[:alnum:]_.-])system\.dae([^[:alnum:]_.-]|$)/ { found = 1 }
		inside && /\}/ { inside = 0 }
		END { exit !found }
	' /etc/honk/config.dae
}

clash_system_matches() {
	if [ "$clash_api_enabled" = 0 ]; then
		! grep -q 'clash_api {' /etc/honk/system.dae
		return
	fi
	permissions=$(ls -ldn /etc/honk/system.dae 2>/dev/null | awk '{print $1}')
	[ "$permissions" = '-rw-------' ] || return 1
	grep -Fqx "        external_controller: '$system_host:$clash_api_port'" /etc/honk/system.dae || return 1
	grep -Fqx "        external_ui: '/usr/share/honk/zashboard'" /etc/honk/system.dae || return 1
	system_secret=$(sed -n "s/^        secret: '\([^']*\)'$/\1/p" /etc/honk/system.dae)
	[ "$system_secret" = "$clash_api_secret" ]
}

repair() {
	if [ -e /etc/.honk-update/journal ] || [ -L /etc/.honk-update/journal ]; then echo '{"ok":false,"message":"update_recovery_required"}'; return 1; fi
	load_settings
	if [ "$config_mode" = manual ]; then
		check_config && { echo '{"ok":true,"message":"manual_config_valid"}'; return 0; }
		echo '{"ok":false,"message":"manual_config_invalid"}'
		return 1
	fi
	old_network=$lan_network
	old_port=$listen_port
	old_enabled=$enabled
	old_boot_enabled=$boot_enabled
	old_initialized=$initialized
	old_clash_enabled=$clash_api_enabled
	old_clash_port=$clash_api_port
	old_clash_secret=$clash_api_secret
	[ "$config_file" = /etc/honk/config.dae ] || { echo '{"ok":false,"message":"invalid_config_path"}'; return 1; }
	[ -f /etc/honk/config.dae ] && [ ! -L /etc/honk/config.dae ] || { echo '{"ok":false,"message":"main_config_unavailable"}'; return 1; }
	main_hash=$(sha256sum /etc/honk/config.dae | awk '{print $1}')
	main_has_system_include || { echo '{"ok":false,"message":"required_system_include_missing_manual_repair"}'; return 1; }
	valid_network_name || { echo '{"ok":false,"message":"invalid_lan_network"}'; return 1; }
	case "$listen_port" in ''|*[!0-9]*) echo '{"ok":false,"message":"invalid_listen_port"}'; return 1 ;; esac
	[ "$listen_port" -ge 1024 ] && [ "$listen_port" -le 65535 ] || { echo '{"ok":false,"message":"invalid_listen_port"}'; return 1; }
	valid_clash_api || { echo '{"ok":false,"message":"invalid_clash_api_settings"}'; return 1; }
	check_network || { echo '{"ok":false,"message":"lan_network_unavailable"}'; return 1; }
	network_settings || { echo '{"ok":false,"message":"lan_ipv4_unavailable"}'; return 1; }
	old_running=0
	managed_core_pid >/dev/null 2>&1 && old_running=1
	if pidof honk-core >/dev/null 2>&1 && [ "$old_running" = 0 ]; then echo '{"ok":false,"message":"unmanaged_core_running"}'; return 1; fi
	if ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$listen_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$clash_api_port" ]; }; then
		check_port "$clash_api_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	honk_lock_acquire || { echo '{"ok":false,"message":"operation_in_progress"}'; return 1; }
	trap 'honk_lock_release >/dev/null 2>&1' 0
	load_settings
	[ "$lan_network" = "$old_network" ] && [ "$listen_port" = "$old_port" ] && [ "$enabled" = "$old_enabled" ] && [ "$boot_enabled" = "$old_boot_enabled" ] && [ "$initialized" = "$old_initialized" ] && [ "$clash_api_enabled" = "$old_clash_enabled" ] && [ "$clash_api_port" = "$old_clash_port" ] && [ "$clash_api_secret" = "$old_clash_secret" ] || { echo '{"ok":false,"message":"settings_changed_concurrently"}'; return 1; }
	managed_core_pid >/dev/null 2>&1 && recheck_running=1 || recheck_running=0
	[ "$recheck_running" = "$old_running" ] || { echo '{"ok":false,"message":"service_state_changed_concurrently"}'; return 1; }
	[ "$(sha256sum /etc/honk/config.dae | awk '{print $1}')" = "$main_hash" ] || { echo '{"ok":false,"message":"main_config_changed_concurrently"}'; return 1; }
	check_network && network_settings || { echo '{"ok":false,"message":"lan_network_changed_during_repair"}'; return 1; }
	if ! { [ "$old_running" = 1 ] && [ "$(configured_system_port)" = "$listen_port" ]; }; then
		check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	fi
	if [ "$clash_api_enabled" = 1 ] && ! { [ "$old_running" = 1 ] && [ "$(configured_clash_port)" = "$clash_api_port" ]; }; then
		check_port "$clash_api_port" || { echo '{"ok":false,"message":"clash_api_port_occupied"}'; return 1; }
	fi
	if [ "$initialized" = 1 ]; then system_host=$lan_ip; else system_host=127.0.0.1; fi
	if [ -r /usr/share/doona/index.html ] && [ -f /etc/honk/system.dae ] && [ ! -L /etc/honk/system.dae ] && system_config_readonly && \
		grep -Fqx '    wan_interface: auto' /etc/honk/system.dae && grep -Fqx "    lan_interface: '$lan_device'" /etc/honk/system.dae && \
		grep -Fqx "    data_dir: '/etc/honk'" /etc/honk/system.dae && grep -Fqx '    nfqueue_enable: true' /etc/honk/system.dae && \
		grep -Fqx "        listen: '$system_host:$listen_port'" /etc/honk/system.dae && \
		grep -Fqx "        ui: '/usr/share/doona'" /etc/honk/system.dae && grep -Fqx '        password_auth: true' /etc/honk/system.dae && \
		grep -Fqx '        allow_anonymous_loopback: false' /etc/honk/system.dae && grep -Fqx '        config_write: true' /etc/honk/system.dae && clash_system_matches; then
		echo '{"ok":true,"message":"system_config_healthy"}'
		return 0
	fi
	if [ -e /etc/honk/system.dae ] && { [ ! -f /etc/honk/system.dae ] || [ -L /etc/honk/system.dae ]; }; then
		echo '{"ok":false,"message":"system_config_not_regular_file"}'
		return 1
	fi
	[ -r /usr/share/doona/index.html ] || { echo '{"ok":false,"message":"ui_assets_missing"}'; return 1; }
	umask 077
	repair_dir=$(mktemp -d /tmp/honk-repair.XXXXXX) || { echo '{"ok":false,"message":"temporary_storage_unavailable"}'; return 1; }
	old_system=$repair_dir/system.dae
	original_system_hash=""
	if [ -f /etc/honk/system.dae ]; then
		cp -p /etc/honk/system.dae "$old_system" || { rm -rf "$repair_dir"; echo '{"ok":false,"message":"system_snapshot_failed"}'; return 1; }
		original_system_hash=$(sha256sum "$old_system" | awk '{print $1}')
	fi
	system_written_hash=$original_system_hash
	if [ "$old_running" = 1 ]; then
		if ! honk_lifecycle_stop 30; then
			logger -t honk "repair stop/drain unconfirmed; no restart attempted; snapshot retained at $repair_dir"
			echo '{"ok":false,"message":"service_stop_unconfirmed_snapshot_retained"}'
			return 1
		fi
	fi
	if [ "$initialized" = 1 ]; then system_listen=$lan_ip; else system_listen=127.0.0.1; fi
	if ! write_runtime_system "$lan_device" "$lan_ip" "$listen_port" "$system_listen"; then
		repair_rollback_ok=1
		[ -n "$system_written_hash" ] && ! restore_system && repair_rollback_ok=0
		restore_old_runtime || repair_rollback_ok=0
		if [ "$repair_rollback_ok" = 1 ]; then
			rm -rf "$repair_dir"
			echo '{"ok":false,"message":"system_config_repair_failed_rolled_back"}'
		else
			logger -t honk "repair rollback failed; snapshot retained at $repair_dir"
			echo '{"ok":false,"message":"system_config_repair_rollback_failed_snapshot_retained"}'
		fi
		return 1
	fi
	if [ "$initialized" = 1 ] && { [ "$old_running" = 1 ] || [ "$enabled" = 1 ]; }; then
		if ! honk_lifecycle_start 30; then
			repair_rollback_ok=1
			honk_lifecycle_stop 30 || repair_rollback_ok=0
			if [ "$repair_rollback_ok" = 1 ]; then restore_system || repair_rollback_ok=0; fi
			restore_old_runtime || repair_rollback_ok=0
			if [ "$repair_rollback_ok" = 1 ]; then
				rm -rf "$repair_dir"
				echo '{"ok":false,"message":"repair_restart_failed_rolled_back"}'
			else
				logger -t honk "repair restart rollback failed; snapshot retained at $repair_dir"
				echo '{"ok":false,"message":"repair_restart_and_rollback_failed_snapshot_retained"}'
			fi
			return 1
		fi
	fi
	system_written_hash=""
	rm -rf "$repair_dir"
	echo '{"ok":true,"message":"system_config_repaired"}'
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
	[ -r /usr/share/doona/index.html ] || { echo '{"ok":false,"message":"ui_assets_missing"}'; return 1; }
	if [ "$1" = read_credentials ]; then
		read_credentials || { echo '{"ok":false,"message":"invalid_credentials"}'; return 1; }
	fi
	[ -x "$HONK_CORE" ] || { echo '{"ok":false,"message":"core_missing"}'; return 1; }
	command -v curl >/dev/null 2>&1 || { echo '{"ok":false,"message":"curl_missing"}'; return 1; }
	pidof honk-core >/dev/null 2>&1 && { echo '{"ok":false,"message":"core_already_running"}'; return 1; }
	no_honk_resources || { echo '{"ok":false,"message":"honk_resources_already_exist"}'; return 1; }
	check_port || { echo '{"ok":false,"message":"listen_port_occupied"}'; return 1; }
	check_network || { echo '{"ok":false,"message":"lan_network_unavailable"}'; return 1; }
	network_settings || { echo '{"ok":false,"message":"lan_ipv4_unavailable"}'; return 1; }
	check_config || { echo '{"ok":false,"message":"invalid_package_config"}'; return 1; }
	return 0
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
	old_system=$temp_dir/system.dae
	cp -p /etc/honk/system.dae "$old_system" || { echo '{"ok":false,"message":"system_config_backup_failed"}'; return 1; }
	original_system_hash=$(sha256sum "$old_system" | awk '{print $1}')
	system_written_hash=$original_system_hash
	ensure_loopback_system || { echo '{"ok":false,"message":"loopback_listener_write_failed"}'; return 1; }
	mock_config=$temp_dir/mock.dae
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
	chmod 0600 "$mock_config" "$mock_log" 2>/dev/null || true
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

	write_runtime_system "$lan_device" "$lan_ip" || { restore_system; echo '{"ok":false,"message":"system_config_write_failed"}'; return 1; }
	lan_url="http://$lan_ip:$listen_port"
	if ! mock_start /etc/honk/config.dae "$mock_log" "$lan_url" "$response_file"; then
		restore_system
		echo '{"ok":false,"message":"generated_config_invalid_restored_loopback"}'
		return 1
	fi
	api_discovery "$lan_url" "$response_file" || {
		mock_stop >/dev/null 2>&1
		restore_system
		echo '{"ok":false,"message":"lan_api_verification_failed_restored_loopback"}'
		return 1
	}
	mock_stop || {
		restore_system
		echo '{"ok":false,"message":"mock_core_stop_failed_restored_loopback"}'
		return 1
	}
	uci set honk.main.initialized='1' && uci commit honk || {
		restore_system
		uci set honk.main.initialized='0' >/dev/null 2>&1
		uci commit honk >/dev/null 2>&1
		echo '{"ok":false,"message":"uci_commit_failed_restored_loopback"}'
		return 1
	}
	system_written_hash=""
	password=""
	username=""
	echo '{"ok":true,"message":"administrator_initialized"}'
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
		sync_local_direct
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
	*)
		echo "usage: $0 {check|diagnose|preflight|local-direct|initialize|settings|repair}" >&2
		exit 2
		;;
esac
