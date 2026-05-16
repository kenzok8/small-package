#!/bin/sh

REAL_LOG="/usr/share/clashoo/clashoo_real.txt"
panel="$1"
lang="$(uci -q get luci.main.lang 2>/dev/null)"
STATE_FILE="/tmp/clash_panel_download_state"
RUN_FILE="/var/run/panel_downloading"
DASHBOARD_LINK="/etc/clashoo/dashboard"

[ -n "$panel" ] || panel="$(uci -q get clashoo.config.dashboard_panel 2>/dev/null)"
[ -n "$panel" ] || panel="zashboard"

case "$panel" in
	metacubexd)
		URLS="https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"
		TARGET_DIR="/etc/clashoo/dashboard-metacubexd"
		;;
	yacd)
		URLS="https://github.com/MetaCubeX/Yacd-meta/archive/refs/heads/gh-pages.zip https://github.com/haishanh/yacd/archive/refs/heads/gh-pages.zip"
		TARGET_DIR="/etc/clashoo/dashboard-yacd"
		;;
	zashboard)
		URLS="https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
		TARGET_DIR="/etc/clashoo/dashboard-zashboard"
		;;
	razord)
		URLS="https://github.com/MetaCubeX/Razord-meta/archive/refs/heads/gh-pages.zip https://github.com/ayanamist/clash-dashboard/archive/refs/heads/gh-pages.zip"
		TARGET_DIR="/etc/clashoo/dashboard-razord"
		;;
	*)
		URLS="https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip"
		TARGET_DIR="/etc/clashoo/dashboard-zashboard"
		panel="zashboard"
		;;
esac

TMP_ROOT="/tmp/clash_panel_${panel}_$$"
ZIP_FILE="$TMP_ROOT/panel.zip"
UNPACK_DIR="$TMP_ROOT/unpack"

UPDATE_LOG="/tmp/clash_update.txt"

update_log() {
	[ -n "$1" ] || return 0
	printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$UPDATE_LOG"
}

log_msg() {
	if [ "$lang" = "zh_cn" ]; then
		echo "$2" >"$REAL_LOG"
		[ "$3" = "1" ] || update_log "$2"
	else
		echo "$1" >"$REAL_LOG"
		[ "$3" = "1" ] || update_log "$1"
	fi
}

set_state() {
	state="$1"
	msg="$2"
	echo "${state}:${panel}:${msg}" >"$STATE_FILE"
}

cleanup() {
	rm -rf "$TMP_ROOT" >/dev/null 2>&1
	rm -f "$RUN_FILE" >/dev/null 2>&1
}

download_zip() {
	for url in $URLS; do
		if wget -q --timeout=60 --no-check-certificate --user-agent="Clash/OpenWRT" "$url" -O "$ZIP_FILE"; then
			return 0
		fi
	done
	return 1
}

extract_zip() {
	if command -v unzip >/dev/null 2>&1; then
		unzip -oq "$ZIP_FILE" -d "$UNPACK_DIR" >/dev/null 2>&1
		return $?
	fi

	if command -v busybox >/dev/null 2>&1 && busybox --list 2>/dev/null | grep -qx "unzip"; then
		busybox unzip -oq "$ZIP_FILE" -d "$UNPACK_DIR" >/dev/null 2>&1
		return $?
	fi

	if command -v bsdtar >/dev/null 2>&1; then
		bsdtar -xf "$ZIP_FILE" -C "$UNPACK_DIR" >/dev/null 2>&1
		return $?
	fi

	return 2
}

find_web_root() {
	if [ -f "$UNPACK_DIR/index.html" ]; then
		echo "$UNPACK_DIR"
		return 0
	fi

	index_file="$(find "$UNPACK_DIR" -type f -name index.html 2>/dev/null | head -n 1)"
	if [ -n "$index_file" ]; then
		dirname "$index_file"
		return 0
	fi

	return 1
}

activate_panel() {
	rm -rf "$DASHBOARD_LINK" >/dev/null 2>&1
	ln -s "$TARGET_DIR" "$DASHBOARD_LINK" >/dev/null 2>&1 || cp -a "$TARGET_DIR" "$DASHBOARD_LINK" >/dev/null 2>&1
	rm -rf /www/luci-static/yacd >/dev/null 2>&1
	if [ "$panel" = "yacd" ]; then
		ln -s "$TARGET_DIR" /www/luci-static/yacd >/dev/null 2>&1
	fi
}

trap cleanup EXIT INT TERM
mkdir -p "$UNPACK_DIR" "$TARGET_DIR" >/dev/null 2>&1
touch "$RUN_FILE"
set_state "downloading" "开始下载"

log_msg "Downloading dashboard panel..." "正在下载面板..."
if ! download_zip; then
	set_state "error" "下载失败"
	log_msg "Dashboard panel download failed" "面板下载失败"
	exit 1
fi

extract_zip
extract_rc=$?
if [ "$extract_rc" -ne 0 ]; then
	if [ "$extract_rc" -eq 2 ]; then
		set_state "error" "缺少解压工具"
		log_msg "Panel unzip tool not found" "缺少解压工具，无法安装面板"
	else
		set_state "error" "解压失败"
		log_msg "Dashboard panel unzip failed" "面板解压失败"
	fi
	exit 1
fi

SRC_DIR="$(find_web_root)"
if [ -z "$SRC_DIR" ] || [ ! -f "$SRC_DIR/index.html" ]; then
	set_state "error" "文件无效"
	log_msg "Dashboard panel content invalid" "面板文件无效"
	exit 1
fi

rm -rf "$TARGET_DIR"/* >/dev/null 2>&1
cp -a "$SRC_DIR"/. "$TARGET_DIR"/ >/dev/null 2>&1

activate_panel

uci set clashoo.config.dashboard_panel="$panel" >/dev/null 2>&1
uci commit clashoo >/dev/null 2>&1

set_state "success" "安装成功"
log_msg "Dashboard panel installed" "面板安装完成"
sleep 1
log_msg "Clashoo" "Clashoo" 1
exit 0
