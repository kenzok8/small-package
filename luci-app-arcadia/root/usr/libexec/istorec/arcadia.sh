#!/bin/sh
# Author jjm2473@gmail.com
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

ARCH="default"
IMAGE_NAME='default'

get_image() {
  IMAGE_NAME=`uci get arcadia.@arcadia[0].image 2>/dev/null`
  if [ -z "$IMAGE_NAME" -o "$IMAGE_NAME" == "default" ]; then
      IMAGE_NAME="supermanito/arcadia:beta"
  fi
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f arcadia

  do_install_detail
}

do_install_detail() {
  local hostnet=`uci get arcadia.@arcadia[0].hostnet 2>/dev/null`
  local config=`uci get arcadia.@arcadia[0].config_path 2>/dev/null`
  local port=`uci get arcadia.@arcadia[0].port 2>/dev/null`
  local dev

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  [ -z "$port" ] && port=5678

  local cmd="docker run --restart=unless-stopped -d -v \"$config/config:/arcadia/config\" -v \"$config/log:/arcadia/log\" -v \"$config/scripts:/arcadia/scripts\" -v \"$config/repo:/arcadia/repo\" -v \"$config/raw:/arcadia/raw\" -v \"$config/tgbot:/arcadia/tgbot\" "
  if [ "$hostnet" = 1 ]; then
    cmd="$cmd\
    --dns=127.0.0.1 \
    --network=host "
  else
    cmd="$cmd\
    --dns=172.17.0.1 \
    -p $port:5678 "
  fi

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name arcadia \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the arcadia"
  echo "      upgrade                Upgrade the arcadia"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the arcadia"
  echo "      status                 Arcadia status"
  echo "      port                   Arcadia port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f arcadia
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} arcadia
  ;;
  "status")
    docker ps --all -f 'name=^/arcadia$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/arcadia$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->5678/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac
