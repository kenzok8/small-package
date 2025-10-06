#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

istoreenhance_pull() {
  local image_name="$1"
  echo "docker pull ${image_name}"
  docker pull "$image_name"
  if [ $? -ne 0 ]; then
    local isInstall=$(command -v iStoreEnhance)
    local isRun=$(pgrep iStoreEnhance)
      # 判断iStoreEnhance是否运行
    if [ -n "$isRun" ]; then
      # 使用 docker info 获取包含 registry.linkease.net 的镜像服务器地址
      local registry_mirror=$(docker info 2>/dev/null | awk -F': ' '/Registry Mirrors:/ {found=1; next} found && NF {if ($0 ~ /registry.linkease.net/) {print; exit}}')

      if [[ -n "$registry_mirror" ]]; then
        echo "istoreenhance_pull failed"
      else
        echo "download failed, not found registry.linkease.net"
      fi
    else
      if [ -z "$isInstall" ]; then
        echo "download failed, install istoreenhance to speedup, \"https://doc.linkease.com/zh/guide/istore/software/istoreenhance.html\""
      else
        echo "download failed, enable istoreenhance to speedup"
      fi
    fi
    exit 1
  fi
}

do_install() {
  local port=`uci get ittools.@main[0].port 2>/dev/null`
  local image_name=`uci get ittools.@main[0].image_name 2>/dev/null`

  [ -z "$image_name" ] && image_name="linuxserver/ittools:latest"
  istoreenhance_pull ${image_name}
  docker rm -f ittools

  [ -z "$port" ] && port=9070

  local cmd="docker run --restart=unless-stopped -d -h ITToolsServer "

  cmd="$cmd\
  --dns=172.17.0.1 \
  -p $port:80 "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name ittools \"$image_name\""

  echo "$cmd"
  eval "$cmd"
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the ittools"
  echo "      upgrade                Upgrade the ittools"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the ittools"
  echo "      status                 ITTools status"
  echo "      port                   ITTools port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f ittools
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} ittools
  ;;
  "status")
    docker ps --all -f 'name=^/ittools$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/ittools$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*->9070/tcp' | sed 's/0.0.0.0:\([0-9]*\)->.*/\1/'
  ;;
  *)
    usage
    exit 1
  ;;
esac
