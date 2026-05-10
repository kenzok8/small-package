#!/bin/sh

LOG_FILE="/tmp/clash_update.txt"
MODELTYPE=$(uci get clashoo.config.download_core 2>/dev/null)
CORETYPE=$(uci get clashoo.config.dcore 2>/dev/null)
MIRROR_PREFIX=$(uci get clashoo.config.core_mirror_prefix 2>/dev/null)
CUSTOM_CORE_URL=$(uci get clashoo.config.core_download_url 2>/dev/null)
CORE_INSTALLED=0
CONNECT_TIMEOUT=15
REQUEST_TIMEOUT=30
DOWNLOAD_TIMEOUT=150
ATTEMPTS_PER_MIRROR=1
MAX_TOTAL_SECONDS=300
TAG_FETCH_RETRIES=2
START_TS=$(date +%s)

write_log() {
	echo "  $(date "+%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

finalize() {
	if [ "$CORE_INSTALLED" = "1" ]; then
		# Smart 内核下载后自动切换
		if [ "$CORETYPE" = "1" ]; then
			uci set clashoo.config.core_type="mihomo" 2>/dev/null
			uci set clashoo.config.smart_auto_switch="1" 2>/dev/null
			uci commit clashoo 2>/dev/null
			write_log "Smart 内核已就绪，自动启用 Smart 策略"
		fi
		write_log "内核已替换，重启 Clashoo"
		if ! /etc/init.d/clashoo restart >/dev/null 2>&1; then
			write_log "重启 Clashoo 失败"
		fi
	fi
	rm -f /var/run/core_update >/dev/null 2>&1
}

timed_out() {
	now_ts=$(date +%s)
	[ $((now_ts - START_TS)) -ge "$MAX_TOTAL_SECONDS" ]
}

ensure_not_timed_out() {
	if timed_out; then
		write_log "下载超时（超过 ${MAX_TOTAL_SECONDS} 秒）"
		return 1
	fi
	return 0
}

normalize_prefix() {
	p="$1"
	[ -z "$p" ] && return
	case "$p" in
		*/) printf '%s\n' "$p" ;;
		*) printf '%s/\n' "$p" ;;
	esac
}

mirror_prefixes() {
	# 默认源按 2026-04 实测排序：mirror.ghproxy.com 已挂、hub.gitmirror.com/git.886.be 全死、
	# gh.idayer.com/ghproxy.net 限速截断；只保留 gh-proxy.com + ghfast.top 两条快通道。
	# 末尾会自动追加裸 GitHub（download_with_mirrors 末尾会 push 一个空 prefix）。
	custom="$(normalize_prefix "$MIRROR_PREFIX")"
	if [ -n "$custom" ]; then
		echo "$custom https://gh-proxy.com/ https://ghfast.top/"
	else
		echo "https://gh-proxy.com/ https://ghfast.top/"
	fi
}

prefixed_url() {
	prefix="$1"
	base_url="$2"
	if [ -z "$prefix" ]; then
		echo "$base_url"
	else
		echo "${prefix}${base_url}"
	fi
}

fetch_url_try() {
	url="$1"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$REQUEST_TIMEOUT" -A "Clash/OpenWRT" "$url"
		return $?
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -qO- --timeout="$CONNECT_TIMEOUT" --no-check-certificate --user-agent="Clash/OpenWRT" "$url"
		return $?
	fi
	return 127
}

detect_proxy() {
	if pidof mihomo >/dev/null 2>&1 || pidof clash-meta >/dev/null 2>&1 || pidof sing-box >/dev/null 2>&1; then
		local p
		p="$(uci -q get clashoo.config.mixed_port 2>/dev/null)"
		[ -n "$p" ] && echo "http://127.0.0.1:$p"
	fi
}

download_file_try() {
	url="$1"
	out="$2"
	proxy="$3"
	if command -v curl >/dev/null 2>&1; then
		if [ -n "$proxy" ]; then
			curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$DOWNLOAD_TIMEOUT" --retry 0 -A "Clash/OpenWRT" --proxy "$proxy" "$url" -o "$out"
		else
			curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$DOWNLOAD_TIMEOUT" --retry 0 -A "Clash/OpenWRT" "$url" -o "$out"
		fi
		return $?
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -q --timeout="$REQUEST_TIMEOUT" --tries=1 --no-check-certificate --user-agent="Clash/OpenWRT" "$url" -O "$out"
		return $?
	fi
	return 127
}

