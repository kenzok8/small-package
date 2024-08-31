#!/bin/sh

ACTION=${1}
shift 1

get_image() {
  IMAGE_NAME="carseason/mfun:laster"
}

do_install() {
  get_image
  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f mfun

  do_install_detail
}

do_install_detail() {
  local config_path=`uci get mfun.@mfun[0].config_path 2>/dev/null`
  local tmp_path=`uci get mfun.@mfun[0].tmp_path 2>/dev/null`
  local port=`uci get mfun.@mfun[0].port 2>/dev/null`
  local dev

  if [ -z "$config_path" ]; then
      echo "config path is empty!"
      exit 1
  fi
  if [ -z "$tmp_path" ]; then
      echo "tmp path is empty!"
      exit 1
  fi

  [ -z "$port" ] && port=8990

  local cmd="docker run --restart=unless-stopped -d \
    -v \"$config_path:/mfun/store\" \
    -v \"$tmp_path:/mfun/tmp\" \
    --dns=172.17.0.1 \
    -p $port:8990"

  if [ -e "/dev/rga" ]; then
    cmd="$cmd \
    -t \
    --privileged "
    for dev in iep rga dri dma_heap mali mali0 mpp_service mpp-service vpu_service vpu-service \
        hevc_service hevc-service rkvdec rkvenc avsd vepu h265e ; do
      [ -e "/dev/$dev" ] && cmd="$cmd --device /dev/$dev"
    done
  elif [ -d /dev/dri ]; then
    cmd="$cmd \
    --device /dev/dri:/dev/dri \
    --privileged "
  fi

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name mfun \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the mfun"
  echo "      upgrade                Upgrade the mfun"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the mfun"
  echo "      status                 Mfun status"
  echo "      port                   Mfun port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f mfun
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} mfun
  ;;
  "status")
    docker ps --all -f 'name=mfun' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=mfun' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
