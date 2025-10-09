#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

do_install() {
  local port=`uci get dpanel.@main[0].port 2>/dev/null`
  local image_name=`uci get dpanel.@main[0].image_name 2>/dev/null`
  local config=`uci get dpanel.@main[0].config_path 2>/dev/null`
  # config must be provided (same behavior as previous implementation)
  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  # If no port configured, default to 8807 (maps host:container 8807:8080)
  [ -z "$port" ] && port=8807
  # Default image for DPanel
  [ -z "$image_name" ] && image_name="dpanel/dpanel:lite"
  echo "docker pull ${image_name}"
  docker pull ${image_name}
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "download failed"
    exit 1
  fi
  docker rm -f dpanel

  local cmd="docker run -d --restart=always \
    -p $port:8080 \
    -e APP_NAME=dpanel \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v \"$config:/dpanel\" "

  cmd="$cmd\
  --dns=172.17.0.1 \
  --dns=223.5.5.5 "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"
  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"

  cmd="$cmd --name dpanel \"$image_name\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the dpanel"
  echo "      upgrade                Upgrade the dpanel"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the dpanel"
  echo "      status                 DPanel status"
  echo "      port                   DPanel port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f dpanel
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} dpanel
  ;;
  "status")
    docker ps --all -f 'name=^/dpanel$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/dpanel$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->8080/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac
