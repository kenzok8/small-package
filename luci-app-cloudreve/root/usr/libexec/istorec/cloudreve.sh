#!/bin/sh
# istorec script for cloudreve (iStoreOS native app integration)
#
# This is how the official "Configs" folder reaches the app:
#   is-opkg AUTOCONF=cloudreve path=<base> ...
#     -> derives ISTORE_CONF_DIR=<base>/Configs
#     -> calls: /usr/libexec/istorec/cloudreve.sh autoconf "$ISTORE_CONF_DIR"
# We then persist that base path into UCI so both init.d and LuCI agree.
#
# Actions: install / autoconf / upgrade / remove / start / stop / status

CONF="cloudreve"
INIT="/etc/init.d/cloudreve"
CONFIGS_DIR="Configs"
APP_SUBDIR="cloudreve"

UCI() { uci -q "$@"; }

# Persist base path (mount point) into UCI section @cloudreve[0]
set_base() {
	base="$1"
	[ -n "$base" ] || return 1
	UCI set ${CONF}.@cloudreve[0].storage_path="$base" 2>/dev/null
	UCI commit ${CONF} 2>/dev/null
	return 0
}

app_dir_of() {
	base="$1"
	echo "${base}/${CONFIGS_DIR}/${APP_SUBDIR}"
}

ensure_dirs() {
	base="$1"
	app_dir="$(app_dir_of "$base")"
	mkdir -p "$app_dir" 2>/dev/null || return 1
	return 0
}

case "$1" in

install)
	# Fresh install: nothing heavy; LuCI guides binary download
	echo "Cloudreve 安装完成。请打开 LuCI 管理页 → NAS → Cloudreve 云盘，选择磁盘并下载程序本体。"
	exit 0
	;;

autoconf)
	# Called by is-opkg: $2 = ISTORE_CONF_DIR (e.g. /mnt/sda1/Configs)
	conf_dir="${2:-}"
	[ -n "$conf_dir" ] || { echo "缺少参数：未传入 ISTORE_CONF_DIR" >&2; exit 1; }
	# Strip trailing /Configs to recover base mount point
	base="$(dirname "$conf_dir")"
	# 路径安全校验：照抄 openclawmgr validate_base_dir
	case "$base" in
		/*) ;;
		*) echo "路径必须是绝对路径: $base" >&2; exit 1 ;;
	esac
	[ "$base" != "/" ] || { echo "不能使用根目录 /: $base" >&2; exit 1; }
	case "$base" in
		/root|/root/*) echo "不能使用 /root 开头的目录: $base" >&2; exit 1 ;;
	esac
	case "$base" in
		*"/../"*|*"/.."|*"/./"*|*"/.") echo "路径不能包含 .. 或 .: $base" >&2; exit 1 ;;
	esac
	case "$base" in
		/bin|/bin/*|/sbin|/sbin/*|/lib|/lib/*|/usr|/usr/*|/etc|/etc/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/run|/run/*|/tmp|/tmp/*|/var|/var/*|/overlay|/overlay/*|/rom|/rom/*)
			echo "$base 是系统目录，禁止使用" >&2; exit 1
			;;
	esac
	set_base "$base" || exit 1
	ensure_dirs "$base" || exit 1
	echo "autoconf: base=$base conf_dir=$conf_dir app_dir=$(app_dir_of "$base")"
	exit 0
	;;

upgrade)
	# Keep existing binary; just ensure dirs still exist
	base="$(uci -q get ${CONF}.@cloudreve[0].storage_path 2>/dev/null)"
	if [ -n "$base" ]; then
		ensure_dirs "$base" || true
	fi
	exit 0
	;;

rm|remove)
	# 生态标准子命令是 rm，remove 作为兼容别名保留
	[ -x "$INIT" ] && "$INIT" stop >/dev/null 2>&1 || true
	[ -x "$INIT" ] && "$INIT" disable >/dev/null 2>&1 || true
	echo "Cloudreve 已停止。Configs/cloudreve 下的程序本体保留不动，不会被删除。"
	exit 0
	;;

start)
	[ -x "$INIT" ] && exec "$INIT" start
	exit 1
	;;

stop)
	[ -x "$INIT" ] && exec "$INIT" stop
	exit 1
	;;

restart)
	[ -x "$INIT" ] && exec "$INIT" restart
	exit 1
	;;

status)
	[ -x "$INIT" ] && exec "$INIT" status
	exit 1
	;;

port)
	# 输出实际监听端口，供 iStore / 面板拼访问地址
	uci -q get ${CONF}.@cloudreve[0].listen_port 2>/dev/null || echo "5212"
	exit 0
	;;

*)
	echo "Usage: $0 {install|autoconf <ISTORE_CONF_DIR>|upgrade|rm|start|stop|restart|status|port}" >&2
	exit 1
	;;
esac
