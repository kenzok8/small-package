#!/bin/sh

SUB_DIR="${CLASHOO_SUB_DIR:-/usr/share/clashoo/config/sub}"
SINGBOX_DIR="${CLASHOO_SINGBOX_DIR:-/usr/share/clashoo/config/singbox}"
BACKUP_DIR="${CLASHOO_BACKUP_DIR:-/usr/share/clashbackup}"
TEMPLATE_DIR="${CLASHOO_TEMPLATE_DIR:-/usr/share/clashoo/config/custom}"
LIST_FILE="${CLASHOO_LIST_FILE:-$BACKUP_DIR/confit_list.conf}"
BIND_FILE="${CLASHOO_BIND_FILE:-$BACKUP_DIR/template_bindings.conf}"
STATUS_FILE="${CLASHOO_STATUS_FILE:-$BACKUP_DIR/subscription_update.status}"
LOCK_DIR="${CLASHOO_LOCK_DIR:-/tmp/clashoo_subscription_update.lock}"
UPDATE_LOG="${CLASHOO_UPDATE_LOG:-/tmp/clash_update.txt}"
SERVICE_CMD="${CLASHOO_SERVICE_CMD:-/etc/init.d/clashoo}"
TMP_DIR="${CLASHOO_TMP_DIR:-/tmp}"

# Subscriptions are fetched direct first (many airports are domestic / geo-fence
# foreign exit IPs). Only used as a last-resort fallback, see download_to.
. /usr/share/clashoo/update/proxy_lib.sh

updated=0
unchanged=0
failed=0
skipped=0
restart_needed=0
started_at="$(date +%s)"
message=""
record_status=0
[ "$1" = "--all" ] && record_status=1

log_update() {
	printf '  %s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$UPDATE_LOG"
}

write_status() {
	local tmp
	mkdir -p "$(dirname "$STATUS_FILE")" >/dev/null 2>&1
	tmp="${STATUS_FILE}.tmp.$$"
	cat >"$tmp" <<EOF
running=$1
last_run=$started_at
finished_at=$2
updated=$updated
unchanged=$unchanged
failed=$failed
skipped=$skipped
message=$message
EOF
	mv "$tmp" "$STATUS_FILE"
}

cleanup() {
	rm -rf "$LOCK_DIR" >/dev/null 2>&1
}

if ! mkdir "$LOCK_DIR" >/dev/null 2>&1; then
	exit 75
fi
trap cleanup EXIT INT TERM
[ "$record_status" = "1" ] && write_status 1 0

safe_name() {
	case "$1" in
		''|*/*|*..*) return 1 ;;
	esac
	return 0
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
				ip !~ /^127\./ && ip !~ /^0\./ && ip !~ /^198\.18\./ &&
				ip != "8.8.8.8" && ip != "1.1.1.1" &&
				ip != "223.5.5.5" && ip != "119.29.29.29") {
				print ip
				exit
			}
		}'
}

curl_download() {
	local url out hdr ua host ip
	url="$1"
	out="$2"
	hdr="$3"
	ua="$4"
	host="$5"
	ip="$6"
	if [ -n "$host" ] && [ -n "$ip" ]; then
		curl -sSL --connect-timeout 15 --max-time 60 --speed-time 30 \
			--speed-limit 1 --retry 2 -A "$ua" -D "$hdr" -o "$out" \
			--resolve "$host:443:$ip" --resolve "$host:80:$ip" \
			-w '%{http_code}' "$url" 2>/dev/null
	else
		curl -sSL --connect-timeout 15 --max-time 60 --speed-time 30 \
			--speed-limit 1 --retry 2 -A "$ua" -D "$hdr" -o "$out" \
			-w '%{http_code}' "$url" 2>/dev/null
	fi
}

download_to() {
	local url out hdr ua code rc host dns ip
	url="$1"
	out="$2"
	hdr="$3"
	ua="$(uci -q get clashoo.config.sub_ua 2>/dev/null)"
	[ -n "$ua" ] || ua="clash.meta"

	rm -f "$out" "$hdr" >/dev/null 2>&1
	if command -v curl >/dev/null 2>&1; then
		code="$(curl_download "$url" "$out" "$hdr" "$ua" "" "")"
		rc=$?
		if [ "$rc" -eq 0 ] && [ "$code" = "200" ]; then
			return 0
		fi
		host="$(extract_host "$url")"
		for dns in 223.5.5.5 119.29.29.29 1.1.1.1 8.8.8.8; do
			ip="$(resolve_via "$host" "$dns")"
			[ -n "$ip" ] || continue
			log_update "DNS 回退：${host} -> ${ip} (@${dns})"
			code="$(curl_download "$url" "$out" "$hdr" "$ua" "$host" "$ip")"
			rc=$?
			[ "$rc" -eq 0 ] && [ "$code" = "200" ] && return 0
		done
		# Last resort: direct + DNS-override both failed, so the source may be
		# GFW-blocked (e.g. a github-hosted sub). In kernel-only mode try once
		# through the running core — nothing left to lose, and it won't disturb
		# any airport that already answered direct.
		proxy="$(clashoo_detect_proxy)"
		if [ -n "$proxy" ]; then
			log_update "代理兜底：通过本地核心重试订阅"
			code="$(curl -sSL --connect-timeout 15 --max-time 60 --speed-time 30 \
				--speed-limit 1 --retry 1 -A "$ua" -D "$hdr" -o "$out" \
				--proxy "$proxy" -w '%{http_code}' "$url" 2>/dev/null)"
			[ "$?" -eq 0 ] && [ "$code" = "200" ] && return 0
		fi
		return 1
	fi
	wget -q --tries=4 --timeout=20 --user-agent="$ua" "$url" -O "$out"
}

update_info() {
	local hdr target info
	hdr="$1"
	target="$2"
	info="$(grep -i 'subscription-userinfo:' "$hdr" 2>/dev/null | head -1 | \
		sed 's/^[Ss]ubscription-[Uu]serinfo:[[:space:]]*//' | tr -d '\r')"
	if [ -n "$info" ]; then
		printf '%s\n' "$info" >"${target}.info"
	else
		rm -f "${target}.info" >/dev/null 2>&1
	fi
}

service_running() {
	[ -n "${CLASHOO_SERVICE_CMD:-}" ] && return 0
	"$SERVICE_CMD" status >/dev/null 2>&1
}

template_output_name() {
	local sub tpl
	sub="$(printf '%s' "$1" | sed -e 's/\.[Yy][Aa][Mm][Ll]$//' -e 's/\.[Yy][Mm][Ll]$//' -e 's/[^A-Za-z0-9._-]/-/g')"
	tpl="$(printf '%s' "$2" | sed -e 's/\.[Yy][Aa][Mm][Ll]$//' -e 's/\.[Yy][Mm][Ll]$//' -e 's/[^A-Za-z0-9._-]/-/g')"
	printf '_merged_%s__%s.yaml' "${sub:-sub}" "${tpl:-template}"
}

apply_template() {
	local name target template merged merged_path use_config
	name="$1"
	target="$2"
	[ -r "$BIND_FILE" ] || return 0
	[ -x /usr/share/clashoo/update/template_merge.sh ] || return 0
	template="$(awk -F '#' -v n="$name" '$1==n && ($3=="1" || $3=="true") {print $2; exit}' "$BIND_FILE")"
	[ -n "$template" ] && [ -r "$TEMPLATE_DIR/$template" ] || return 0
	merged="$(template_output_name "$name" "$template")"
	merged_path="$TEMPLATE_DIR/$merged"
	if sh /usr/share/clashoo/update/template_merge.sh "$target" "$TEMPLATE_DIR/$template" "$merged_path" >/dev/null 2>&1; then
		use_config="$(uci -q get clashoo.config.use_config 2>/dev/null)"
		if [ "$use_config" = "$target" ] || [ "$use_config" = "$merged_path" ]; then
			uci -q set clashoo.config.use_config="$merged_path"
			uci -q set clashoo.config.config_type='3'
			uci -q commit clashoo >/dev/null 2>&1
			restart_needed=1
		fi
	else
		log_update "模板生成失败：${name} <- ${template}"
	fi
}

