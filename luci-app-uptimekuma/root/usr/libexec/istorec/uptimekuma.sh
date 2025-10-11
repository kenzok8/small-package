#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

do_install() {
  local port=`uci get uptimekuma.@main[0].port 2>/dev/null`
  local image_name=`uci get uptimekuma.@main[0].image_name 2>/dev/null`
  local config=`uci get uptimekuma.@main[0].config_path 2>/dev/null`

  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  [ -z "$port" ] && port=3001
  [ -z "$image_name" ] && image_name="louislam/uptime-kuma:1"
  echo "docker pull ${image_name}"
  docker pull ${image_name}
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "download failed"
    exit 1
  fi
  docker rm -f uptimekuma

  local cmd="docker run --restart=unless-stopped -d -h UptimeKumaServer \
    -p $port:3001 \
    -v \"$config:/app/data\" "

  cmd="$cmd\
  --dns=172.17.0.1 \
  --dns=223.5.5.5 "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"
  cmd="$cmd --name uptimekuma \"$image_name\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the uptimekuma"
  echo "      upgrade                Upgrade the uptimekuma"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the uptimekuma"
  echo "      status                 UptimeKuma status"
  echo "      port                   UptimeKuma port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f uptimekuma
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} uptimekuma
  ;;
  "status")
    docker ps --all -f 'name=^/uptimekuma$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/uptimekuma$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->9060/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac
