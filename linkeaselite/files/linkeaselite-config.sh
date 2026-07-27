#!/bin/sh

. /lib/functions.sh

case "$1" in
  save)
    if [ -n "$2" ]; then
      uci set "linkeaselite.@linkeaselite[0].preconfig=$2"
      uci commit linkeaselite
    fi
    ;;

  load)
    data="`uci -q get linkeaselite.@linkeaselite[0].preconfig`"
    if [ -z "${data}" ]; then
      echo "nil"
    else
      echo "${data}"
    fi
    ;;

  local_save)
    if [ -n "$2" ]; then
      uci set "linkeaselite.@linkeaselite[0].local_home=$2"
      uci commit linkeaselite
      ROOT_DIR="$2"
      if [ -f "/etc/config/quickstart" ]; then
        config_load quickstart
        config_get MAIN_DIR main main_dir ""
        config_get CONF_DIR main conf_dir ""
        config_get PUB_DIR main pub_dir ""
        config_get DL_DIR main dl_dir ""
        config_get TMP_DIR main tmp_dir ""
        [ "$ROOT_DIR" = "$MAIN_DIR" ] && exit 0
        uci set "quickstart.main.main_dir=$ROOT_DIR"
        if [ -z "$CONF_DIR" ] || [ "$CONF_DIR" = "$MAIN_DIR/Configs" ]; then
          uci set "quickstart.main.conf_dir=$ROOT_DIR/Configs"
        fi
        if [ -z "$PUB_DIR" ] || [ "$PUB_DIR" = "$MAIN_DIR/Public" ]; then
          uci set "quickstart.main.pub_dir=$ROOT_DIR/Public"
        fi
        if [ -z "$DL_DIR" ] || [ "$DL_DIR" = "$MAIN_DIR/Public/Downloads" ]; then
          uci set "quickstart.main.dl_dir=$ROOT_DIR/Public/Downloads"
        fi
        if [ -z "$TMP_DIR" ] || [ "$TMP_DIR" = "$MAIN_DIR/Caches" ]; then
          uci set "quickstart.main.tmp_dir=$ROOT_DIR/Caches"
        fi
        uci commit quickstart
      fi
    fi
    ;;

  local_load)
    if [ -f "/etc/config/quickstart" ]; then
      data="`uci -q get quickstart.main.main_dir`"
    fi
    if [ -z "$data" ]; then
      data="`uci -q get linkeaselite.@linkeaselite[0].local_home`"
    fi
    if [ -z "${data}" ]; then
      echo "nil"
    else
      echo "${data}"
    fi
    ;;

  status)
    if pidof linkease-lite >/dev/null 2>&1; then
      echo "running"
    else
      echo "stopped"
    fi
    ;;

  *)
    echo "Usage: $0 {save|load|local_save|local_load|status}"
    exit 1
esac
