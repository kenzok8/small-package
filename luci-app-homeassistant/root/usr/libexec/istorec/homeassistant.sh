#!/bin/sh

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
  local config=`uci get homeassistant.@homeassistant[0].config_path 2>/dev/null`
  local IMAGE_NAME=`uci get homeassistant.@homeassistant[0].image_name 2>/dev/null`
  local tz=`uci get homeassistant.@homeassistant[0].time_zone 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  istoreenhance_pull ${IMAGE_NAME}
  docker rm -f homeassistant

  local cmd="docker run --restart=unless-stopped -d \
    -v \"$config:/config\" \
    --privileged \
    --network=host \
    --dns=127.0.0.1 "

  if [ -z "$tz" ]; then
    tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  fi
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name homeassistant \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

  RET=$?
  if [ "$RET" = "0" ]; then
    echo "Wait 10 seconds for homeassistant boot..."
    sleep 10
    do_hacs_install
  fi
}

do_hacs_install() {
  echo "Install HACS"
  echo "rm -f custom_components/hacs.zip config/custom_components/hacs.zip ; wget -O - https://get.hacs.xyz | bash -" | docker exec -i homeassistant bash -
  sleep 3
  echo "restart homeassistant"
  docker restart homeassistant
  return 0
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
    docker ps --all -f 'name=^/homeassistant$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/homeassistant$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  "hacs-install")
    do_hacs_install
  ;;
  *)
    usage
    exit 1
  ;;
esac
