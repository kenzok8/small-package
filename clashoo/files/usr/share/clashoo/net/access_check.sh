#!/bin/sh
# clashoo access check
# 用法: access_check.sh <url> [mode]
#   mode = direct | proxy（默认 proxy）
#     direct: 经 openwrt 主干直连，不走任何代理
#     proxy:  走 clashoo 本地代理端口，验证核心出站

url="$1"
mode="${2:-proxy}"
[ -n "$url" ] || exit 1

attempts=2
ok=0
sum_ms=0
last_code=000

url_host() {
	printf '%s' "$1" | sed -n 's#^[a-zA-Z][a-zA-Z0-9+.-]*://\([^/:?#]*\).*$#\1#p'
}

url_port() {
	_u="$1"
	_p="$(printf '%s' "$_u" | sed -n 's#^[a-zA-Z][a-zA-Z0-9+.-]*://[^/:?#]*:\([0-9][0-9]*\).*$#\1#p')"
	[ -n "$_p" ] && { printf '%s' "$_p"; return; }
	case "$_u" in
		https://*) printf '443' ;;
		http://*)  printf '80' ;;
		*)         printf '443' ;;
	esac
}

run_with_timeout() {
	_secs="$1"
	shift
	if command -v timeout >/dev/null 2>&1; then
		timeout "$_secs" "$@" 2>/dev/null
	else
		"$@" 2>/dev/null
	fi
}

resolve_real_ip() {
	_host="$1"
	[ -n "$_host" ] || return 0
	for _dns in 223.5.5.5 119.29.29.29 1.1.1.1; do
		_ip="$(run_with_timeout 1 nslookup "$_host" "$_dns" | awk '/^Address: /{print $2} /^Address [0-9]+: /{print $3}' | grep -E '^[0-9]+(\.[0-9]+){3}$' | tail -n1)"
		[ -n "$_ip" ] && { printf '%s' "$_ip"; return; }
	done
}

set -- -4 -L --max-time 8 --connect-timeout 4 --retry 1 -s -o /dev/null -w '%{http_code} %{time_total}'
if [ "$mode" = "direct" ]; then
	# 强制不走任何代理，避免误读 http_proxy 环境变量
	set -- "$@" --noproxy '*'
	# 尝试固定 WAN 出口并使用真实 DNS 结果，降低 Fake-IP/透明链干扰
	wan_dev="$(ip route get 223.5.5.5 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
	[ -n "$wan_dev" ] && set -- "$@" --interface "$wan_dev"
	host="$(url_host "$url")"
	port="$(url_port "$url")"
	real_ip="$(resolve_real_ip "$host")"
	[ -n "$host" ] && [ -n "$port" ] && [ -n "$real_ip" ] && set -- "$@" --resolve "${host}:${port}:${real_ip}"
else
	proxy_port="$(uci get clashoo.config.mixed_port 2>/dev/null)"
	[ -z "$proxy_port" ] && proxy_port="$(uci get clashoo.config.http_port 2>/dev/null)"
	[ -z "$proxy_port" ] && proxy_port=7890
	set -- "$@" -x "http://127.0.0.1:${proxy_port}"
fi
set -- "$@" "$url"

i=1
while [ "$i" -le "$attempts" ]; do
	out="$(curl "$@" 2>/dev/null || true)"
	code="$(printf '%s' "$out" | awk '{print $1}')"
	time_s="$(printf '%s' "$out" | awk '{print $2}')"
	[ -n "$code" ] || code=000
	[ -n "$time_s" ] || time_s=0
	ms="$(awk -v t="$time_s" 'BEGIN{printf "%d", t*1000}')"
	last_code="$code"
	if [ "$code" = "200" ] || [ "$code" = "204" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
		ok=$((ok + 1))
		sum_ms=$((sum_ms + ms))
	fi
	i=$((i + 1))
done

loss=$((attempts - ok))
avg_ms=0
if [ "$ok" -gt 0 ]; then
	avg_ms=$((sum_ms / ok))
fi

echo "ok=$ok attempts=$attempts loss=$loss avg_ms=$avg_ms code=$last_code"
