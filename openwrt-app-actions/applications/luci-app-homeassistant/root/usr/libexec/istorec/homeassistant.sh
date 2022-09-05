#!/bin/sh

ACTION=${1}
shift 1

get_image() {
  IMAGE_NAME="homeassistant/home-assistant:latest"
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f homeassistant

  do_install_detail
}

do_install_detail() {
  local config=`uci get homeassistant.@homeassistant[0].config_path 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  local cmd="docker run --restart=unless-stopped -d \
    -v \"$config:/config\" \
    --privileged \
    --network=host \
    --dns=127.0.0.1 "

  local tz="`cat /tmp/TZ`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name homeassistant \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the homeassistant"
  echo "      upgrade                Upgrade the homeassistant"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the homeassistant"
  echo "      status                 Home Assistant status"
  echo "      port                   Home Assistant port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f homeassistant
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} homeassistant
  ;;
  "status")
    docker ps --all -f 'name=homeassistant' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=homeassistant' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
