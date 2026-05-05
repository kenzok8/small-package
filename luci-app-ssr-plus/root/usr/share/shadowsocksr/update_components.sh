#!/bin/sh

set -u

XRAY_RELEASE_PAGE="https://github.com/XTLS/Xray-core/releases/latest"
MIHOMO_RELEASE_PAGE="https://github.com/MetaCubeX/mihomo/releases/latest"
NAIVEPROXY_RELEASE_API="https://api.github.com/repos/klzgrad/naiveproxy/releases/latest"
XRAY_BINARY="/usr/bin/xray"
MIHOMO_BINARY="/usr/bin/mihomo"
NAIVEPROXY_BINARY="/usr/bin/naive"
COUNTRY_MMDB_URL="https://testingcf.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/lite/Country.mmdb"
GEOSITE_URL="https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat"
GEOIP_DAT_URL="https://testingcf.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat"
COUNTRY_MMDB_FILE="/usr/share/shadowsocksr/Country.mmdb"
GEOIP_DAT_FILE="/usr/share/v2ray/geoip.dat"
GEOSITE_DAT_FILE="/usr/share/v2ray/geosite.dat"
OPENCLASH_GEOSITE_FILE="/etc/openclash/GeoSite.dat"
OPENCLASH_GEOIP_DAT_FILE="/etc/openclash/geoip.dat"
OPENCLASH_GEOSITE_DAT_FILE="/etc/openclash/geosite.dat"

log_kv() {
	key="$1"
	shift
	printf '%s=%s\n' "$key" "$*"
}

file_mtime() {
	local path="$1"
	[ -f "$path" ] || {
		printf '%s' 'File Not Exist'
		return 0
	}
	date -r "$path" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf '%s' 'Unknown'
}

file_size() {
	local path="$1"
	[ -f "$path" ] || {
		printf '%s' '0'
		return 0
	}
	wc -c < "$path" 2>/dev/null | tr -d '[:space:]'
}

resolve_existing_geo_file() {
	local primary="$1"
	local fallback="$2"

	if [ -f "$primary" ]; then
		printf '%s' "$primary"
	elif [ -n "$fallback" ] && [ -f "$fallback" ]; then
		printf '%s' "$fallback"
	else
		printf '%s' "$primary"
	fi
}

resolve_geosite_file() {
	resolve_existing_geo_file "$GEOSITE_DAT_FILE" "$OPENCLASH_GEOSITE_FILE"
}

resolve_v2ray_geoip_file() {
	resolve_existing_geo_file "$GEOIP_DAT_FILE" "$OPENCLASH_GEOIP_DAT_FILE"
}

resolve_v2ray_geosite_file() {
	resolve_existing_geo_file "$GEOSITE_DAT_FILE" "$OPENCLASH_GEOSITE_DAT_FILE"
}

trim_version() {
	printf '%s' "$1" | sed 's/^v//'
}

get_component_mirror() {
	if [ -n "${COMPONENT_MIRROR:-}" ]; then
		echo "$COMPONENT_MIRROR"
		return 0
	fi
	uci -q get shadowsocksr.@global[0].component_mirror 2>/dev/null || echo "direct"
}

mirror_wrap_url() {
	local raw_url="$1"
	local mirror

	mirror="$(get_component_mirror)"
	case "$mirror" in
		direct|"")
			printf '%s' "$raw_url"
			;;
		ghproxy)
			printf 'https://mirror.ghproxy.com/%s' "$raw_url"
			;;
		ghproxy_cc)
			printf 'https://ghproxy.cc/%s' "$raw_url"
			;;
		ghfast)
			printf 'https://ghfast.top/%s' "$raw_url"
			;;
		jsdelivr)
			case "$raw_url" in
				https://github.com/XTLS/Xray-core/releases/download/*)
					printf '%s' "$raw_url" | sed 's#https://github.com/XTLS/Xray-core/releases/download/\(v[^/]*\)/\(.*\)#https://fastly.jsdelivr.net/gh/XTLS/Xray-core@\1/\2#'
					;;
				https://github.com/MetaCubeX/mihomo/releases/download/*)
					printf '%s' "$raw_url" | sed 's#https://github.com/MetaCubeX/mihomo/releases/download/\(v[^/]*\)/\(.*\)#https://fastly.jsdelivr.net/gh/MetaCubeX/mihomo@\1/\2#'
					;;
				*)
					printf '%s' "$raw_url"
					;;
			esac
			;;
		*)
			printf '%s' "$raw_url"
			;;
	esac
}

version_gt() {
	local left right first

	left="$(trim_version "${1:-}")"
	right="$(trim_version "${2:-}")"

	[ -n "$left" ] || return 1
	[ -n "$right" ] || return 1
	[ "$left" = "$right" ] && return 1

	first="$(printf '%s\n%s\n' "$left" "$right" | sort -V | tail -n 1)"
	[ "$first" = "$left" ]
}

naiveproxy_versions_equal() {
	local left right

	left="$(trim_version "${1:-}")"
	right="$(trim_version "${2:-}")"
	[ -n "$left" ] || return 1
	[ -n "$right" ] || return 1
	[ "$left" = "$right" ] && return 0
	[ "${left%%-*}" = "${right%%-*}" ]
}

get_openwrt_arch() {
	local arch

	arch=""
	if [ -r /etc/openwrt_release ]; then
		arch="$(. /etc/openwrt_release 2>/dev/null; printf '%s' "${DISTRIB_ARCH:-}")"
	fi

	if [ -z "$arch" ] && command -v opkg >/dev/null 2>&1; then
		arch="$(opkg print-architecture 2>/dev/null | awk '$2 != "all" && $2 != "noarch" { print $2 }' | tail -n 1)"
	fi

	if [ -z "$arch" ] && command -v uname >/dev/null 2>&1; then
		arch="$(uname -m 2>/dev/null)"
	fi

	printf '%s' "$arch"
}

