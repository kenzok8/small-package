#!/bin/sh

ACTION=${1}
shift 1


do_install() {
  local path=`uci -q get demon.@demon[0].cache_path 2>/dev/null`
  local image_name=`uci -q get demon.@demon[0].image_name 2>/dev/null`
  local port=`uci -q get demon.@demon[0].port 2>/dev/null`

  if [ -z "$path" ]; then
      echo "path is empty!"
      exit 1
  fi
  if [ -z "$port" ]; then
      port=18888
  fi

  if [ -z ${image_name} ]; then
    local arch=`uname -m`
    if [ "$arch" = "x86_64" ]; then
      image_name="images-cluster.xycloud.com/wxedge/amd64-wxedge:3.5.1-CTWXKS1748570956"
    else
      echo "Arm64 is not supported now"
      sleep 5
      exit 2
    fi
  fi

  docker pull "$image_name"
  docker rm -f onethingdemon
  if [ "$(docker inspect -f '{{.State.Running}}' wxedge 2>/dev/null)" = "true" ]; then
    echo "Stop wxedge due to incompatibility"
    docker stop wxedge
  fi

  local cmd="docker run --restart=unless-stopped -d \
    --privileged \
    --network=host \
    --dns=127.0.0.1 \
    --dns=223.5.5.5 \
    --tmpfs /run \
    --tmpfs /tmp \
    -v \"$path:/storage\" \
    -v \"$path/containerd:/var/lib/containerd\" \
    -e \"LISTEN_ADDR=:${port}\" \
    -e PLACE=CTKS"

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name onethingdemon \"$image_name\""

  echo "$cmd"
  eval "$cmd"

  if [ "$?" = "0" ]; then
    echo "Started OK"
    if [ "`uci -q get firewall.demon.enabled`" = 0 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.demon.enabled="1"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  fi

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the demon"
  echo "      upgrade                Upgrade the demon"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the demon"
  echo "      status                 Onething Demon status"
  echo "      port                   Onething Demon port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f onethingdemon
    if [ "`uci -q get firewall.demon.enabled`" = 1 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.demon.enabled="0"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} onethingdemon
  ;;
  "status")
    docker ps --all -f 'name=^/onethingdemon$' --format '{{.State}}'
  ;;
  "port")
    port=`uci -q get demon.@demon[0].port 2>/dev/null`
    echo $port
  ;;
  *)
    usage
    exit 1
  ;;
esac
