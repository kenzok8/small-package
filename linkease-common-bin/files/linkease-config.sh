#!/bin/sh

. /lib/functions.sh

ensure_linkease_config() {
	if ! uci -q get linkease.@linkease[0] >/dev/null; then
		uci -q add linkease linkease >/dev/null
		uci -q set linkease.@linkease[0].enabled='0'
		uci -q set linkease.@linkease[0].port='8897'
		uci -q set linkease.@linkease[0].allowPublic='0'
		uci -q commit linkease
	fi
}

sync_linkeasefull_local_home() {
	if uci -q get linkeasefull.@linkeasefull[0] >/dev/null; then
		uci -q set "linkeasefull.@linkeasefull[0].data_root_parent=$1"
		uci -q commit linkeasefull
	fi
}

case "$1" in
  save)
	ensure_linkease_config
	if [ ! -z "$2" ]; then
	  uci set "linkease.@linkease[0].preconfig=$2"
	  uci commit linkease
	fi
	;;

  load)
	ensure_linkease_config
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
	ensure_linkease_config
	if [ ! -z "$2" ]; then
	  uci set "linkease.@linkease[0].local_home=$2"
	  uci commit linkease
	  sync_linkeasefull_local_home "$2"
	  ROOT_DIR="$2"
	  if [ -f "/etc/config/quickstart" ]; then
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
	ensure_linkease_config
	if [ -f "/etc/config/quickstart" ]; then
	  data="`uci -q get quickstart.main.main_dir`"
	fi
	if [ -z "$data" ]; then
	  data="`uci -q get linkease.@linkease[0].local_home`"
	fi
	if [ -z "$data" ]; then
	  data="`uci -q get linkeasefull.@linkeasefull[0].data_root_parent`"
	fi

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
