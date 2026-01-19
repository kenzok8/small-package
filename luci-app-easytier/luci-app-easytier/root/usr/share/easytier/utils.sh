#!/bin/sh
# EasyTier Utility Functions
# Common helper functions for EasyTier init scripts

# 获取时区设置
get_tz() {
	SET_TZ=""
	[ -e "/etc/localtime" ] && return
	for tzfile in /etc/TZ /var/etc/TZ; do
		[ -e "$tzfile" ] || continue
		tz="$(cat $tzfile 2>/dev/null)"
	done
	[ -z "$tz" ] && return
	SET_TZ=$tz
}

# 获取 CPU 架构
get_cpu_arch() {
	local cputype=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
	local cpucore=""
	
	[ -n "$(echo $cputype | grep -E 'linux.*armv.*')" ] && cpucore="arm"
	[ -n "$(echo $cputype | grep -E 'linux.*armv7.*')" ] && [ -n "$(cat /proc/cpuinfo | grep vfp)" ] && cpucore="armv7"
	[ -n "$(echo $cputype | grep -E 'linux.*aarch64.*|linux.*armv8.*')" ] && cpucore="aarch64"
	[ -n "$(echo $cputype | grep -E 'linux.*86.*')" ] && cpucore="i386"
	[ -n "$(echo $cputype | grep -E 'linux.*86_64.*')" ] && cpucore="x86_64"
	
	if [ -n "$(echo $cputype | grep -E 'linux.*mips.*')" ]; then
		local mipstype=$(echo -n I | hexdump -o 2>/dev/null | awk '{ print substr($2,6,1); exit}')
		[ "$mipstype" = "0" ] && cpucore="mips" || cpucore="mipsel"
	fi
	
	echo "$cpucore"
}

# 统一日志记录
log_message() {
	local level="$1"
	local component="$2"
	local message="$3"
	local logfile="${4:-/tmp/easytier.log}"
	
	echo "$(date '+%Y-%m-%d %H:%M:%S') ${component} : ${message}" >> "$logfile"
}

# 日志大小管理
manage_log_size() {
	local logfile="$1"
	local max_size_kb="${2:-5120}"
	local keep_lines="${3:-500}"
	
	while true; do
		local log_size=$(ls -l "$logfile" 2>/dev/null | awk '{print int($5/1024)}')
		if [ "${log_size:-0}" -gt "$max_size_kb" ]; then
			tail -n "$keep_lines" "$logfile" > "${logfile}.tmp"
			mv "${logfile}.tmp" "$logfile"
		fi
		sleep 300
	done
}

# 获取可用磁盘空间 (KB)
get_available_space() {
	local path="$1"
	local size=$(df -k | awk '/\/overlay$/ {sub(/K$/, "", $4); print $4}')
	[ -z "$size" ] && size=$(df -kP "$path" 2>/dev/null | awk 'NR==2 {print $(NF-2)}')
	echo "${size:-0}"
}

# 安全执行命令并返回结果
safe_exec() {
	local cmd="$1"
	local result=$(eval "$cmd" 2>/dev/null)
	echo "$result"
}

# 检查进程是否运行
is_process_running() {
	local process_name="$1"
	pgrep -f "$process_name" >/dev/null 2>&1
	return $?
}

# 停止进程
stop_process() {
	local process_name="$1"
	ps | grep "$process_name" | grep -v grep | awk '{print $1}' | xargs kill >/dev/null 2>&1
	ps | grep "$process_name" | grep -v grep | awk '{print $1}' | xargs kill -9 >/dev/null 2>&1
}