head_url_try() {
	url="$1"
	if command -v curl >/dev/null 2>&1; then
		curl -fsSIL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$REQUEST_TIMEOUT" -A "Clash/OpenWRT" "$url" >/dev/null 2>&1
		return $?
	fi
	wget -q --spider --timeout="$CONNECT_TIMEOUT" --no-check-certificate --user-agent="Clash/OpenWRT" "$url"
}

map_mihomo_arch() {
	case "$1" in
		amd64|x86_64) echo "linux-amd64" ;;
		arm64|aarch64_cortex-a53|aarch64_generic) echo "linux-arm64" ;;
		armv7|arm_cortex-a7_neon-vfpv4) echo "linux-armv7" ;;
		armv6|arm_arm1176jzf-s_vfp) echo "linux-armv6" ;;
		armv5|arm_arm926ej-s) echo "linux-armv5" ;;
		386|i386_pentium4) echo "linux-386" ;;
		mipsle|mipsel_24kc) echo "linux-mipsle-softfloat" ;;
		mips|mips_24kc) echo "linux-mips-softfloat" ;;
		mips64le|mips64el_mips64r2) echo "linux-mips64le" ;;
		mips64|mips64_mips64r2) echo "linux-mips64" ;;
		riscv64) echo "linux-riscv64" ;;
		*) echo "linux-amd64" ;;
	esac
}

map_singbox_arch() {
	case "$1" in
		amd64)   echo "amd64" ;;
		arm64)   echo "arm64" ;;
		armv7)   echo "armv7" ;;
		armv6)   echo "armv6" ;;
		armv5)   echo "armv5" ;;
		386)     echo "386" ;;
		mips)    echo "mips" ;;
		mipsle)  echo "mipsle" ;;
		mips64)  echo "mips64" ;;
		mips64le) echo "mips64le" ;;
		*)       echo "amd64" ;;
	esac
}

map_openwrt_arch() {
	case "$1" in
		amd64|x86_64) echo "x86_64" ;;
		arm64)        echo "aarch64_generic" ;;
		armv7)        echo "arm_cortex-a7_neon-vfpv4" ;;
		armv6)        echo "arm_arm1176jzf-s_vfp" ;;
		armv5)        echo "arm_arm926ej-s" ;;
		386)          echo "i386_pentium4" ;;
		mipsle)       echo "mipsel_24kc" ;;
		mips)         echo "mips_24kc" ;;
		mips64le)     echo "mips64el_mips64r2" ;;
		mips64)       echo "mips64_mips64r2" ;;
		*)            echo "" ;;
	esac
}

append_unique_line() {
	list="$1"
	line="$2"
	[ -z "$line" ] && {
		printf '%s' "$list"
		return
	}
	case "
$list
" in
	*"
$line
"*)
		printf '%s' "$list"
		;;
	*)
		if [ -n "$list" ]; then
			printf '%s\n%s' "$list" "$line"
		else
			printf '%s' "$line"
		fi
		;;
	esac
}

pick_highest_stable_tag() {
	printf '%s\n' "$1" | sed '/^$/d;s/\r$//' | grep -E '^v[0-9]+([.][0-9]+){1,3}$' | sort -V | tail -n 1
}

pick_highest_prerelease_tag() {
	printf '%s\n' "$1" | sed '/^$/d;s/\r$//' | grep -E '^v[0-9]+([.][0-9]+){1,3}-[0-9A-Za-z.-]+$' | sort -V | tail -n 1
}

extract_release_tags_by_prerelease() {
	payload="$1"
	is_prerelease="$2"

	if command -v jsonfilter >/dev/null 2>&1; then
		printf '%s' "$payload" | jsonfilter -e "@[@.prerelease=${is_prerelease}].tag_name" 2>/dev/null
		return
	fi

	tags="$(printf '%s' "$payload" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
	flags="$(printf '%s' "$payload" | grep -o '"prerelease"[[:space:]]*:[[:space:]]*[a-z]*' | sed 's/.*:[[:space:]]*//')"
	[ -z "$tags" ] && return
	[ -z "$flags" ] && return

	tags_file="/tmp/clashoo-tags-$$"
	flags_file="/tmp/clashoo-pre-$$"
	printf '%s\n' "$tags" > "$tags_file"
	printf '%s\n' "$flags" > "$flags_file"
	awk -v want="$is_prerelease" 'NR==FNR { t[FNR]=$0; next } $0==want { print t[FNR] }' "$tags_file" "$flags_file"
	rm -f "$tags_file" "$flags_file" >/dev/null 2>&1
}

detect_openwrt_arch() {
	local arch
	if command -v opkg >/dev/null 2>&1; then
		arch="$(opkg print-architecture 2>/dev/null | awk '$1=="arch" && $2!="all" && $2!="noarch" {a=$2} END{print a}')"
		[ -n "$arch" ] && { echo "$arch"; return 0; }
	fi
	map_openwrt_arch "$MODELTYPE"
}

install_singbox_openwrt_asset() {
	local pkg work rootdir
	pkg="$1"
	work="/tmp/singbox-openwrt-pkg"
	rootdir="/tmp/singbox-openwrt-root"

	rm -rf "$work" "$rootdir" 2>/dev/null
	mkdir -p "$work" "$rootdir"

	tar -xzf "$pkg" -C "$work" >/dev/null 2>&1 || return 1
	[ -f "$work/data.tar.gz" ] || return 1
	tar -xzf "$work/data.tar.gz" -C "$rootdir" >/dev/null 2>&1 || return 1
	[ -f "$rootdir/usr/bin/sing-box" ] || return 1

	if ! install_with_rollback "$rootdir/usr/bin/sing-box" "/usr/bin/sing-box"; then
		return 1
	fi

	if [ -f "$rootdir/etc/init.d/sing-box" ]; then
		cp -f "$rootdir/etc/init.d/sing-box" /etc/init.d/sing-box >/dev/null 2>&1 || true
		chmod 755 /etc/init.d/sing-box >/dev/null 2>&1 || true
	fi

	if [ -f "$rootdir/etc/config/sing-box" ] && [ ! -f /etc/config/sing-box ]; then
		cp -f "$rootdir/etc/config/sing-box" /etc/config/sing-box >/dev/null 2>&1 || true
	fi

	if [ -f "$rootdir/etc/sing-box/config.json" ] && [ ! -f /etc/sing-box/config.json ]; then
		mkdir -p /etc/sing-box >/dev/null 2>&1
		cp -f "$rootdir/etc/sing-box/config.json" /etc/sing-box/config.json >/dev/null 2>&1 || true
	fi

	rm -rf "$work" "$rootdir" >/dev/null 2>&1
	return 0
}

install_singbox_openwrt_apk_asset() {
	local pkg
	pkg="$1"
	command -v apk >/dev/null 2>&1 || return 1
	apk add --allow-untrusted --force-overwrite "$pkg" >/dev/null 2>&1 || return 1
	[ -x /usr/bin/sing-box ] || return 1
	return 0
}

install_singbox_tar_asset() {
	local archive bin
	archive="$1"
	rm -rf /tmp/singbox-extract >/dev/null 2>&1
	mkdir -p /tmp/singbox-extract
	tar -xzf "$archive" -C /tmp/singbox-extract >/dev/null 2>&1 || return 1
	bin="$(find /tmp/singbox-extract -name 'sing-box' -type f 2>/dev/null | head -n 1)"
	[ -n "$bin" ] || return 1
	install_with_rollback "$bin" "/usr/bin/sing-box"
}

fetch_latest_tag() {
	repo="$1"
	api_url="https://api.github.com/repos/${repo}/releases/latest"
	list_api="https://api.github.com/repos/${repo}/releases?per_page=100"
	web_url="https://github.com/${repo}/releases/latest"
	candidates=""

	# Fast path: prefer official GitHub API first to avoid stale mirror cache.
	p=""
	ensure_not_timed_out || return 1
	u="$(prefixed_url "$p" "$api_url")"
	i=1
	while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
		ensure_not_timed_out || return 1
		tag="$(fetch_url_try "$u" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
		case "$tag" in
			v*[-]*)
				:
				;;
			*)
				[ -n "$tag" ] && echo "$tag" && return 0
				;;
		esac
		sleep 1
		i=$((i + 1))
	done

	for p in $(mirror_prefixes); do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$api_url")"
		i=1
		while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
			ensure_not_timed_out || return 1
			tag="$(fetch_url_try "$u" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
			case "$tag" in
				v*[-]*)
					# stable channel should ignore prerelease-like tags from stale mirrors
					:
					;;
				*)
					candidates="$(append_unique_line "$candidates" "$tag")"
					;;
			esac
			sleep 1
			i=$((i + 1))
		done
	done

	p=""
	ensure_not_timed_out || return 1
	u="$(prefixed_url "$p" "$list_api")"
	i=1
	while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
		ensure_not_timed_out || return 1
		payload="$({ fetch_url_try "$u" || true; })"
		tags="$(extract_release_tags_by_prerelease "$payload" false)"
		best="$(pick_highest_stable_tag "$tags")"
		[ -n "$best" ] && echo "$best" && return 0
		sleep 1
		i=$((i + 1))
	done

	for p in $(mirror_prefixes); do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$list_api")"
		i=1
		while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
			ensure_not_timed_out || return 1
			payload="$({ fetch_url_try "$u" || true; })"
			tags="$(extract_release_tags_by_prerelease "$payload" false)"
			for tag in $tags; do
				candidates="$(append_unique_line "$candidates" "$tag")"
			done
			sleep 1
			i=$((i + 1))
		done
	done

	for p in $(mirror_prefixes); do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$web_url")"
		i=1
		while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
			ensure_not_timed_out || return 1
			if command -v curl >/dev/null 2>&1; then
				tag="$(curl -fsSIL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$REQUEST_TIMEOUT" -A "Clash/OpenWRT" "$u" 2>/dev/null | sed -n 's#^[Ll]ocation: .*/releases/tag/\([^[:space:]\r]*\).*#\1#p' | head -n 1)"
			else
				tag="$(wget -S --spider --timeout="$CONNECT_TIMEOUT" --no-check-certificate --user-agent="Clash/OpenWRT" "$u" 2>&1 | sed -n 's#^  Location: .*/releases/tag/\([^[:space:]]*\).*#\1#p' | head -n 1)"
			fi
			case "$tag" in
				v*[-]*)
					:
					;;
				*)
					candidates="$(append_unique_line "$candidates" "$tag")"
					;;
			esac
			sleep 1
			i=$((i + 1))
		done
	done

	releases_url="https://github.com/${repo}/releases"
	for p in $(mirror_prefixes); do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$releases_url")"
		tag="$(fetch_url_try "$u" | sed -n 's#.*releases/tag/\(v[0-9][^\"/?]*\).*#\1#p' | head -n 1)"
		case "$tag" in
			v*[-]*)
				:
				;;
			*)
				candidates="$(append_unique_line "$candidates" "$tag")"
				;;
		esac
	done

	best="$(pick_highest_stable_tag "$candidates")"
	[ -n "$best" ] && {
		echo "$best"
		return 0
	}
	fallback="$(printf '%s\n' "$candidates" | sed '/^$/d' | head -n 1)"
	[ -n "$fallback" ] && {
		echo "$fallback"
		return 0
	}

	return 1
}

fetch_prerelease_tag() {
	repo="$1"
	api_url="https://api.github.com/repos/${repo}/releases?per_page=100"
	candidates=""

	# Fast path: official GitHub API first.
	p=""
	ensure_not_timed_out || return 1
	u="$(prefixed_url "$p" "$api_url")"
	i=1
	while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
		ensure_not_timed_out || return 1
		payload="$({ fetch_url_try "$u" || true; })"
		tags="$(extract_release_tags_by_prerelease "$payload" true)"
		best="$(pick_highest_prerelease_tag "$tags")"
		[ -n "$best" ] && echo "$best" && return 0
		sleep 1
		i=$((i + 1))
	done

	for p in $(mirror_prefixes); do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$api_url")"
		i=1
		while [ "$i" -le "$TAG_FETCH_RETRIES" ]; do
			ensure_not_timed_out || return 1
			payload="$({ fetch_url_try "$u" || true; })"
			tags="$(extract_release_tags_by_prerelease "$payload" true)"
			for tag in $tags; do
				candidates="$(append_unique_line "$candidates" "$tag")"
			done
			sleep 1
			i=$((i + 1))
		done
	done

	best="$(pick_highest_prerelease_tag "$candidates")"
	[ -n "$best" ] && {
		echo "$best"
		return 0
	}
	fallback="$(printf '%s\n' "$candidates" | sed '/^$/d' | head -n 1)"
	[ -n "$fallback" ] && {
		echo "$fallback"
		return 0
	}

	return 1
}

fetch_expanded_asset_names() {
	repo="$1"
	tag="$2"
	url="https://github.com/${repo}/releases/expanded_assets/${tag}"

	for p in $(mirror_prefixes) ""; do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$url")"
		assets="$(fetch_url_try "$u" | sed -n "s#.*releases/download/${tag}/\\([^\\\"?]*\\)\\\".*#\\1#p")"
		[ -n "$assets" ] && printf '%s\n' "$assets" && return 0
	done

	return 1
}

pick_reachable_release_url() {
	base_url="$1"
	for p in $(mirror_prefixes) ""; do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$base_url")"
		if head_url_try "$u"; then
			echo "$u"
			return 0
		fi
	done
	return 1
}

pick_mihomo_asset_by_url() {
	repo="$1"
	tag="$2"
	arch="$3"
	channel="$4"
	ver="${tag#v}"
	candidates=""

	if [ "$channel" = "alpha" ] || [ "$channel" = "smart" ]; then
		if [ "$arch" = "linux-amd64" ]; then
			if [ "$channel" = "smart" ]; then
				candidates="mihomo-linux-amd64-alpha-smart-*.gz mihomo-linux-amd64-compatible-alpha-smart-*.gz"
			else
				candidates="mihomo-linux-amd64-alpha-*.gz mihomo-linux-amd64-compatible-alpha-*.gz"
			fi
		else
			[ "$channel" = "smart" ] && candidates="mihomo-${arch}-alpha-smart-*.gz" || candidates="mihomo-${arch}-alpha-*.gz"
		fi
		assets_html="$(fetch_expanded_asset_names "$repo" "$tag")"
		if [ -n "$assets_html" ]; then
			for a in $(printf '%s\n' "$assets_html"); do
				for pat in $candidates; do
					case "$a" in
					$pat)
						u="https://github.com/${repo}/releases/download/${tag}/${a}"
						if pick_reachable_release_url "$u" >/dev/null 2>&1; then
							echo "$a"
							return 0
						fi
						;;
					esac
				done
			done
		fi
		return 1
	fi

	if [ "$arch" = "linux-amd64" ]; then
		candidates="mihomo-linux-amd64-v${ver}.gz mihomo-linux-amd64-compatible-v${ver}.gz"
	else
		candidates="mihomo-${arch}-v${ver}.gz"
	fi

	for a in $candidates; do
		u="https://github.com/${repo}/releases/download/${tag}/${a}"
		if pick_reachable_release_url "$u" >/dev/null 2>&1; then
			echo "$a"
			return 0
		fi
	done

	return 1
}

download_with_mirrors() {
	base_url="$1"
	outfile="$2"
	verify_mode="${3:-gzip}"
	proxy="$(detect_proxy)"
	for p in $(mirror_prefixes) ""; do
		ensure_not_timed_out || return 1
		u="$(prefixed_url "$p" "$base_url")"
		i=1
		while [ "$i" -le "$ATTEMPTS_PER_MIRROR" ]; do
			ensure_not_timed_out || return 1
			write_log "Downloading from ${u} (try ${i})"
			rm -f "$outfile" 2>/dev/null
			if download_file_try "$u" "$outfile" "$proxy"; then
				case "$verify_mode" in
					raw)
						if [ -s "$outfile" ]; then
							return 0
						fi
						write_log "Downloaded file is empty from ${u}"
						;;
					*)
						if gzip -t "$outfile" >/dev/null 2>&1; then
							return 0
						fi
						write_log "Downloaded file is invalid gzip from ${u}"
						;;
				esac
			fi
			sleep 1
			i=$((i + 1))
		done
	done
	return 1
}

