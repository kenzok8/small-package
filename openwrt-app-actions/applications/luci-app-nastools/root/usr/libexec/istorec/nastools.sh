#!/bin/sh

ACTION=${1}
shift 1

get_image() {
  IMAGE_NAME="jxxghp/nas-tools"
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f nastools

  do_install_detail
}

do_install_detail() {
  local config=`uci get nastools.@nastools[0].config_path 2>/dev/null`
  local port=`uci get nastools.@nastools[0].http_port 2>/dev/null`
  local auto_update=`uci get nastools.@nastools[0].auto_upgrade 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  [ -z "$port" ] && port=3003

  local cmd="docker run --restart=unless-stopped -d \
    --hostname nastools \
    -v \"$config:/config\" \
    --dns=172.17.0.1 \
    -p $port:3000 \
    -e UMASK=000"

  local tz="`cat /tmp/TZ`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  if [ -n "$auto_update" ]; then
    if [ "$auto_update" = 1 ]; then
      cmd="$cmd -e NASTOOL_AUTO_UPDATE=true"
    else
      cmd="$cmd -e NASTOOL_AUTO_UPDATE=false"
    fi
  fi

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"

  cmd="$cmd --name nastools \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the nastools"
  echo "      upgrade                Upgrade the nastools"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the nastools"
  echo "      status                 NasTools status"
  echo "      port                   NasTools port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f nastools
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} nastools
  ;;
  "status")
    docker ps --all -f 'name=nastools' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=nastools' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
