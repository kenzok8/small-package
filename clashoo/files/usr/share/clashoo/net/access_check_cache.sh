#!/bin/sh

set -eu

CACHE_DIR="/tmp/clashoo"
CACHE_FILE="/tmp/clashoo_check_cache"
LOCK_DIR="${CACHE_DIR}/access_check.lock"
LOCK_PID_FILE="${LOCK_DIR}/pid"
UPDATING_FLAG="${CACHE_DIR}/access_check_updating"
TMP_FILE="${CACHE_FILE}.tmp.$$"
DIAG_LOG="/tmp/clashoo_access_check.log"

take_lock() {
	mkdir "$LOCK_DIR" 2>/dev/null || return 1
	printf '%s\n' "$$" > "$LOCK_PID_FILE" 2>/dev/null
	return 0
}

pid_is_cache_worker() {
	[ -r "/proc/$1/cmdline" ] || return 1
	tr '\0' ' ' <"/proc/$1/cmdline" 2>/dev/null | grep -q 'access_check_cache\.sh'
}

lock_is_dead() {
	_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null)"
	case "$_pid" in
		''|*[!0-9]*)
			[ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +3 2>/dev/null)" ]
			return $?
			;;
	esac
	[ ! -d "/proc/$_pid" ] && return 0
	! pid_is_cache_worker "$_pid"
}

mkdir -p "$CACHE_DIR"
if ! take_lock; then
	lock_is_dead || exit 0
	rm -rf "$LOCK_DIR" >/dev/null 2>&1
	take_lock || exit 0
fi
trap 'rm -rf "$LOCK_DIR" "$UPDATING_FLAG" "$TMP_FILE"' EXIT INT TERM
: > "$UPDATING_FLAG"

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

log_diag() {
	[ "$(uci -q get clashoo.config.access_check_debug)" = "1" ] || return 0
	_line="$(date '+%Y-%m-%d %H:%M:%S') $1"
	printf '%s\n' "$_line" >>"$DIAG_LOG" 2>/dev/null
	_n="$(wc -l <"$DIAG_LOG" 2>/dev/null || echo 0)"
	if [ "${_n:-0}" -gt 200 ]; then
		tail -n 100 "$DIAG_LOG" >"${DIAG_LOG}.tmp" 2>/dev/null && mv "${DIAG_LOG}.tmp" "$DIAG_LOG" 2>/dev/null
	fi
}

probe_run() {
	_url="$1"
	_mode="$2"
	# nice + ionice：探测 IO/CPU 都低优先级，避免抢占 LuCI dispatcher
	nice -n 19 /usr/share/clashoo/net/access_check.sh "$_url" "$_mode" 2>/dev/null || true
}

proxy_port="$(uci -q get clashoo.config.mixed_port)"
[ -z "$proxy_port" ] && proxy_port="$(uci -q get clashoo.config.http_port)"
[ -z "$proxy_port" ] && proxy_port="7890"
tcp_mode="$(uci -q get clashoo.config.tcp_mode)"
[ -z "$tcp_mode" ] && tcp_mode="redirect"
udp_mode="$(uci -q get clashoo.config.udp_mode)"
[ -z "$udp_mode" ] && udp_mode="$tcp_mode"

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

# 并行探测，把 CPU 抢占窗口从串行 2s+ 压缩到最慢一路的耗时
f_db="${TMP_FILE}.db"
f_dy="${TMP_FILE}.dy"
f_pb="${TMP_FILE}.pb"
f_py="${TMP_FILE}.py"
probe_run "https://www.douyin.com/generate_204" "direct" >"$f_db" &
probe_run "https://www.youtube.com/generate_204" "direct" >"$f_dy" &
if proxy_listening; then
	proxy_skipped=0
	probe_run "https://www.douyin.com/generate_204" "proxy"  >"$f_pb" &
	probe_run "https://www.youtube.com/generate_204" "proxy"  >"$f_py" &
else
	# 代理端口未监听（clashoo 已停止），跳过探测，直接标 down
	proxy_skipped=1
	echo "ok=0 attempts=1 loss=1 avg_ms=0 code=000" >"$f_pb"
	echo "ok=0 attempts=1 loss=1 avg_ms=0 code=000" >"$f_py"
fi
wait
direct_bytedance="$(cat "$f_db" 2>/dev/null)"
direct_youtube="$(cat "$f_dy" 2>/dev/null)"
proxy_bytedance="$(cat "$f_pb" 2>/dev/null)"
proxy_youtube="$(cat "$f_py" 2>/dev/null)"
rm -f "$f_db" "$f_dy" "$f_pb" "$f_py"

updated_at="$(date +%s)"

log_diag "port=${proxy_port} proxy_skipped=${proxy_skipped} direct_bd=[${direct_bytedance}] direct_yt=[${direct_youtube}] proxy_bd=[${proxy_bytedance}] proxy_yt=[${proxy_youtube}]"

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