is_openwrt_env() {
	[ -r /etc/openwrt_release ] || command -v opkg >/dev/null 2>&1
}

find_mihomo_binary() {
	if command -v mihomo >/dev/null 2>&1; then
		command -v mihomo
		return 0
	fi

	for path in /usr/bin/mihomo /usr/libexec/mihomo /etc/ssrplus/bin/mihomo; do
		if [ -x "$path" ]; then
			printf '%s' "$path"
			return 0
		fi
	done

	return 1
}

find_naiveproxy_binary() {
	if command -v naive >/dev/null 2>&1; then
		command -v naive
		return 0
	fi

	for path in /usr/bin/naive /usr/libexec/naive /etc/ssrplus/bin/naive; do
		if [ -x "$path" ]; then
			printf '%s' "$path"
			return 0
		fi
	done

	return 1
}

get_xray_current_version() {
	if [ ! -x "$XRAY_BINARY" ]; then
		return 1
	fi

	"$XRAY_BINARY" version 2>/dev/null | sed -n 's/^Xray[[:space:]]\+\([^[:space:]]\+\).*$/\1/p' | sed -n '1p'
	return 0
}

get_mihomo_current_version() {
	local binary

	binary="$(find_mihomo_binary)" || return 1
	"$binary" -v 2>/dev/null | sed -n 's/.* v\([0-9][0-9.]*\).*/\1/p' | sed -n '1p'
	return 0
}

get_naiveproxy_current_version() {
	local binary

	binary="$(find_naiveproxy_binary)" || return 1
	"$binary" --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' | sed -n '1p'
	return 0
}

map_xray_asset() {
	case "$1" in
		x86_64*|amd64*)
			printf '%s' 'Xray-linux-64.zip'
			;;
		i386*|i486*|i586*|i686*|x86*)
			printf '%s' 'Xray-linux-32.zip'
			;;
		aarch64*|arm64*)
			printf '%s' 'Xray-linux-arm64-v8a.zip'
			;;
		*armv7*|*cortex-a*|*neon*|*vfpv3*|*vfpv4*)
			printf '%s' 'Xray-linux-arm32-v7a.zip'
			;;
		*armv6*|*arm1176*)
			printf '%s' 'Xray-linux-arm32-v6.zip'
			;;
		*armv5*|*arm926*|*xscale*)
			printf '%s' 'Xray-linux-arm32-v5.zip'
			;;
		mips64el*|mips64le*)
			printf '%s' 'Xray-linux-mips64le.zip'
			;;
		mips64*)
			printf '%s' 'Xray-linux-mips64.zip'
			;;
		mipsel*|mips32el*|mips32le*)
			printf '%s' 'Xray-linux-mips32le.zip'
			;;
		mips*)
			printf '%s' 'Xray-linux-mips32.zip'
			;;
		riscv64*)
			printf '%s' 'Xray-linux-riscv64.zip'
			;;
		loongarch64*|loong64*)
			printf '%s' 'Xray-linux-loong64.zip'
			;;
		powerpc64*|ppc64*)
			printf '%s' 'Xray-linux-ppc64.zip'
			;;
		s390x*)
			printf '%s' 'Xray-linux-s390x.zip'
			;;
		*)
			return 1
			;;
	 esac
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1
}

select_unzip_cmd() {
	if require_cmd unzip; then
		printf '%s' 'unzip -oq'
		return 0
	fi

	if busybox unzip >/dev/null 2>&1; then
		printf '%s' 'busybox unzip -o'
		return 0
	fi

	return 1
}

select_gzip_cmd() {
	if require_cmd gzip; then
		printf '%s' 'gzip -dc'
		return 0
	fi

	if busybox gzip >/dev/null 2>&1; then
		printf '%s' 'busybox gzip -dc'
		return 0
	fi

	return 1
}

select_xz_cmd() {
	if require_cmd xz; then
		printf '%s' 'xz -dc'
		return 0
	fi

	if busybox xz >/dev/null 2>&1; then
		printf '%s' 'busybox xz -dc'
		return 0
	fi

	return 1
}

select_tar_cmd() {
	if require_cmd tar; then
		printf '%s' 'tar'
		return 0
	fi

	if busybox tar --help >/dev/null 2>&1; then
		printf '%s' 'busybox tar'
		return 0
	fi

	return 1
}

select_wget_cmd() {
	if require_cmd wget-ssl; then
		printf '%s' 'wget-ssl'
		return 0
	fi

	if require_cmd wget; then
		printf '%s' 'wget'
		return 0
	fi

	return 1
}

curl_effective_url() {
	local target="$1"
	local effective=""
	local headers=""
	local location=""

	headers="$(curl -kfsSI --http1.1 --connect-timeout 10 --retry 2 -A 'curl/8.0' -H 'Accept-Encoding: identity' "$target" 2>/dev/null || true)"
	location="$(printf '%s\n' "$headers" | sed -n 's/^[Ll]ocation:[[:space:]]*//p' | sed 's/\r$//' | sed 's/[[:space:]]\+\[following\]$//' | sed -n '1p')"
	[ -n "$location" ] && effective="$location"
	[ -n "$effective" ] || effective="$(curl -kfsSL --http1.1 --connect-timeout 10 --retry 2 -A 'curl/8.0' -H 'Accept-Encoding: identity' -o /dev/null -w '%{url_effective}' "$target" 2>/dev/null || true)"
	[ -n "$effective" ] || return 1

	printf '%s' "$effective"
}

wget_effective_url() {
	local target="$1"
	local wget_cmd output location

	wget_cmd="$(select_wget_cmd)" || return 1
	output="$($wget_cmd --server-response --max-redirect=0 --spider --timeout=20 --tries=3 --no-check-certificate "$target" 2>&1 || true)"
	location="$(printf '%s\n' "$output" | sed -n 's/^[Ll]ocation:[[:space:]]*//p' | sed 's/\r$//' | sed 's/[[:space:]]\+\[following\]$//' | sed -n '1p')"

	if [ -n "$location" ]; then
		printf '%s' "$location"
		return 0
	fi

	printf '%s\n' "$output" | grep -qE 'HTTP/[0-9.]+ 200' || return 1
	printf '%s' "$target"
}

effective_url() {
	local target="$1"
	local url=""

	url="$(curl_effective_url "$target" 2>/dev/null || true)"
	[ -n "$url" ] || url="$(wget_effective_url "$target" 2>/dev/null || true)"
	[ -n "$url" ] || return 1
	printf '%s' "$url"
}

fetch_text() {
	local url="$1"
	local wget_cmd

	if curl -kfsSL --http1.1 --connect-timeout 10 --retry 2 -A 'curl/8.0' -H 'Accept: application/vnd.github+json' "$url" 2>/dev/null; then
		return 0
	fi

	wget_cmd="$(select_wget_cmd)" || return 1
	"$wget_cmd" --header='Accept: application/vnd.github+json' --timeout=20 --tries=3 --no-check-certificate -O - "$url" 2>/dev/null
}

download_file() {
	local url="$1"
	local output="$2"
	local wget_cmd

	if curl -kfsSL --http1.1 --connect-timeout 10 --retry 2 -A 'curl/8.0' -H 'Accept-Encoding: identity' -o "$output" "$url" 2>/dev/null; then
		return 0
	fi

	wget_cmd="$(select_wget_cmd)" || return 1
	"$wget_cmd" --no-check-certificate --timeout=20 --tries=3 -O "$output" "$url" >/dev/null 2>&1
}

geo_validate_download() {
	local new_file="$1"
	local current_file="$2"
	local new_size current_size

	new_size="$(file_size "$new_file")"
	[ "${new_size:-0}" -gt 0 ] 2>/dev/null || return 1

	if [ -f "$current_file" ]; then
		current_size="$(file_size "$current_file")"
		[ "${new_size:-0}" -ge "${current_size:-0}" ] 2>/dev/null || return 1
	fi

	return 0
}

geo_safe_replace() {
	local new_file="$1"
	local current_file="$2"
	local backup_file="$3"

	mkdir -p "$(dirname "$current_file")" || return 1
	[ -f "$current_file" ] && cp -fp "$current_file" "$backup_file" 2>/dev/null || true

	if ! cp -f "$new_file" "$current_file"; then
		[ -f "$backup_file" ] && cp -f "$backup_file" "$current_file" 2>/dev/null || true
		return 1
	fi

	return 0
}

geo_local_info() {
	local geo="$1"
	local file1=""
	local file2=""

	case "$geo" in
		country_mmdb)
			file1="$COUNTRY_MMDB_FILE"
			;;
		geosite)
			file1="$(resolve_geosite_file)"
			;;
		v2ray_geo)
			file1="$(resolve_v2ray_geoip_file)"
			file2="$(resolve_v2ray_geosite_file)"
			;;
		*)
			log_kv error 'unsupported_component'
			return 1
			;;
	esac

	log_kv component "$geo"
	log_kv installed "$([ -f "$file1" ] && echo 1 || echo 0)"
	log_kv current_version "$(file_mtime "$file1")"
	log_kv current_version_extra "$([ -n "$file2" ] && file_mtime "$file2" || echo '')"
	log_kv latest_version ''
	log_kv can_upgrade 0
	log_kv error ''
}

