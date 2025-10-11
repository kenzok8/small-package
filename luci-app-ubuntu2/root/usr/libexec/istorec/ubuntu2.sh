#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

do_install() {
  local https_port=`uci get ubuntu2.@main[0].https_port 2>/dev/null`
  local image_name=`uci get ubuntu2.@main[0].image_name 2>/dev/null`
  local config=`uci get ubuntu2.@main[0].config_path 2>/dev/null`
  local pwd=`uci get ubuntu2.@main[0].password 2>/dev/null`
  if [ -z ${IMAGE_NAME} ]; then
    local arch=`uname -m`
    if [ "$arch" = "x86_64" ]; then
      IMAGE_NAME=linkease/desktop-ubuntu2-standard-amd64:latest
    else
      IMAGE_NAME=linkease/desktop-ubuntu2-standard-arm64:latest
    fi
  fi

  echo "docker pull ${image_name}"
  docker pull ${image_name}
  docker rm -f ubuntu2

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  # not conflict with jellyfin
  [ -z "$https_port" ] && https_port=3001

  local cmd="docker run --restart=unless-stopped -d --user 0:0 -e START_DOCKER=false -v \"$config:/config\" \
    --privileged --device /dev/fuse --security-opt apparmor=unconfined --shm-size=512m \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --dns=172.17.0.1 \
    -p $https_port:3001 "

  if [ -n "$pwd" ]; then
    cmd="$cmd -e \"PASSWORD=$pwd\" "
  fi

  if [ -d /dev/dri ]; then
    cmd="$cmd\
    --device /dev/dri:/dev/dri "
  fi

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name ubuntu2 \"$image_name\""

  echo "$cmd"
  eval "$cmd"
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the ubuntu2"
  echo "      upgrade                Upgrade the ubuntu2"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the ubuntu2"
  echo "      status                 Ubuntu2 status"
  echo "      port                   Ubuntu2 port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f ubuntu2
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} ubuntu2
  ;;
  "status")
    docker ps --all -f 'name=^/ubuntu2$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/ubuntu2$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->3001/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac
