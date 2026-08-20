#!/bin/sh

. /lib/functions.sh

ensure_linkease_config() {
	if [ ! -f /etc/config/linkease ]; then
		touch /etc/config/linkease || return 1
	fi
	if ! uci -q get linkease.@linkease[0] >/dev/null; then
		uci -q add linkease linkease >/dev/null || return 1
		uci -q set linkease.@linkease[0].enabled='0' || return 1
		uci -q set linkease.@linkease[0].port='8897' || return 1
		uci -q set linkease.@linkease[0].allowPublic='0' || return 1
		uci -q commit linkease || return 1
	fi
}

case "$1" in
  save)
	ensure_linkease_config || exit 1
	if [ ! -z "$2" ]; then
	  uci set "linkease.@linkease[0].preconfig=$2"
	  uci commit linkease
	fi
	;;

  load)
	ensure_linkease_config || exit 1
	if [ -f "/usr/sbin/preconfig.data" ]; then
	  data="`cat /usr/sbin/preconfig.data`"
	  uci set "linkease.@linkease[0].preconfig=${data}"
	  uci commit linkease
	  rm /usr/sbin/preconfig.data
	else
	  data="`uci -q get linkease.@linkease[0].preconfig`"
	fi

	if [ -z "${data}" ]; then
	  echo "nil"
	else
	  echo "${data}"
	fi

	;;

  local_save)
	if [ ! -z "$2" ]; then
	  ensure_linkease_config || exit 1
	  uci set "linkease.@linkease[0].local_home=$2"
	  uci commit linkease
	  ROOT_DIR="$2"
	  if [ -f "/etc/config/quickstart" ]; then
		if ! uci -q get quickstart.main >/dev/null; then
		  uci -q set quickstart.main=main
		fi
		config_load quickstart
		config_get MAIN_DIR main main_dir ""
		config_get CONF_DIR main conf_dir ""
		config_get PUB_DIR main pub_dir ""
		config_get DL_DIR main dl_dir ""
		config_get TMP_DIR main tmp_dir ""
		if [ "$ROOT_DIR" = "$MAIN_DIR" ]; then
		  exit 0
		fi
		uci set "quickstart.main.main_dir=$ROOT_DIR"
		if [ -z "$CONF_DIR" -o "$CONF_DIR" = "$MAIN_DIR/Configs" ]; then
		  uci set "quickstart.main.conf_dir=$ROOT_DIR/Configs"
		fi
		if [ -z "$PUB_DIR" -o "$PUB_DIR" = "$MAIN_DIR/Public" ]; then
		  uci set "quickstart.main.pub_dir=$ROOT_DIR/Public"
		fi
		if [ -z "$DL_DIR" -o "$DL_DIR" = "$MAIN_DIR/Public/Downloads" ]; then
		  uci set "quickstart.main.dl_dir=$ROOT_DIR/Public/Downloads"
		fi
		if [ -z "$TMP_DIR" -o "$TMP_DIR" = "$MAIN_DIR/Caches" ]; then
		  uci set "quickstart.main.tmp_dir=$ROOT_DIR/Caches"
		fi
		uci commit quickstart
	  fi
	fi
	;;

  local_load)
	ensure_linkease_config || exit 1
	data="`uci -q get linkease.@linkease[0].local_home`"

	if [ -z "${data}" ]; then
	  echo "nil"
	else
	  echo "${data}"
	fi

	;;

  status)
	echo "TODO"
	;;

  *)
	echo "Usage: $0 {save|load|local_save|local_load|status}"
	exit 1
esac