geo_upgrade() {
	local geo="$1"
	local tmp_dir file_a url_a file_b url_b msg

	tmp_dir="$(mktemp -d /tmp/ssrplus-geo.XXXXXX)"
	[ -n "$tmp_dir" ] && [ -d "$tmp_dir" ] || {
		log_kv component "$geo"
		log_kv success 0
		log_kv message 'Failed to create temp directory'
		return 0
	}
	trap "rm -rf '$tmp_dir'" EXIT INT TERM

	case "$geo" in
		country_mmdb)
			file_a="$COUNTRY_MMDB_FILE"
			url_a="$(mirror_wrap_url "$COUNTRY_MMDB_URL")"
			download_file "$url_a" "$tmp_dir/file_a" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Download failed'
				return 0
			}
			geo_validate_download "$tmp_dir/file_a" "$file_a" || {
				log_kv component "$geo"
				log_kv success 1
				log_kv current_version "$(file_mtime "$file_a")"
				log_kv current_version_extra ''
				log_kv latest_version "$(file_mtime "$file_a")"
				log_kv can_upgrade 0
				log_kv message 'Already up to date'
				return 0
			}
			geo_safe_replace "$tmp_dir/file_a" "$file_a" "$tmp_dir/file_a.bak" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Install failed'
				return 0
			}
			msg='Upgrade completed'
			;;
		geosite)
			file_a="$(resolve_geosite_file)"
			url_a="$(mirror_wrap_url "$GEOSITE_URL")"
			download_file "$url_a" "$tmp_dir/file_a" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Download failed'
				return 0
			}
			geo_validate_download "$tmp_dir/file_a" "$file_a" || {
				log_kv component "$geo"
				log_kv success 1
				log_kv current_version "$(file_mtime "$file_a")"
				log_kv current_version_extra ''
				log_kv latest_version "$(file_mtime "$file_a")"
				log_kv can_upgrade 0
				log_kv message 'Already up to date'
				return 0
			}
			geo_safe_replace "$tmp_dir/file_a" "$file_a" "$tmp_dir/file_a.bak" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Install failed'
				return 0
			}
			msg='Upgrade completed'
			;;
		v2ray_geo)
			file_a="$(resolve_v2ray_geoip_file)"
			url_a="$(mirror_wrap_url "$GEOIP_DAT_URL")"
			file_b="$(resolve_v2ray_geosite_file)"
			url_b="$(mirror_wrap_url "$GEOSITE_URL")"
			download_file "$url_a" "$tmp_dir/file_a" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Download failed'
				return 0
			}
			download_file "$url_b" "$tmp_dir/file_b" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Download failed'
				return 0
			}
			geo_validate_download "$tmp_dir/file_a" "$file_a" || {
				log_kv component "$geo"
				log_kv success 1
				log_kv current_version "$(file_mtime "$file_a")"
				log_kv current_version_extra "$(file_mtime "$file_b")"
				log_kv latest_version "$(file_mtime "$file_a")"
				log_kv can_upgrade 0
				log_kv message 'Already up to date'
				return 0
			}
			geo_validate_download "$tmp_dir/file_b" "$file_b" || {
				log_kv component "$geo"
				log_kv success 1
				log_kv current_version "$(file_mtime "$file_a")"
				log_kv current_version_extra "$(file_mtime "$file_b")"
				log_kv latest_version "$(file_mtime "$file_a")"
				log_kv can_upgrade 0
				log_kv message 'Already up to date'
				return 0
			}
			geo_safe_replace "$tmp_dir/file_a" "$file_a" "$tmp_dir/file_a.bak" || {
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Install failed'
				return 0
			}
			geo_safe_replace "$tmp_dir/file_b" "$file_b" "$tmp_dir/file_b.bak" || {
				[ -f "$tmp_dir/file_a.bak" ] && cp -f "$tmp_dir/file_a.bak" "$file_a" 2>/dev/null || true
				log_kv component "$geo"
				log_kv success 0
				log_kv message 'Install failed'
				return 0
			}
			msg='Upgrade completed'
			;;
		*)
			log_kv component "$geo"
			log_kv success 0
			log_kv message 'Unsupported component'
			return 0
			;;
	esac

	log_kv component "$geo"
	log_kv success 1
	log_kv current_version "$(file_mtime "$file_a")"
	log_kv current_version_extra "$([ -n "${file_b:-}" ] && file_mtime "$file_b" || echo '')"
	log_kv latest_version "$(file_mtime "$file_a")"
	log_kv can_upgrade 0
	log_kv message "$msg"
	return 0
}

get_xray_latest_tag() {
	local location tag

	location="$(effective_url "$XRAY_RELEASE_PAGE")" || return 1
	tag="$(printf '%s' "$location" | sed -n 's#.*/tag/\(v[0-9][^/]*\)$#\1#p' | sed -n '1p')"
	[ -n "$tag" ] || return 1
	printf '%s' "$tag"
}

get_xray_latest_info() {
	local tag version asset url arch

	arch="$(get_openwrt_arch)"
	asset="$(map_xray_asset "$arch")" || return 2
	tag="$(get_xray_latest_tag)" || return 3
	version="$(trim_version "$tag")"
	url="$(mirror_wrap_url "https://github.com/XTLS/Xray-core/releases/download/$tag/$asset")"

	[ -n "$tag" ] && [ -n "$version" ] && [ -n "$url" ] || return 4

	log_kv arch "$arch"
	log_kv asset "$asset"
	log_kv latest_version "$version"
	log_kv download_url "$url"
	return 0
}

get_mihomo_latest_tag() {
	local location tag

	location="$(effective_url "$MIHOMO_RELEASE_PAGE")" || return 1
	tag="$(printf '%s' "$location" | sed -n 's#.*/tag/\(v[0-9][^/]*\)$#\1#p' | sed -n '1p')"
	[ -n "$tag" ] || return 1
	printf '%s' "$tag"
}

map_mihomo_asset() {
	local arch="$1"
	local version="$2"

	case "$arch" in
		x86_64*|amd64*)
			printf 'mihomo-linux-amd64-compatible-v%s.gz' "$version"
			;;
		i386*|i486*|i586*|i686*|x86*)
			printf 'mihomo-linux-386-v%s.gz' "$version"
			;;
		aarch64*|arm64*)
			printf 'mihomo-linux-arm64-v%s.gz' "$version"
			;;
		*armv7*|*cortex-a*|*neon*|*vfpv3*|*vfpv4*)
			printf 'mihomo-linux-armv7-v%s.gz' "$version"
			;;
		*armv6*|*arm1176*)
			printf 'mihomo-linux-armv6-v%s.gz' "$version"
			;;
		*armv5*|*arm926*|*xscale*)
			printf 'mihomo-linux-armv5-v%s.gz' "$version"
			;;
		mips64el*|mips64le*)
			printf 'mihomo-linux-mips64le-v%s.gz' "$version"
			;;
		mips64*)
			printf 'mihomo-linux-mips64-v%s.gz' "$version"
			;;
		mipsel*|mips32el*|mips32le*)
			printf 'mihomo-linux-mipsle-softfloat-v%s.gz' "$version"
			;;
		mips*)
			printf 'mihomo-linux-mips-softfloat-v%s.gz' "$version"
			;;
		riscv64*)
			printf 'mihomo-linux-riscv64-v%s.gz' "$version"
			;;
		loongarch64*|loong64*)
			printf 'mihomo-linux-loong64-abi1-v%s.gz' "$version"
			;;
		powerpc64le*|ppc64le*)
			printf 'mihomo-linux-ppc64le-v%s.gz' "$version"
			;;
		s390x*)
			printf 'mihomo-linux-s390x-v%s.gz' "$version"
			;;
		*)
			return 1
			;;
	 esac
}

get_mihomo_latest_info() {
	local arch tag version asset url

	arch="$(get_openwrt_arch)"
	tag="$(get_mihomo_latest_tag)" || return 3
	version="$(trim_version "$tag")"
	asset="$(map_mihomo_asset "$arch" "$version")" || return 2
	url="$(mirror_wrap_url "https://github.com/MetaCubeX/mihomo/releases/download/$tag/$asset")"

	log_kv arch "$arch"
	log_kv asset "$asset"
	log_kv latest_version "$version"
	log_kv download_url "$url"
	return 0
}

map_naiveproxy_linux_asset() {
	case "$1" in
		x86_64*|amd64*)
			printf '%s' 'x64'
			;;
		i386*|i486*|i586*|i686*|x86*)
			printf '%s' 'x86'
			;;
		aarch64*|arm64*)
			printf '%s' 'arm64'
			;;
		*armv7*|*cortex-a*|*neon*|*vfpv3*|*vfpv4*)
			printf '%s' 'arm'
			;;
		mips64el*|mips64le*)
			printf '%s' 'mips64el'
			;;
		mipsel*|mips32el*|mips32le*)
			printf '%s' 'mipsel'
			;;
		riscv64*)
			printf '%s' 'riscv64'
			;;
		loongarch64*|loong64*)
			printf '%s' 'loong64'
			;;
		*)
			return 1
			;;
	esac
}

normalize_naiveproxy_openwrt_arch() {
	local arch="${1%%+*}"
	printf '%s' "$arch"
}

naiveproxy_openwrt_arch_candidates() {
	local normalized

	normalized="$(normalize_naiveproxy_openwrt_arch "$1")"
	printf '%s\n' "$normalized"

	case "$normalized" in
		aarch64_*)
			[ "$normalized" = "aarch64_generic" ] || printf '%s\n' 'aarch64_generic'
			;;
		x86|i386|i486|i586|i686)
			printf '%s\n' 'x86'
			;;
	esac
}

asset_list_has() {
	local asset_list="$1"
	local candidate="$2"

	printf '%s\n' "$asset_list" | grep -Fx "$candidate" >/dev/null 2>&1
}

select_naiveproxy_asset() {
	local asset_list="$1"
	local tag="$2"
	local arch="$3"
	local candidate linux_arch candidate_arch

	if is_openwrt_env; then
		for candidate_arch in $(naiveproxy_openwrt_arch_candidates "$arch"); do
			candidate="naiveproxy-${tag}-openwrt-${candidate_arch}-static.tar.xz"
			if asset_list_has "$asset_list" "$candidate"; then
				printf '%s' "$candidate"
				return 0
			fi

			candidate="naiveproxy-${tag}-openwrt-${candidate_arch}.tar.xz"
			if asset_list_has "$asset_list" "$candidate"; then
				printf '%s' "$candidate"
				return 0
			fi
		done
	fi

	linux_arch="$(map_naiveproxy_linux_asset "$arch" 2>/dev/null || true)"
	if [ -n "$linux_arch" ]; then
		candidate="naiveproxy-${tag}-linux-${linux_arch}.tar.xz"
		if asset_list_has "$asset_list" "$candidate"; then
			printf '%s' "$candidate"
			return 0
		fi
	fi

	return 1
}

get_naiveproxy_latest_info() {
	local arch release_json tag version asset asset_list url

	arch="$(get_openwrt_arch)"
	release_json="$(fetch_text "$NAIVEPROXY_RELEASE_API")" || return 3
	tag="$(printf '%s\n' "$release_json" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | sed -n '1p')"
	[ -n "$tag" ] || return 3
	version="$(trim_version "$tag")"
	asset_list="$(printf '%s\n' "$release_json" | sed -n 's/.*"name":[[:space:]]*"\([^"]*\.tar\.xz\)".*/\1/p')"
	asset="$(select_naiveproxy_asset "$asset_list" "$tag" "$arch")" || return 4
	url="$(mirror_wrap_url "https://github.com/klzgrad/naiveproxy/releases/download/$tag/$asset")"

	log_kv arch "$arch"
	log_kv asset "$asset"
	log_kv latest_version "$version"
	log_kv download_url "$url"
	return 0
}

xray_info() {
	local current installed latest_output latest_rc latest_version arch asset can_upgrade

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	asset="$(map_xray_asset "$arch" 2>/dev/null || true)"
	if current="$(get_xray_current_version)" && [ -n "$current" ]; then
		installed=1
	fi

	latest_output="$(get_xray_latest_info 2>/dev/null)"
	latest_rc=$?

	log_kv component xray
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv arch "$arch"
	log_kv asset "$asset"

	if [ $latest_rc -ne 0 ]; then
		log_kv can_upgrade 0
		case "$latest_rc" in
			2) log_kv error 'unsupported_arch' ;;
			3) log_kv error 'fetch_failed' ;;
			4) log_kv error 'asset_not_found' ;;
			*) log_kv error 'unknown_error' ;;
		 esac
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	arch="$(printf '%s\n' "$latest_output" | sed -n 's/^arch=//p' | sed -n '1p')"
	asset="$(printf '%s\n' "$latest_output" | sed -n 's/^asset=//p' | sed -n '1p')"
	can_upgrade=0
	if [ -z "$current" ] || version_gt "$latest_version" "$current"; then
		can_upgrade=1
	fi

	printf '%s\n' "$latest_output" | sed '/^download_url=/d'
	log_kv can_upgrade "$can_upgrade"
	log_kv error ''
}

