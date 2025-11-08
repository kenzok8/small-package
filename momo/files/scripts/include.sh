#!/bin/sh

. "$IPKG_INSTROOT/usr/share/libubox/jshn.sh"

# paths

## home
HOME_DIR="/etc/momo"
PROFILES_DIR="$HOME_DIR/profiles"
SUBSCRIPTIONS_DIR="$HOME_DIR/subscriptions"

## run
RUN_DIR="$HOME_DIR/run"
RUN_PROFILE_PATH="$RUN_DIR/config.json"

## ucode
UCODE_DIR="$HOME_DIR/ucode"
INCLUDE_UC="$UCODE_DIR/include.uc"
MIXIN_UC="$UCODE_DIR/mixin.uc"
HIJACK_UT="$UCODE_DIR/hijack.ut"

## scripts
SH_DIR="$HOME_DIR/scripts"
INCLUDE_SH="$SH_DIR/include.sh"
FIREWALL_INCLUDE_SH="$SH_DIR/firewall_include.sh"
DEBUG_SH="$SH_DIR/debug.sh"

## firewall
NFT_DIR="$HOME_DIR/firewall"
GEOIP_CN_NFT="$NFT_DIR/geoip_cn.nft"
GEOIP6_CN_NFT="$NFT_DIR/geoip6_cn.nft"

## log
LOG_DIR="/var/log/momo"
APP_LOG_PATH="$LOG_DIR/app.log"
CORE_LOG_PATH="$LOG_DIR/core.log"
DEBUG_LOG_PATH="$LOG_DIR/debug.log"

## temp
TEMP_DIR="/var/run/momo"
PID_FILE_PATH="$TEMP_DIR/momo.pid"
STARTED_FLAG_PATH="$TEMP_DIR/started.flag"
BRIDGE_NF_CALL_IPTABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_iptables.flag"
BRIDGE_NF_CALL_IP6TABLES_FLAG_PATH="$TEMP_DIR/bridge_nf_call_ip6tables.flag"

# functions
get_paths() {
	json_init

	json_add_string home_dir "$HOME_DIR"
	json_add_string profiles_dir "$PROFILES_DIR"
	json_add_string subscriptions_dir "$SUBSCRIPTIONS_DIR"

	json_add_string run_dir "$RUN_DIR"
	json_add_string run_profile_path "$RUN_PROFILE_PATH"

	json_add_string ucode_dir "$UCODE_DIR"
	json_add_string include_uc "$INCLUDE_UC"
	json_add_string hijack_ut "$HIJACK_UT"

	json_add_string sh_dir "$SH_DIR"
	json_add_string include_sh "$INCLUDE_SH"
	json_add_string firewall_include_sh "$FIREWALL_INCLUDE_SH"
	json_add_string debug_sh "$DEBUG_SH"

	json_add_string nft_dir "$NFT_DIR"
	json_add_string geoip_cn_nft "$GEOIP_CN_NFT"
	json_add_string geoip6_cn_nft "$GEOIP6_CN_NFT"

	json_add_string log_dir "$LOG_DIR"
	json_add_string app_log_path "$APP_LOG_PATH"
	json_add_string core_log_path "$CORE_LOG_PATH"
	json_add_string debug_log_path "$DEBUG_LOG_PATH"

	json_add_string temp_dir "$TEMP_DIR"
	json_add_string pid_file_path "$PID_FILE_PATH"
	json_add_string started_flag_path "$STARTED_FLAG_PATH"
	json_add_string bridge_nf_call_iptables_flag_path "$BRIDGE_NF_CALL_IPTABLES_FLAG_PATH"
	json_add_string bridge_nf_call_ip6tables_flag_path "$BRIDGE_NF_CALL_IP6TABLES_FLAG_PATH"

	json_dump

	json_cleanup
}

format_filesize() {
	local b; b=1
	local kb; kb=$((b * 1024))
	local mb; mb=$((kb * 1024))
	local gb; gb=$((mb * 1024))
	local tb; tb=$((gb * 1024))
	local pb; pb=$((tb * 1024))
	local size; size=$1
	if [ -n "$size" ]; then
		if [ "$size" -lt "$kb" ]; then
			echo "$(awk "BEGIN {print $size / $b}") B"
		elif [ "$size" -lt "$mb" ]; then
			echo "$(awk "BEGIN {print $size / $kb}") KB"
		elif [ "$size" -lt "$gb" ]; then
			echo "$(awk "BEGIN {print $size / $mb}") MB"
		elif [ "$size" -lt "$tb" ]; then
			echo "$(awk "BEGIN {print $size / $gb}") GB"
		elif [ "$size" -lt "$pb" ]; then
			echo "$(awk "BEGIN {print $size / $tb}") TB"
		else
			echo "$(awk "BEGIN {print $size / $pb}") PB"
		fi
	fi
}

prepare_files() {
	if [ ! -d "$LOG_DIR" ]; then
		mkdir -p "$LOG_DIR"
	fi
	if [ ! -f "$APP_LOG_PATH" ]; then
		touch "$APP_LOG_PATH"
	fi
	if [ ! -f "$CORE_LOG_PATH" ]; then
		touch "$CORE_LOG_PATH"
	fi
	if [ ! -d "$TEMP_DIR" ]; then
		mkdir -p "$TEMP_DIR"
	fi
}

clear_log() {
	echo -n > "$APP_LOG_PATH"
	echo -n > "$CORE_LOG_PATH"
}

log() {
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$1] $2" >> "$APP_LOG_PATH"
}