update_mihomo() {
	local name url typ target tmp hdr use_config config_type
	name="$1"
	url="$2"
	typ="$3"
	safe_name "$name" || return 1
	case "$typ" in clash|meta) ;; *) skipped=$((skipped + 1)); return 0 ;; esac
	target="$SUB_DIR/$name"
	[ -f "$target" ] || { skipped=$((skipped + 1)); return 0; }
	tmp="$TMP_DIR/clashoo_sub_$$.yaml"
	hdr="$TMP_DIR/clashoo_sub_$$.hdr"
	if ! download_to "$url" "$tmp" "$hdr"; then
		failed=$((failed + 1))
		log_update "更新失败（下载失败）：$name"
		rm -f "$tmp" "$hdr"
		return 1
	fi
	if ! grep -Eq '^(proxies|proxy-providers):' "$tmp" 2>/dev/null; then
		failed=$((failed + 1))
		log_update "更新失败（无效 Mihomo 配置）：$name"
		rm -f "$tmp" "$hdr"
		return 1
	fi
	if cmp -s "$tmp" "$target"; then
		update_info "$hdr" "$target"
		unchanged=$((unchanged + 1))
		rm -f "$tmp" "$hdr"
		return 0
	fi
	if ! mv "$tmp" "$target"; then
		failed=$((failed + 1))
		rm -f "$hdr"
		return 1
	fi
	update_info "$hdr" "$target"
	rm -f "$hdr"
	updated=$((updated + 1))
	use_config="$(uci -q get clashoo.config.use_config 2>/dev/null)"
	config_type="$(uci -q get clashoo.config.config_type 2>/dev/null)"
	[ "$config_type" = "1" ] && [ "$use_config" = "$target" ] && restart_needed=1
	apply_template "$name" "$target"
	log_update "更新完成：$name"
}

valid_singbox() {
	ucode -e 'import { readfile } from "fs"; let c = json(readfile(ARGV[0])); exit(type(c) == "object" && type(c.outbounds) == "array" && length(c.outbounds) > 0 ? 0 : 1);' "$1" >/dev/null 2>&1
}

update_singbox() {
	local name target url tmp hdr active
	name="$1"
	safe_name "$name" || return 1
	target="$SINGBOX_DIR/$name"
	[ -f "$target" ] && [ -r "$target.url" ] || { skipped=$((skipped + 1)); return 0; }
	url="$(sed -n '1p' "$target.url")"
	[ -n "$url" ] || { skipped=$((skipped + 1)); return 0; }
	tmp="$TMP_DIR/clashoo_sb_$$.json"
	hdr="$TMP_DIR/clashoo_sb_$$.hdr"
	if ! download_to "$url" "$tmp" "$hdr" || ! valid_singbox "$tmp"; then
		failed=$((failed + 1))
		log_update "更新失败（无效 sing-box 配置）：$name"
		rm -f "$tmp" "$hdr"
		return 1
	fi
	if cmp -s "$tmp" "$target"; then
		update_info "$hdr" "$target"
		unchanged=$((unchanged + 1))
		rm -f "$tmp" "$hdr"
		return 0
	fi
	if ! mv "$tmp" "$target"; then
		failed=$((failed + 1))
		rm -f "$hdr"
		return 1
	fi
	update_info "$hdr" "$target"
	rm -f "$hdr"
	updated=$((updated + 1))
	active="$(uci -q get clashoo.config.singbox_active 2>/dev/null)"
	[ "$active" = "$name" ] && restart_needed=1
	log_update "更新完成：$name"
}

update_all() {
	local name url typ url_file
	if [ -r "$LIST_FILE" ]; then
		while IFS='#' read -r name url typ _rest; do
			[ -n "$name" ] && [ -n "$url" ] || continue
			update_mihomo "$name" "$url" "$typ" || true
		done <"$LIST_FILE"
	fi
	for url_file in "$SINGBOX_DIR"/*.url; do
		[ -f "$url_file" ] || continue
		name="$(basename "$url_file" .url)"
		update_singbox "$name" || true
	done
}

case "$1" in
	--all)
		update_all
		;;
	--mihomo)
		line="$(awk -F '#' -v n="$2" '$1==n {print; exit}' "$LIST_FILE" 2>/dev/null)"
		[ -n "$line" ] || { failed=1; message="subscription not found"; }
		if [ -n "$line" ]; then
			name="$(printf '%s' "$line" | awk -F '#' '{print $1}')"
			url="$(printf '%s' "$line" | awk -F '#' '{print $2}')"
			typ="$(printf '%s' "$line" | awk -F '#' '{print $3}')"
			update_mihomo "$name" "$url" "$typ" || true
		fi
		;;
	--singbox)
		update_singbox "$2" || true
		;;
	*)
		failed=1
		message="invalid arguments"
		;;
esac

if [ "$restart_needed" = "1" ] && service_running; then
	"$SERVICE_CMD" restart >/dev/null 2>&1
fi

finished_at="$(date +%s)"
[ -n "$message" ] || message="updated=$updated unchanged=$unchanged failed=$failed skipped=$skipped"
[ "$record_status" = "1" ] && write_status 0 "$finished_at"
[ "$failed" -eq 0 ]
