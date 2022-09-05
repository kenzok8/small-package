#!/bin/sh

ACTION=${1}
shift 1

get_image() {
  IMAGE_NAME="kodcloud/kodbox:latest"
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f kodexplorer

  do_install_detail
}

do_install_detail() {
  local config=`uci get kodexplorer.@kodexplorer[0].cache_path 2>/dev/null`
  local port=`uci get kodexplorer.@kodexplorer[0].port 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  [ -z "$port" ] && port=8081

  local cmd="docker run --restart=unless-stopped -d \
    -v \"$config:/var/www/html\" \
    --dns=172.17.0.1 \
    -p $port:80 "

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"

  local tz="`cat /tmp/TZ`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name kodexplorer \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the kodexplorer"
  echo "      upgrade                Upgrade the kodexplorer"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the kodexplorer"
  echo "      status                 KodExplorer status"
  echo "      port                   KodExplorer port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f kodexplorer
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} kodexplorer
  ;;
  "status")
    docker ps --all -f 'name=kodexplorer' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=kodexplorer' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
