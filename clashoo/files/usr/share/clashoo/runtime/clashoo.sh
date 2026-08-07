#!/bin/sh

REAL_LOG="/usr/share/clashoo/clashoo_real.txt"
UPDATE_LOG="/tmp/clash_update.txt"
LIST_FILE="/usr/share/clashbackup/confit_list.conf"
SUB_DIR="/usr/share/clashoo/config/sub"
TMP_PREFIX="/tmp/clash_sub_$$"
DEFAULT_SUB_UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'

subtype="$(uci -q get clashoo.config.subcri 2>/dev/null)"
config_name_raw="$(uci -q get clashoo.config.config_name 2>/dev/null)"
lang="$(uci -q get luci.main.lang 2>/dev/null)"

log_text() {
	if [ "$lang" = "en" ]; then
		echo "$1" >"$REAL_LOG"
	else
		echo "$2" >"$REAL_LOG"
	fi
}

log_update() {
	printf '  %s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$UPDATE_LOG"
}

sanitize_name() {
	local name
	name="$1"
	name="$(printf '%s' "$name" | tr 'A-Z' 'a-z')"
	name="$(printf '%s' "$name" | sed -e 's/\.yaml$//' -e 's/\.yml$//')"
	name="$(printf '%s' "$name" | tr ' /' '--')"
	name="$(printf '%s' "$name" | sed -e 's/[^a-z0-9._-]/-/g' -e 's/--\+/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//')"
	printf '%s' "$name"
}

sanitize_custom_name() {
	local name
	name="$1"
	name="$(printf '%s' "$name" | sed -e 's/\.yaml$//' -e 's/\.yml$//')"
	name="$(printf '%s' "$name" | tr ' /' '--')"
	name="$(printf '%s' "$name" | sed -e 's/[\\]//g' -e 's/\.\.+/-/g' -e 's/--\+/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//')"
	printf '%s' "$name"
}

url_decode() {
	printf '%s' "$1" | sed 's/%/\\x/g' | xargs -0 printf '%b' 2>/dev/null || printf '%s' "$1"
}

url_to_name() {
	local url host qname decoded
	url="$1"

	qname="$(printf '%s' "$url" | sed -n 's/.*[?&]filename=\([^&#]*\).*/\1/p')"
	[ -n "$qname" ] || qname="$(printf '%s' "$url" | sed -n 's/.*[?&]name=\([^&#]*\).*/\1/p')"
	if [ -n "$qname" ]; then
		# URL decode then strip non-filename chars, keep CJK and alphanumeric
		decoded="$(url_decode "$qname")"
		decoded="$(printf '%s' "$decoded" | tr -d '\r\n' | sed -e 's/[[:space:]]/-/g' -e 's/[/\\:*?"<>|]//g' -e 's/\.yaml$//' -e 's/\.yml$//')"
		[ -n "$decoded" ] && printf '%s' "$decoded" && return
	fi
	qname="$(sanitize_name "$qname")"
	if [ -n "$qname" ]; then
		printf '%s' "$qname"
		return
	fi

	host="$(printf '%s' "$url" | sed -e 's#^[a-zA-Z0-9+.-]*://##' -e 's#/.*$##' -e 's/:.*$//' -e 's#\..*$##')"
	host="$(sanitize_name "$host")"
	[ -n "$host" ] || host="sub"
	printf '%s' "$host"
}

next_available_name() {
	local base try idx
	base="$1"
	base="$(printf '%s' "$base" | sed -e 's/\.yaml$//' -e 's/\.yml$//')"
	base="$(printf '%s' "$base" | tr ' /' '--')"
	base="$(printf '%s' "$base" | sed -e 's/[\\]//g' -e 's/\.\.+/-/g' -e 's/--\+/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//')"
	[ -n "$base" ] || base="sub"

	if [ ! -f "$SUB_DIR/${base}.yaml" ]; then
		printf '%s' "$base"
		return
	fi

	idx=2
	while :; do
		try="${base}-${idx}"
		if [ ! -f "$SUB_DIR/${try}.yaml" ]; then
			printf '%s' "$try"
			return
		fi
		idx=$((idx + 1))
	done
}

get_subscription_urls() {
	uci -q show clashoo.config 2>/dev/null | awk -F"'" '
		/^clashoo.config.subscribe_url=/ {
			if (NF >= 3) {
				for (i = 2; i <= NF; i += 2) {
					if (length($i) > 0) print $i
				}
			} else {
				sub(/^clashoo.config.subscribe_url=/, "", $0)
				if (length($0) > 0) print $0
			}
		}
	'
}

ensure_system_dns() {
	local test_host
	test_host="github.com"
	if nslookup "$test_host" 127.0.0.1 >/dev/null 2>&1 || nslookup "$test_host" >/dev/null 2>&1; then
		return 0
	fi

	uci delete dhcp.@dnsmasq[0].server >/dev/null 2>&1
	uci set dhcp.@dnsmasq[0].noresolv='0' >/dev/null 2>&1
	uci del_list dhcp.@dnsmasq[0].server='127.0.0.1#' >/dev/null 2>&1
	uci del_list dhcp.@dnsmasq[0].server='127.0.0.1#5300' >/dev/null 2>&1
	uci add_list dhcp.@dnsmasq[0].server='119.29.29.29' >/dev/null 2>&1
	uci add_list dhcp.@dnsmasq[0].server='223.5.5.5' >/dev/null 2>&1
	uci commit dhcp >/dev/null 2>&1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	sleep 2
}

extract_host() {
	printf '%s' "$1" | sed -e 's#^[a-zA-Z0-9+.-]*://##' -e 's#/.*$##' -e 's#:.*$##' -e 's#.*@##'
}

resolve_via() {
	local host dns
	host="$1"
	dns="$2"
	nslookup "$host" "$dns" 2>/dev/null | awk '
		/^Address/ {
			ip = $NF
			if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ &&
				ip !~ /^127\./ &&
				ip !~ /^0\./ &&
				ip !~ /^198\.18\./ &&
				ip != "8.8.8.8" && ip != "8.8.4.4" &&
				ip != "1.1.1.1" && ip != "1.0.0.1" &&
				ip != "223.5.5.5" && ip != "223.6.6.6" &&
				ip != "119.29.29.29" && ip != "114.114.114.114") {
				print ip
				exit
			}
		}'
}

curl_subscription() {
	local url tmp hdr err ua extra_resolve http_code rc
	url="$1"
	tmp="$2"
	hdr="$3"
	err="$4"
	ua="$5"
	extra_resolve="$6"

	rm -f "$tmp" "$hdr" "$err" >/dev/null 2>&1

	# shellcheck disable=SC2086
	http_code="$(curl -sSL --connect-timeout 15 --max-time 60 \
		--speed-time 30 --speed-limit 1 --retry 2 \
		-H "User-Agent: ${ua}" -D "$hdr" -o "$tmp" \
		$extra_resolve \
		-w '%{http_code}' "$url" 2>"$err")"
	rc=$?
	printf '%s\n' "$http_code"
	return "$rc"
}

download_subscription() {
	local url target tmp hdr err rc http_code info_line ua err_msg
	local host ip dns extra
	url="$1"
	target="$2"
	tmp="${TMP_PREFIX}.yaml"
	hdr="${TMP_PREFIX}.hdr"
	err="${TMP_PREFIX}.err"

	ua="$(uci -q get clashoo.config.sub_ua 2>/dev/null)"
	[ -n "$ua" ] || ua="$DEFAULT_SUB_UA"

	if command -v curl >/dev/null 2>&1; then
		http_code="$(curl_subscription "$url" "$tmp" "$hdr" "$err" "$ua" "")"
		rc=$?

		if [ "$rc" -ne 0 ] || [ "$http_code" = "000" ]; then
			host="$(extract_host "$url")"
			if [ -n "$host" ]; then
				for dns in 223.5.5.5 119.29.29.29 1.1.1.1 8.8.8.8; do
					ip="$(resolve_via "$host" "$dns")"
					[ -n "$ip" ] || continue
					log_update "DNS 回退：${host} -> ${ip} (@${dns})"
					extra="--resolve ${host}:443:${ip} --resolve ${host}:80:${ip}"
					http_code="$(curl_subscription "$url" "$tmp" "$hdr" "$err" "$ua" "$extra")"
					rc=$?
					[ "$rc" -eq 0 ] && [ "$http_code" = "200" ] && break
				done
			fi
		fi
	else
		wget -q --tries=4 --timeout=20 \
			--user-agent="$ua" "$url" -O "$tmp" 2>"$err"
		rc=$?
		http_code=""
	fi

	if [ "$rc" -ne 0 ]; then
		err_msg="$(grep -a 'curl:' "$err" 2>/dev/null | tail -1)"
		[ -z "$err_msg" ] && err_msg="$(tail -1 "$err" 2>/dev/null)"
		log_update "下载失败：$(basename "$target") rc=${rc} ${err_msg}"
		rm -f "$tmp" "$hdr" "$err" >/dev/null 2>&1
		return 1
	fi

	if [ -n "$http_code" ] && [ "$http_code" != "200" ]; then
		log_update "下载失败：$(basename "$target") HTTP ${http_code}"
		rm -f "$tmp" "$hdr" "$err" >/dev/null 2>&1
		return 1
	fi

	if ! grep -Eq '^(proxies|proxy-providers):' "$tmp" 2>/dev/null; then
		log_update "校验失败：$(basename "$target") 内容不含 proxies/proxy-providers"
		rm -f "$tmp" "$hdr" "$err" >/dev/null 2>&1
		return 1
	fi

	info_line="$(grep -i 'subscription-userinfo:' "$hdr" 2>/dev/null | head -1 | \
		sed 's/^[Ss]ubscription-[Uu]serinfo:[[:space:]]*//' | tr -d '\r')"
	[ -n "$info_line" ] && printf '%s\n' "$info_line" > "${target}.info" || \
		rm -f "${target}.info" >/dev/null 2>&1

	rm -f "$hdr" "$err" >/dev/null 2>&1
	mv "$tmp" "$target" >/dev/null 2>&1 || {
		rm -f "$tmp" >/dev/null 2>&1
		return 1
	}
	printf '%s\n' "$ua" >"${target}.ua"

	return 0
}

upsert_meta() {
	local filename url typ tmpf
	filename="$1"
	url="$2"
	typ="$3"
	tmpf="${TMP_PREFIX}.list"

	[ -f "$LIST_FILE" ] || touch "$LIST_FILE"
	awk -F '#' -v n="$filename" '$1 != n { print $0 }' "$LIST_FILE" >"$tmpf"
	printf '%s#%s#%s\n' "$filename" "$url" "$typ" >>"$tmpf"
	mv "$tmpf" "$LIST_FILE"
}

cleanup_tmp() {
	rm -f "${TMP_PREFIX}.yaml" "${TMP_PREFIX}.urls" "${TMP_PREFIX}.list" \
		"${TMP_PREFIX}.hdr" "${TMP_PREFIX}.err" >/dev/null 2>&1
}

trap cleanup_tmp EXIT INT TERM

[ "$subtype" = "clash" ] || [ "$subtype" = "meta" ] || subtype="clash"

mkdir -p "$SUB_DIR" /usr/share/clashbackup >/dev/null 2>&1
[ -f "$LIST_FILE" ] || touch "$LIST_FILE"

URLS_FILE="${TMP_PREFIX}.urls"
get_subscription_urls | sed '/^[[:space:]]*$/d' | awk '!seen[$0]++' >"$URLS_FILE"

url_count="$(wc -l <"$URLS_FILE" 2>/dev/null | tr -d ' ')"
if [ -z "$url_count" ] || [ "$url_count" -eq 0 ]; then
	log_update "未找到订阅链接"
	log_text "No subscription URL found" "未找到订阅链接"
	sleep 2
	log_text "Clash for OpenWRT" "Clash for OpenWRT"
	exit 1
fi

ensure_system_dns
log_update "开始下载订阅（共 ${url_count} 条）"
log_text "Downloading subscription..." "开始下载订阅..."

base_name="$(sanitize_custom_name "$config_name_raw")"
timestamp="$(date +%Y%m%d)"

success=0
failed=0
idx=0
first_file=""

while IFS= read -r url; do
	[ -n "$url" ] || continue
	idx=$((idx + 1))

	if [ -n "$base_name" ]; then
		if [ "$url_count" -gt 1 ]; then
			name_candidate="$(sanitize_name "${base_name}-${idx}")"
			file_base="$(next_available_name "$name_candidate")"
		else
			file_base="$base_name"
		fi
	else
		name_candidate="$(url_to_name "$url")-${timestamp}"
		if [ "$url_count" -gt 1 ]; then
			name_candidate="${name_candidate}-${idx}"
		fi
		file_base="$(next_available_name "$name_candidate")"
	fi

	target_file="$SUB_DIR/${file_base}.yaml"
	if download_subscription "$url" "$target_file"; then
		upsert_meta "${file_base}.yaml" "$url" "$subtype"
		log_update "订阅下载成功：${file_base}.yaml"
		[ -n "$first_file" ] || first_file="$target_file"
		success=$((success + 1))
	else
		log_update "订阅下载失败：${file_base}.yaml"
		failed=$((failed + 1))
	fi
done <"$URLS_FILE"

if [ "$success" -gt 0 ]; then
	use_config="$(uci -q get clashoo.config.use_config 2>/dev/null)"
	if [ -z "$use_config" ] || [ ! -f "$use_config" ]; then
		uci set clashoo.config.use_config="$first_file"
		uci set clashoo.config.config_type='1'
		uci commit clashoo
	fi
	log_text "Subscription download completed: ${success} success, ${failed} failed" "订阅下载完成：成功 ${success} 个，失败 ${failed} 个"
	log_update "订阅下载完成：成功 ${success} 个，失败 ${failed} 个"
	ret=0
else
	log_text "All subscription downloads failed" "订阅下载失败"
	log_update "订阅下载失败：全部链接失败"
	ret=1
fi

sleep 2
log_text "Clash for OpenWRT" "Clash for OpenWRT"
exit "$ret"
