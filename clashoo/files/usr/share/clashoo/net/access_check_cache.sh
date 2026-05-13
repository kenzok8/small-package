#!/bin/sh

set -eu

CACHE_DIR="/tmp/clashoo"
CACHE_FILE="/tmp/clashoo_check_cache"
LOCK_DIR="${CACHE_DIR}/access_check.lock"
UPDATING_FLAG="${CACHE_DIR}/access_check_updating"
TMP_FILE="${CACHE_FILE}.tmp.$$"

mkdir -p "$CACHE_DIR"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
	old_pid="$(cat "$UPDATING_FLAG" 2>/dev/null)"
	if [ -n "$old_pid" ] && [ ! -d "/proc/$old_pid" ]; then
		rm -rf "$LOCK_DIR" "$UPDATING_FLAG" >/dev/null 2>&1
		mkdir "$LOCK_DIR" 2>/dev/null || exit 0
	else
		exit 0
	fi
fi
trap 'rm -rf "$LOCK_DIR" "$UPDATING_FLAG" "$TMP_FILE"' EXIT INT TERM
printf '%s\n' "$$" > "$UPDATING_FLAG"

safe_int() {
	case "${1:-}" in
		''|*[!0-9]*)
			printf '0'
			;;
		*)
			printf '%s' "$1"
			;;
	esac
}

safe_code() {
	case "${1:-}" in
		''|*[!0-9A-Za-z]*)
			printf '000'
			;;
		*)
			printf '%s' "$1"
			;;
	esac
}

parse_field() {
	_line="$1"
	_key="$2"
	printf '%s\n' "$_line" | sed -n "s/.*${_key}=\\([^ ]*\\).*/\\1/p"
}

probe_json() {
	_line="$1"
	_ok="$(safe_int "$(parse_field "$_line" "ok")")"
	_attempts="$(safe_int "$(parse_field "$_line" "attempts")")"
	_loss="$(safe_int "$(parse_field "$_line" "loss")")"
	_avg_ms="$(safe_int "$(parse_field "$_line" "avg_ms")")"
	_code="$(safe_code "$(parse_field "$_line" "code")")"

	_state="down"
	if [ "$_ok" -ge "$_attempts" ] && [ "$_attempts" -gt 0 ]; then
		if [ "$_avg_ms" -ge 2500 ]; then
			_state="high_latency"
		else
			_state="ok"
		fi
	elif [ "$_ok" -gt 0 ]; then
		_state="loss"
	fi

	_ok_bool=false
	[ "$_ok" -gt 0 ] && _ok_bool=true

	printf '{"ok":%s,"state":"%s","code":"%s","ok_count":%s,"attempts":%s,"loss":%s,"avg_ms":%s}' \
		"$_ok_bool" "$_state" "$_code" "$_ok" "$_attempts" "$_loss" "$_avg_ms"
}

probe_run() {
	_url="$1"
	_mode="$2"
	# nice + ionice：探测 IO/CPU 都低优先级，避免抢占 LuCI dispatcher
	nice -n 19 /usr/share/clashoo/net/access_check.sh "$_url" "$_mode" 2>/dev/null || true
}

has_wan_route() {
	ip route get 1.1.1.1 >/dev/null 2>&1
}

proxy_port="$(uci -q get clashoo.config.mixed_port)"
[ -z "$proxy_port" ] && proxy_port="$(uci -q get clashoo.config.http_port)"
[ -z "$proxy_port" ] && proxy_port="7890"
tcp_mode="$(uci -q get clashoo.config.tcp_mode)"
[ -z "$tcp_mode" ] && tcp_mode="redirect"
udp_mode="$(uci -q get clashoo.config.udp_mode)"
[ -z "$udp_mode" ] && udp_mode="$tcp_mode"
updated_at="$(date +%s)"

proxy_listening() {
	# 检测 mixed-port 是否在 LISTEN（clashoo 未运行时立即标 proxy down，避免显示假绿）
	if command -v ss >/dev/null 2>&1; then
		ss -tln 2>/dev/null | awk -v p=":${proxy_port}" '$0 ~ "LISTEN" && index($4, p) {found=1; exit} END{exit !found}'
	elif command -v netstat >/dev/null 2>&1; then
		netstat -tln 2>/dev/null | awk -v p=":${proxy_port}" '$0 ~ "LISTEN" && index($4, p) {found=1; exit} END{exit !found}'
	else
		return 0
	fi
}

if has_wan_route; then
	# 并行探测，把 CPU 抢占窗口从串行 2s+ 压缩到最慢一路的耗时
	f_db="${TMP_FILE}.db"
	f_dy="${TMP_FILE}.dy"
	f_pb="${TMP_FILE}.pb"
	f_py="${TMP_FILE}.py"
	probe_run "http://www.qualcomm.cn/generate_204" "direct" >"$f_db" &
	probe_run "https://www.youtube.com/generate_204" "direct" >"$f_dy" &
	if proxy_listening; then
		probe_run "http://www.qualcomm.cn/generate_204" "proxy"  >"$f_pb" &
		probe_run "https://www.youtube.com/generate_204" "proxy"  >"$f_py" &
	else
		# 代理端口未监听（clashoo 已停止），跳过探测，直接标 down
		echo "ok=0 attempts=1 loss=1 avg_ms=0 code=000" >"$f_pb"
		echo "ok=0 attempts=1 loss=1 avg_ms=0 code=000" >"$f_py"
	fi
	wait
	direct_bytedance="$(cat "$f_db" 2>/dev/null)"
	direct_youtube="$(cat "$f_dy" 2>/dev/null)"
	proxy_bytedance="$(cat "$f_pb" 2>/dev/null)"
	proxy_youtube="$(cat "$f_py" 2>/dev/null)"
	rm -f "$f_db" "$f_dy" "$f_pb" "$f_py"
else
	direct_bytedance="ok=0 attempts=1 loss=1 avg_ms=0 code=000"
	direct_youtube="ok=0 attempts=1 loss=1 avg_ms=0 code=000"
	proxy_bytedance="ok=0 attempts=1 loss=1 avg_ms=0 code=000"
	proxy_youtube="ok=0 attempts=1 loss=1 avg_ms=0 code=000"
fi

cat >"$TMP_FILE" <<EOF
{
  "proxy_port": "${proxy_port}",
  "tcp_mode": "${tcp_mode}",
  "udp_mode": "${udp_mode}",
  "updated_at": ${updated_at},
  "stale": false,
  "updating": false,
  "direct": {
    "bytedance": $(probe_json "$direct_bytedance"),
    "youtube": $(probe_json "$direct_youtube")
  },
  "proxy": {
    "bytedance": $(probe_json "$proxy_bytedance"),
    "youtube": $(probe_json "$proxy_youtube")
  }
}
EOF

mv -f "$TMP_FILE" "$CACHE_FILE"
exit 0
