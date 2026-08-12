#!/bin/sh

set -eu

LOG_FILE="${LOG_FILE:-/tmp/clash_update.txt}"
NFT_DIR="${NFT_DIR:-/usr/share/clashoo/nftables}"
TARGET_V4="${NFT_DIR}/geoip_cn.nft"
TARGET_V6="${NFT_DIR}/geoip6_cn.nft"
FW4_SCRIPT="${FW4_SCRIPT:-/usr/share/clashoo/net/fw4.sh}"
RUNTIME_STATE_FILE="${RUNTIME_STATE_FILE:-/tmp/clashoo/runtime_state}"
PROC_ROOT="${PROC_ROOT:-/proc}"
TMP_V4="/tmp/china_ip.txt.$$"
TMP_V6="/tmp/china_ipv6.txt.$$"
OUT_V4="/tmp/geoip_cn.nft.$$"
OUT_V6="/tmp/geoip6_cn.nft.$$"

log() {
	printf '  %s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

bool_enabled() {
	case "$1" in
		1|true|TRUE|yes|on) return 0 ;;
		*) return 1 ;;
	esac
}

download_with_fallback() {
	local url="$1"
	local output="$2"
	local ip

	if curl -fsSL "$url" -o "$output"; then
		return 0
	fi

	case "$url" in
		https://ispip.clang.cn/*)
			for ip in 182.247.248.127 103.220.64.183; do
				if curl -fsSL --resolve "ispip.clang.cn:443:${ip}" "$url" -o "$output"; then
					log "DNS 异常，已使用 --resolve(${ip}) 回源下载"
					return 0
				fi
			done
			;;
	esac

	return 1
}

cleanup() {
	rm -f "$TMP_V4" "$TMP_V6" "$OUT_V4" "$OUT_V6"
}

trap cleanup EXIT INT TERM

render_nft_set() {
	local source_file="$1"
	local output_file="$2"
	local set_name="$3"
	local set_type="$4"

	awk -v set_name="$set_name" -v set_type="$set_type" '
	BEGIN {
		print "set " set_name " {"
		print "\ttype " set_type ";"
		print "\tflags interval;"
		print "\tauto-merge;"
		print "\telements = {"
		first = 1
	}
	!/^[[:space:]]*$/ && !/^[[:space:]]*#/ {
		gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
		if ($0 == "")
			next
		if (!first)
			print ","
		printf "\t\t%s", $0
		first = 0
	}
	END {
		if (!first)
			print ""
		print "\t}"
		print "}"
	}
	' "$source_file" > "$output_file"
}

url4="$(uci -q get clashoo.config.china_ip_url 2>/dev/null || true)"
url6="$(uci -q get clashoo.config.china_ipv6_url 2>/dev/null || true)"
bypass_china="$(uci -q get clashoo.config.bypass_china 2>/dev/null || true)"
bypass_china_ipv6="$(uci -q get clashoo.config.bypass_china_ipv6 2>/dev/null || true)"
[ -n "$bypass_china_ipv6" ] || bypass_china_ipv6="$bypass_china"

[ -n "$url4" ] || url4='https://ispip.clang.cn/all_cn.txt'
[ -n "$url6" ] || url6='https://ispip.clang.cn/all_cn_ipv6.txt'

mkdir -p "$NFT_DIR"

log '开始更新大陆白名单'

download_with_fallback "$url4" "$TMP_V4"
[ -s "$TMP_V4" ] || {
	log '大陆 IPv4 白名单下载失败：返回为空'
	exit 1
}
changed=0

render_nft_set "$TMP_V4" "$OUT_V4" clashoo_china ipv4_addr
if cmp -s "$OUT_V4" "$TARGET_V4"; then
	log '大陆 IPv4 白名单内容无变化'
else
	mv "$OUT_V4" "$TARGET_V4"
	chmod 644 "$TARGET_V4" >/dev/null 2>&1 || true
	changed=1
	log '大陆 IPv4 白名单更新完成'
fi

if download_with_fallback "$url6" "$TMP_V6"; then
	if [ -s "$TMP_V6" ]; then
		render_nft_set "$TMP_V6" "$OUT_V6" clashoo_china6 ipv6_addr
		if cmp -s "$OUT_V6" "$TARGET_V6"; then
			log '大陆 IPv6 白名单内容无变化'
		else
			mv "$OUT_V6" "$TARGET_V6"
			chmod 600 "$TARGET_V6" >/dev/null 2>&1 || true
			changed=1
			log '大陆 IPv6 白名单更新完成'
		fi
	else
		log '大陆 IPv6 白名单下载为空，保留原文件'
	fi
else
	log '大陆 IPv6 白名单下载失败，保留原文件'
fi

instance_pid() {
	ubus call service list "{\"name\":\"$1\",\"verbose\":true}" 2>/dev/null |
		jsonfilter -e "@[\"$1\"].instances.*.pid" 2>/dev/null | head -n1
}

pid_running() {
	[ -n "$1" ] && [ -d "$PROC_ROOT/$1" ]
}

clashoo_manages_singbox() {
	[ -r "$RUNTIME_STATE_FILE" ] || return 1
	grep -qx 'configured_core=singbox' "$RUNTIME_STATE_FILE" 2>/dev/null || return 1
	case "$(sed -n 's/^health_detail=//p' "$RUNTIME_STATE_FILE" 2>/dev/null | head -n1)" in
		service_stopped|service_disabled|boot_disabled|preflight:*|start:*) return 1 ;;
	esac
	return 0
}

selected_core_running() {
	local name pid
	if [ "$(uci -q get clashoo.config.core_type 2>/dev/null)" = "singbox" ]; then
		bool_enabled "$(uci -q get sing-box.main.enabled 2>/dev/null)" || return 1
		clashoo_manages_singbox || return 1
		name="sing-box"
	else
		name="clashoo"
	fi
	pid="$(instance_pid "$name")"
	pid_running "$pid"
}

firewall_managed() {
	bool_enabled "$(uci -q get clashoo.config.enable 2>/dev/null)" || return 1
	[ "$(uci -q get clashoo.config.core_only 2>/dev/null)" = "1" ] && return 1
	selected_core_running
}

if [ "$changed" -eq 0 ]; then
	log '白名单内容未变，跳过防火墙重载'
elif ! firewall_managed; then
	log '未接管防火墙（服务未运行或仅内核模式），仅更新白名单文件'
elif bool_enabled "$bypass_china" || bool_enabled "$bypass_china_ipv6"; then
	if "$FW4_SCRIPT" apply >/dev/null 2>&1; then
		log "大陆白名单规则已重载（IPv4=${bypass_china:-0}，IPv6=${bypass_china_ipv6:-0}）"
	else
		log '大陆白名单规则重载失败'
		exit 1
	fi
else
	log '大陆 IPv4/IPv6 绕过均未启用，仅更新白名单文件'
fi

log '大陆白名单更新流程完成'