mihomo_info() {
	local current installed latest_output latest_rc latest_version arch asset can_upgrade

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	if current="$(get_mihomo_current_version)" && [ -n "$current" ]; then
		installed=1
		asset="$(map_mihomo_asset "$arch" "$current" 2>/dev/null || true)"
	else
		asset=""
	fi

	latest_output="$(get_mihomo_latest_info 2>/dev/null)"
	latest_rc=$?

	log_kv component mihomo
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv arch "$arch"
	log_kv asset "$asset"

	if [ $latest_rc -ne 0 ]; then
		log_kv can_upgrade 0
		case "$latest_rc" in
			2) log_kv error 'unsupported_arch' ;;
			3) log_kv error 'fetch_failed' ;;
			4) log_kv error 'asset_not_found' ;;
			*) log_kv error 'unknown_error' ;;
		 esac
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	arch="$(printf '%s\n' "$latest_output" | sed -n 's/^arch=//p' | sed -n '1p')"
	asset="$(printf '%s\n' "$latest_output" | sed -n 's/^asset=//p' | sed -n '1p')"
	can_upgrade=0
	if [ -z "$current" ] || version_gt "$latest_version" "$current"; then
		can_upgrade=1
	fi

	printf '%s\n' "$latest_output" | sed '/^download_url=/d'
	log_kv can_upgrade "$can_upgrade"
	log_kv error ''
}

naiveproxy_info() {
	local current installed latest_output latest_rc latest_version arch asset can_upgrade

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	if current="$(get_naiveproxy_current_version)" && [ -n "$current" ]; then
		installed=1
	fi

	latest_output="$(get_naiveproxy_latest_info 2>/dev/null)"
	latest_rc=$?

	log_kv component naiveproxy
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv arch "$arch"
	log_kv asset ''

	if [ $latest_rc -ne 0 ]; then
		log_kv can_upgrade 0
		case "$latest_rc" in
			3) log_kv error 'fetch_failed' ;;
			4) log_kv error 'asset_not_found' ;;
			*) log_kv error 'unknown_error' ;;
		esac
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	arch="$(printf '%s\n' "$latest_output" | sed -n 's/^arch=//p' | sed -n '1p')"
	asset="$(printf '%s\n' "$latest_output" | sed -n 's/^asset=//p' | sed -n '1p')"
	can_upgrade=0
	if [ -z "$current" ]; then
		can_upgrade=1
	elif ! naiveproxy_versions_equal "$latest_version" "$current" && version_gt "$latest_version" "$current"; then
		can_upgrade=1
	fi

	printf '%s\n' "$latest_output" | sed '/^download_url=/d'
	log_kv can_upgrade "$can_upgrade"
	log_kv error ''
}

xray_local_info() {
	local current installed arch asset

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	asset="$(map_xray_asset "$arch" 2>/dev/null || true)"
	if current="$(get_xray_current_version)" && [ -n "$current" ]; then
		installed=1
	fi

	log_kv component xray
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv latest_version ''
	log_kv arch "$arch"
	log_kv asset "$asset"
	log_kv can_upgrade 0
	log_kv error ''
}

mihomo_local_info() {
	local current installed arch asset

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	if current="$(get_mihomo_current_version)" && [ -n "$current" ]; then
		installed=1
		asset="$(map_mihomo_asset "$arch" "$current" 2>/dev/null || true)"
	else
		asset=""
	fi

	log_kv component mihomo
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv latest_version ''
	log_kv arch "$arch"
	log_kv asset "$asset"
	log_kv can_upgrade 0
	log_kv error ''
}

naiveproxy_local_info() {
	local current installed arch

	installed=0
	current=""
	arch="$(get_openwrt_arch)"
	if current="$(get_naiveproxy_current_version)" && [ -n "$current" ]; then
		installed=1
	fi

	log_kv component naiveproxy
	log_kv installed "$installed"
	log_kv current_version "$current"
	log_kv latest_version ''
	log_kv arch "$arch"
	log_kv asset ''
	log_kv can_upgrade 0
	log_kv error ''
}

xray_upgrade() {
	local latest_output latest_rc latest_version download_url tmp_dir zip_file unzip_cmd backup_file current_before current_after

	latest_output="$(get_xray_latest_info 2>/dev/null)"
	latest_rc=$?
	if [ $latest_rc -ne 0 ]; then
		log_kv success 0
		case "$latest_rc" in
			2) log_kv message 'Unsupported ARCH' ;;
			3) log_kv message 'Failed to fetch release metadata' ;;
			4) log_kv message 'Matching release asset not found' ;;
			*) log_kv message 'Unknown error' ;;
		 esac
		return 0
	fi

	if ! unzip_cmd="$(select_unzip_cmd)"; then
		log_kv success 0
		log_kv message 'Missing unzip support'
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	download_url="$(printf '%s\n' "$latest_output" | sed -n 's/^download_url=//p' | sed -n '1p')"
	current_before="$(get_xray_current_version 2>/dev/null || true)"
	if [ -n "$current_before" ] && ! version_gt "$latest_version" "$current_before"; then
		log_kv success 1
		log_kv previous_version "$current_before"
		log_kv current_version "$current_before"
		log_kv latest_version "$latest_version"
		log_kv message 'Already up to date'
		return 0
	fi

	tmp_dir="$(mktemp -d /tmp/ssrplus-xray.XXXXXX)"
	if [ -z "$tmp_dir" ] || [ ! -d "$tmp_dir" ]; then
		log_kv success 0
		log_kv message 'Failed to create temp directory'
		return 0
	fi

	zip_file="$tmp_dir/xray.zip"
	backup_file="$tmp_dir/xray.backup"

	trap "rm -rf '$tmp_dir'" EXIT INT TERM

	if ! download_file "$download_url" "$zip_file"; then
		log_kv success 0
		log_kv message 'Download failed'
		return 0
	fi

	if ! sh -c "$unzip_cmd \"$zip_file\" -d \"$tmp_dir\" >/dev/null 2>&1"; then
		log_kv success 0
		log_kv message 'Extract failed'
		return 0
	fi

	if [ ! -f "$tmp_dir/xray" ]; then
		log_kv success 0
		log_kv message 'xray binary not found in archive'
		return 0
	fi

	chmod 0755 "$tmp_dir/xray" || true
	if [ -x "$XRAY_BINARY" ]; then
		cp -fp "$XRAY_BINARY" "$backup_file" 2>/dev/null || true
	fi

	if ! cp -f "$tmp_dir/xray" "$XRAY_BINARY"; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$XRAY_BINARY" 2>/dev/null || true
		fi
		log_kv success 0
		log_kv message 'Install failed'
		return 0
	fi

	chmod 0755 "$XRAY_BINARY" || true
	current_after="$(get_xray_current_version 2>/dev/null || true)"
	if [ -z "$current_after" ]; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$XRAY_BINARY" 2>/dev/null || true
			chmod 0755 "$XRAY_BINARY" || true
		fi
		log_kv success 0
		log_kv message 'Installed binary failed to run'
		return 0
	fi

	if [ -x /etc/init.d/shadowsocksr ]; then
		/etc/init.d/shadowsocksr restart >/dev/null 2>&1 || true
	fi

	log_kv success 1
	log_kv previous_version "$current_before"
	log_kv current_version "$current_after"
	log_kv latest_version "$latest_version"
	log_kv message 'Upgrade completed'
	return 0
}

