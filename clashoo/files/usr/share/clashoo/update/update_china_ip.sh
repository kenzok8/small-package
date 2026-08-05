#!/bin/sh

set -eu

LOG_FILE="/tmp/clash_update.txt"
NFT_DIR="/usr/share/clashoo/nftables"
TARGET_V4="${NFT_DIR}/geoip_cn.nft"
TARGET_V6="${NFT_DIR}/geoip6_cn.nft"
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
render_nft_set "$TMP_V4" "$OUT_V4" clashoo_china ipv4_addr
mv "$OUT_V4" "$TARGET_V4"
chmod 644 "$TARGET_V4" >/dev/null 2>&1 || true
log '大陆 IPv4 白名单更新完成'

if download_with_fallback "$url6" "$TMP_V6"; then
	if [ -s "$TMP_V6" ]; then
		render_nft_set "$TMP_V6" "$OUT_V6" clashoo_china6 ipv6_addr
		mv "$OUT_V6" "$TARGET_V6"
		chmod 600 "$TARGET_V6" >/dev/null 2>&1 || true
		log '大陆 IPv6 白名单更新完成'
	else
		log '大陆 IPv6 白名单下载为空，保留原文件'
	fi
else
	log '大陆 IPv6 白名单下载失败，保留原文件'
fi

if bool_enabled "$bypass_china" || bool_enabled "$bypass_china_ipv6"; then
	if /usr/share/clashoo/net/fw4.sh apply >/dev/null 2>&1; then
		log "大陆白名单规则已重载（IPv4=${bypass_china:-0}，IPv6=${bypass_china_ipv6:-0}）"
	else
		log '大陆白名单规则重载失败'
		exit 1
	fi
else
	log '大陆 IPv4/IPv6 绕过均未启用，仅更新白名单文件'
fi

log '大陆白名单更新流程完成'