pick_mihomo_asset() {
	repo="$1"
	tag="$2"
	arch="$3"
	channel="$4"
	ver="${tag#v}"
	candidates=""
	release_assets="$(fetch_expanded_asset_names "$repo" "$tag")"
	[ -z "$release_assets" ] && pick_mihomo_asset_by_url "$repo" "$tag" "$arch" "$channel" && return 0
	[ -z "$release_assets" ] && return 1

	if [ "$channel" = "alpha" ] || [ "$channel" = "smart" ]; then
		if [ "$arch" = "linux-amd64" ]; then
			if [ "$channel" = "smart" ]; then
				asset="$(printf '%s\n' "$release_assets" | sed -n 's#^\(mihomo-linux-amd64-alpha-smart-[0-9a-fA-F]\{7,\}\.gz\)$#\1#p' | head -n 1)"
				[ -z "$asset" ] && asset="$(printf '%s\n' "$release_assets" | sed -n 's#^\(mihomo-linux-amd64-compatible-alpha-smart-[0-9a-fA-F]\{7,\}\.gz\)$#\1#p' | head -n 1)"
			else
				asset="$(printf '%s\n' "$release_assets" | sed -n 's#^\(mihomo-linux-amd64-alpha-[0-9a-fA-F]\{7,\}\.gz\)$#\1#p' | head -n 1)"
				[ -z "$asset" ] && asset="$(printf '%s\n' "$release_assets" | sed -n 's#^\(mihomo-linux-amd64-compatible-alpha-[0-9a-fA-F]\{7,\}\.gz\)$#\1#p' | head -n 1)"
			fi
		else
			if [ "$channel" = "smart" ]; then
				asset="$(printf '%s\n' "$release_assets" | sed -n "s#^\\(mihomo-${arch}-alpha-smart-[0-9a-fA-F]\\{7,\\}\\.gz\\)$#\\1#p" | head -n 1)"
			else
				asset="$(printf '%s\n' "$release_assets" | sed -n "s#^\\(mihomo-${arch}-alpha-[0-9a-fA-F]\\{7,\\}\\.gz\\)$#\\1#p" | head -n 1)"
			fi
		fi
		[ -n "$asset" ] && echo "$asset" && return 0
		pick_mihomo_asset_by_url "$repo" "$tag" "$arch" "$channel"
		return $?
	fi

	if [ "$arch" = "linux-amd64" ]; then
		candidates="mihomo-linux-amd64-v${ver}.gz mihomo-linux-amd64-compatible-v${ver}.gz"
	else
		candidates="mihomo-${arch}-v${ver}.gz"
	fi

	for a in $candidates; do
		if printf '%s\n' "$release_assets" | grep -qx "$a"; then
			echo "$a"
			return 0
		fi
	done

	pick_mihomo_asset_by_url "$repo" "$tag" "$arch" "$channel"
	return $?

}

install_binary() {
	src="$1"
	dst="$2"
	mkdir -p "$(dirname "$dst")"
	rm -f "$dst"
	mv "$src" "$dst"
	chmod 755 "$dst"
}

backup_binary() {
	dst="$1"
	bak="${dst}.bak"
	if [ -x "$dst" ]; then
		cp -f "$dst" "$bak" 2>/dev/null || true
	fi
}

restore_binary() {
	dst="$1"
	bak="${dst}.bak"
	if [ -f "$bak" ]; then
		cp -f "$bak" "$dst" 2>/dev/null || return 1
		chmod 755 "$dst" 2>/dev/null || true
		return 0
	fi
	return 1
}

verify_binary() {
	bin="$1"
	[ -x "$bin" ] || return 1
	"$bin" -v >/dev/null 2>&1 && return 0
	"$bin" version >/dev/null 2>&1 && return 0
	return 1
}

install_with_rollback() {
	tmpfile="$1"
	target="$2"

	chmod 755 "$tmpfile" 2>/dev/null
	if ! verify_binary "$tmpfile"; then
		write_log "新内核预热校验失败，保留当前内核"
		rm -f "$tmpfile" 2>/dev/null
		return 1
	fi

	backup_binary "$target"
	if ! install_binary "$tmpfile" "$target"; then
		write_log "内核替换失败，回滚旧版本"
		restore_binary "$target" >/dev/null 2>&1 || true
		return 1
	fi

	return 0
}

rm -f /tmp/clash.gz /tmp/clash /usr/share/clashoo/core_down_complete 2>/dev/null
touch /var/run/core_update 2>/dev/null
trap finalize EXIT
write_log "内核下载任务启动"
write_log "下载架构：${MODELTYPE:-未设置}"

if [ -n "$CUSTOM_CORE_URL" ]; then
	write_log "使用自定义内核下载链接"
	URL="$CUSTOM_CORE_URL"
	if [ "$CORETYPE" = "3" ]; then
		TARGET="/usr/bin/mihomo"
		VERSION_FILE="/usr/share/clashoo/mihomo_version"
	else
		TARGET="/usr/bin/clash-meta"
		VERSION_FILE="/usr/share/clashoo/clash_meta_version"
	fi
	TAG="custom"
	ASSET="custom"
	VERSION_VALUE="custom-url"

	if ! download_file_try "$URL" /tmp/clash.gz "$(detect_proxy)"; then
		write_log "自定义链接下载失败"
		exit 1
	fi

	if ! gunzip -f /tmp/clash.gz; then
		write_log "自定义内核解压失败"
		exit 1
	fi

	if ! install_with_rollback /tmp/clash "$TARGET"; then
		exit 1
	fi
	CORE_INSTALLED=1
	printf '%s\n' "${VERSION_VALUE}" > "$VERSION_FILE"
	touch /usr/share/clashoo/core_down_complete
	write_log "内核更新完成（自定义链接）"
	exit 0
fi

if [ "$CORETYPE" = "4" ] || [ "$CORETYPE" = "5" ]; then
	SINGBOX_ARCH="$(map_singbox_arch "$MODELTYPE")"
	OPENWRT_ARCH="$(detect_openwrt_arch)"
	if [ "$CORETYPE" = "4" ]; then
		write_log "已选择 sing-box 稳定版"
		write_log "正在获取 GitHub Release 信息..."
		TAG=$(fetch_latest_tag "SagerNet/sing-box")
		[ -z "$TAG" ] && write_log "获取 sing-box 稳定版版本号失败" && exit 1
	else
		write_log "已选择 sing-box 预发布版"
		write_log "正在获取 GitHub Release 信息..."
		TAG=$(fetch_prerelease_tag "SagerNet/sing-box")
		[ -z "$TAG" ] && TAG=$(fetch_latest_tag "SagerNet/sing-box")
		[ -z "$TAG" ] && write_log "获取 sing-box 预发布版版本号失败" && exit 1
	fi
	VER="${TAG#v}"
	installed=0

	if [ -n "$OPENWRT_ARCH" ]; then
		if command -v apk >/dev/null 2>&1; then
			ASSET="sing-box_${VER}_openwrt_${OPENWRT_ARCH}.apk"
			URL="https://github.com/SagerNet/sing-box/releases/download/${TAG}/${ASSET}"
			write_log "优先尝试 OpenWrt APK 包: ${ASSET}"
			if download_with_mirrors "$URL" /tmp/singbox-openwrt.apk raw && install_singbox_openwrt_apk_asset /tmp/singbox-openwrt.apk; then
				installed=1
			else
				write_log "OpenWrt APK 包安装失败，尝试 OpenWrt IPK 包"
			fi
		fi
		if [ "$installed" -ne 1 ]; then
			ASSET="sing-box_${VER}_openwrt_${OPENWRT_ARCH}.ipk"
			URL="https://github.com/SagerNet/sing-box/releases/download/${TAG}/${ASSET}"
			write_log "尝试 OpenWrt IPK 包: ${ASSET}"
			if download_with_mirrors "$URL" /tmp/singbox-openwrt.ipk raw && install_singbox_openwrt_asset /tmp/singbox-openwrt.ipk; then
				installed=1
			else
				write_log "OpenWrt IPK 包安装失败，尝试 tar 包兜底"
			fi
		fi
	fi

	if [ "$installed" -ne 1 ]; then
		for ASSET in "sing-box-${VER}-linux-${SINGBOX_ARCH}-musl.tar.gz" "sing-box-${VER}-linux-${SINGBOX_ARCH}.tar.gz"; do
			URL="https://github.com/SagerNet/sing-box/releases/download/${TAG}/${ASSET}"
			write_log "尝试下载 sing-box 归档包: ${ASSET}"
			if download_with_mirrors "$URL" /tmp/singbox.tar.gz gzip && install_singbox_tar_asset /tmp/singbox.tar.gz; then
				installed=1
				break
			fi
		done
	fi

	if [ "$installed" -ne 1 ]; then
		write_log "sing-box 下载或安装失败（可能是架构不匹配）"
		exit 1
	fi

	CORE_INSTALLED=1
	printf '%s\n' "$TAG" > "/usr/share/clashoo/singbox_version"
	rm -f /tmp/singbox.tar.gz /tmp/singbox-openwrt.ipk /tmp/singbox-openwrt.apk
	rm -rf /tmp/singbox-extract /tmp/singbox-openwrt-pkg /tmp/singbox-openwrt-root
	touch /usr/share/clashoo/core_down_complete
	write_log "sing-box 更新完成: $TAG"
	exit 0
fi

if [ "$CORETYPE" = "1" ]; then
	write_log "已选择内核通道：mihomo Smart 版（vernesong fork）"
	TAG="Prerelease-Alpha"
	write_log "正在获取 GitHub Release 信息..."
	ASSET=$(pick_mihomo_asset "vernesong/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "smart")
	if [ -z "$ASSET" ]; then
		ALT_TAG=$(fetch_prerelease_tag "vernesong/mihomo")
		[ -n "$ALT_TAG" ] && TAG="$ALT_TAG"
		ASSET=$(pick_mihomo_asset "vernesong/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "smart")
	fi
	URL="https://github.com/vernesong/mihomo/releases/download/${TAG}/${ASSET}"
	TARGET="/usr/bin/smart"
	VERSION_FILE="/usr/share/clashoo/mihomo_version"
	VERSION_VALUE="smart-$(printf '%s\n' "$ASSET" | sed -n 's#^mihomo-.*-alpha-smart-\([0-9a-fA-F]\{7,\}\)\.gz$#\1#p' | head -n 1)"
	[ "$VERSION_VALUE" = "smart-" ] && VERSION_VALUE="smart-${TAG}"
elif [ "$CORETYPE" = "2" ]; then
	write_log "已选择内核通道：稳定版"
	write_log "正在获取 GitHub Release 信息..."
	TAG=$(fetch_latest_tag "MetaCubeX/mihomo")
	[ -z "$TAG" ] && write_log "获取稳定版版本号失败" && exit 1
	ASSET=$(pick_mihomo_asset "MetaCubeX/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "stable")
	URL="https://github.com/MetaCubeX/mihomo/releases/download/${TAG}/${ASSET}"
	TARGET="/usr/bin/clash-meta"
	VERSION_FILE="/usr/share/clashoo/clash_meta_version"
 	VERSION_VALUE="$TAG"
else
	write_log "已选择内核通道：预发布版"
	TAG="Prerelease-Alpha"
	write_log "正在获取 GitHub Release 信息..."
	ASSET=$(pick_mihomo_asset "MetaCubeX/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "alpha")
	[ -z "$ASSET" ] && TAG=$(fetch_prerelease_tag "MetaCubeX/mihomo")
	[ -z "$TAG" ] && TAG=$(fetch_latest_tag "MetaCubeX/mihomo")
	[ -z "$TAG" ] && write_log "获取预发布版本号失败" && exit 1
	[ -z "$ASSET" ] && ASSET=$(pick_mihomo_asset "MetaCubeX/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "alpha")
	[ -z "$ASSET" ] && ASSET=$(pick_mihomo_asset "MetaCubeX/mihomo" "$TAG" "$(map_mihomo_arch "$MODELTYPE")" "stable")
	URL="https://github.com/MetaCubeX/mihomo/releases/download/${TAG}/${ASSET}"
	TARGET="/usr/bin/mihomo"
	VERSION_FILE="/usr/share/clashoo/mihomo_version"
	VERSION_VALUE="$(printf '%s\n' "$ASSET" | sed -n 's#^mihomo-.*-alpha-\([0-9a-fA-F]\{7,\}\)\.gz$#\1#p' | head -n 1)"
	[ -z "$VERSION_VALUE" ] && VERSION_VALUE="$TAG"
fi

if [ -z "$TAG" ]; then
	write_log "内核版本检查失败"
	exit 1
fi

if [ -z "$ASSET" ]; then
	write_log "未找到对应架构的内核文件（${MODELTYPE:-unknown} / ${TAG:-unknown}）"
	exit 1
fi
write_log "版本标签：$TAG"
write_log "匹配内核文件：$ASSET"

write_log "开始下载内核"
if ! download_with_mirrors "$URL" /tmp/clash.gz; then
	write_log "内核下载失败：所有镜像源均不可达（已尝试 gh-proxy.com / ghfast.top / 裸 GitHub）"
	write_log "可设置自定义镜像前缀：uci set clashoo.config.core_mirror_prefix='https://your.mirror/' && uci commit clashoo"
	exit 1
fi

if ! gunzip -f /tmp/clash.gz; then
	write_log "内核解压失败"
	exit 1
fi

if ! install_with_rollback /tmp/clash "$TARGET"; then
	exit 1
fi
CORE_INSTALLED=1
printf '%s\n' "${VERSION_VALUE:-$TAG}" > "$VERSION_FILE"
touch /usr/share/clashoo/core_down_complete
write_log "内核更新完成"