mihomo_upgrade() {
	local latest_output latest_rc latest_version download_url tmp_dir gz_file gzip_cmd backup_file current_before current_after target_binary extracted_binary

	latest_output="$(get_mihomo_latest_info 2>/dev/null)"
	latest_rc=$?
	if [ $latest_rc -ne 0 ]; then
		log_kv success 0
		case "$latest_rc" in
			2) log_kv message 'Unsupported ARCH' ;;
			3) log_kv message 'Failed to fetch release metadata' ;;
			4) log_kv message 'Matching release asset not found' ;;
			*) log_kv message 'Unknown error' ;;
		 esac
		return 0
	fi

	if ! gzip_cmd="$(select_gzip_cmd)"; then
		log_kv success 0
		log_kv message 'Missing gzip support'
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	download_url="$(printf '%s\n' "$latest_output" | sed -n 's/^download_url=//p' | sed -n '1p')"
	current_before="$(get_mihomo_current_version 2>/dev/null || true)"
	if [ -n "$current_before" ] && ! version_gt "$latest_version" "$current_before"; then
		log_kv success 1
		log_kv previous_version "$current_before"
		log_kv current_version "$current_before"
		log_kv latest_version "$latest_version"
		log_kv message 'Already up to date'
		return 0
	fi

	target_binary="$(find_mihomo_binary 2>/dev/null || true)"
	[ -n "$target_binary" ] || target_binary="$MIHOMO_BINARY"

	tmp_dir="$(mktemp -d /tmp/ssrplus-mihomo.XXXXXX)"
	if [ -z "$tmp_dir" ] || [ ! -d "$tmp_dir" ]; then
		log_kv success 0
		log_kv message 'Failed to create temp directory'
		return 0
	fi

	gz_file="$tmp_dir/mihomo.gz"
	backup_file="$tmp_dir/mihomo.backup"
	extracted_binary="$tmp_dir/mihomo"

	trap "rm -rf '$tmp_dir'" EXIT INT TERM

	if ! download_file "$download_url" "$gz_file"; then
		log_kv success 0
		log_kv message 'Download failed'
		return 0
	fi

	if ! sh -c "$gzip_cmd \"$gz_file\" > \"$extracted_binary\""; then
		log_kv success 0
		log_kv message 'Extract failed'
		return 0
	fi

	if [ ! -s "$extracted_binary" ]; then
		log_kv success 0
		log_kv message 'mihomo binary not found in archive'
		return 0
	fi

	mkdir -p "$(dirname "$target_binary")" || true
	chmod 0755 "$extracted_binary" || true
	if [ -x "$target_binary" ]; then
		cp -fp "$target_binary" "$backup_file" 2>/dev/null || true
	fi

	if ! cp -f "$extracted_binary" "$target_binary"; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$target_binary" 2>/dev/null || true
		fi
		log_kv success 0
		log_kv message 'Install failed'
		return 0
	fi

	chmod 0755 "$target_binary" || true
	if [ "$target_binary" != "$MIHOMO_BINARY" ] && [ ! -x "$MIHOMO_BINARY" ]; then
		ln -sf "$target_binary" "$MIHOMO_BINARY" 2>/dev/null || true
	fi

	current_after="$(get_mihomo_current_version 2>/dev/null || true)"
	if [ -z "$current_after" ]; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$target_binary" 2>/dev/null || true
			chmod 0755 "$target_binary" || true
		fi
		log_kv success 0
		log_kv message 'Installed binary failed to run'
		return 0
	fi

	if [ -x /etc/init.d/shadowsocksr ]; then
		/etc/init.d/shadowsocksr restart >/dev/null 2>&1 || true
	fi

	log_kv success 1
	log_kv previous_version "$current_before"
	log_kv current_version "$current_after"
	log_kv latest_version "$latest_version"
	log_kv message 'Upgrade completed'
	return 0
}

naiveproxy_upgrade() {
	local latest_output latest_rc latest_version download_url tmp_dir archive_file xz_cmd tar_cmd backup_file current_before current_after target_binary extracted_binary

	latest_output="$(get_naiveproxy_latest_info 2>/dev/null)"
	latest_rc=$?
	if [ $latest_rc -ne 0 ]; then
		log_kv success 0
		case "$latest_rc" in
			3) log_kv message 'Failed to fetch release metadata' ;;
			4) log_kv message 'Matching release asset not found' ;;
			*) log_kv message 'Unknown error' ;;
		esac
		return 0
	fi

	if ! xz_cmd="$(select_xz_cmd)"; then
		log_kv success 0
		log_kv message 'Missing xz support'
		return 0
	fi

	if ! tar_cmd="$(select_tar_cmd)"; then
		log_kv success 0
		log_kv message 'Extract failed'
		return 0
	fi

	latest_version="$(printf '%s\n' "$latest_output" | sed -n 's/^latest_version=//p' | sed -n '1p')"
	download_url="$(printf '%s\n' "$latest_output" | sed -n 's/^download_url=//p' | sed -n '1p')"
	current_before="$(get_naiveproxy_current_version 2>/dev/null || true)"
	if [ -n "$current_before" ] && ! version_gt "$latest_version" "$current_before"; then
		log_kv success 1
		log_kv previous_version "$current_before"
		log_kv current_version "$current_before"
		log_kv latest_version "$latest_version"
		log_kv message 'Already up to date'
		return 0
	fi

	target_binary="$(find_naiveproxy_binary 2>/dev/null || true)"
	[ -n "$target_binary" ] || target_binary="$NAIVEPROXY_BINARY"

	tmp_dir="$(mktemp -d /tmp/ssrplus-naiveproxy.XXXXXX)"
	if [ -z "$tmp_dir" ] || [ ! -d "$tmp_dir" ]; then
		log_kv success 0
		log_kv message 'Failed to create temp directory'
		return 0
	fi

	archive_file="$tmp_dir/naiveproxy.tar.xz"
	backup_file="$tmp_dir/naive.backup"
	extracted_binary=""

	trap "rm -rf '$tmp_dir'" EXIT INT TERM

	if ! download_file "$download_url" "$archive_file"; then
		log_kv success 0
		log_kv message 'Download failed'
		return 0
	fi

	mkdir -p "$tmp_dir/extract" || {
		log_kv success 0
		log_kv message 'Failed to create temp directory'
		return 0
	}

	if ! sh -c "cd \"$tmp_dir/extract\" && $xz_cmd \"$archive_file\" | $tar_cmd -xf - >/dev/null 2>&1"; then
		log_kv success 0
		log_kv message 'Extract failed'
		return 0
	fi

	extracted_binary="$(find "$tmp_dir/extract" -type f -name naive | sed -n '1p')"
	if [ -z "$extracted_binary" ] || [ ! -s "$extracted_binary" ]; then
		log_kv success 0
		log_kv message 'naive binary not found in archive'
		return 0
	fi

	mkdir -p "$(dirname "$target_binary")" || true
	chmod 0755 "$extracted_binary" || true
	if [ -x "$target_binary" ]; then
		cp -fp "$target_binary" "$backup_file" 2>/dev/null || true
	fi

	if ! cp -f "$extracted_binary" "$target_binary"; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$target_binary" 2>/dev/null || true
		fi
		log_kv success 0
		log_kv message 'Install failed'
		return 0
	fi

	chmod 0755 "$target_binary" || true
	if [ "$target_binary" != "$NAIVEPROXY_BINARY" ] && [ ! -x "$NAIVEPROXY_BINARY" ]; then
		ln -sf "$target_binary" "$NAIVEPROXY_BINARY" 2>/dev/null || true
	fi

	current_after="$(get_naiveproxy_current_version 2>/dev/null || true)"
	if [ -z "$current_after" ]; then
		if [ -f "$backup_file" ]; then
			cp -f "$backup_file" "$target_binary" 2>/dev/null || true
			chmod 0755 "$target_binary" || true
		fi
		log_kv success 0
		log_kv message 'Installed binary failed to run'
		return 0
	fi

	if [ -x /etc/init.d/shadowsocksr ]; then
		/etc/init.d/shadowsocksr restart >/dev/null 2>&1 || true
	fi

	log_kv success 1
	log_kv previous_version "$current_before"
	log_kv current_version "$current_after"
	log_kv latest_version "$latest_version"
	log_kv message 'Upgrade completed'
	return 0
}

case "${1:-}" in
	xray_info)
		xray_info
		;;
	xray_local_info)
		xray_local_info
		;;
	xray_upgrade)
		xray_upgrade
		;;
	mihomo_info)
		mihomo_info
		;;
	mihomo_local_info)
		mihomo_local_info
		;;
	mihomo_upgrade)
		mihomo_upgrade
		;;
	naiveproxy_info)
		naiveproxy_info
		;;
	naiveproxy_local_info)
		naiveproxy_local_info
		;;
	naiveproxy_upgrade)
		naiveproxy_upgrade
		;;
	country_mmdb_info)
		geo_local_info country_mmdb
		;;
	country_mmdb_local_info)
		geo_local_info country_mmdb
		;;
	country_mmdb_upgrade)
		geo_upgrade country_mmdb
		;;
	geosite_info)
		geo_local_info geosite
		;;
	geosite_local_info)
		geo_local_info geosite
		;;
	geosite_upgrade)
		geo_upgrade geosite
		;;
	v2ray_geo_info)
		geo_local_info v2ray_geo
		;;
	v2ray_geo_local_info)
		geo_local_info v2ray_geo
		;;
	v2ray_geo_upgrade)
		geo_upgrade v2ray_geo
		;;
	*)
		log_kv success 0
		log_kv message 'Usage: update_components.sh xray_info|xray_local_info|xray_upgrade|mihomo_info|mihomo_local_info|mihomo_upgrade|naiveproxy_info|naiveproxy_local_info|naiveproxy_upgrade|country_mmdb_info|country_mmdb_local_info|country_mmdb_upgrade|geosite_info|geosite_local_info|geosite_upgrade|v2ray_geo_info|v2ray_geo_local_info|v2ray_geo_upgrade'
		return 1 2>/dev/null || exit 1
		;;
esac
