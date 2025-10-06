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
  local port=`uci get immich.@main[0].port 2>/dev/null`
  local config=`uci get immich.@main[0].config_path 2>/dev/null`
  local IMMICH_VERSION=`uci get immich.@main[0].image_ver 2>/dev/null`
  local DB_PASSWORD=`uci get immich.@main[0].db_password 2>/dev/null`

  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  mkdir -p $config
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "mkdir config path failed"
    exit 1
  fi

  [ -z $port ] && port=2283
  [ -z $DB_PASSWORD ] && DB_PASSWORD = "postgres"
  [ -z $IMMICH_VERSION ] && IMMICH_VERSION = "release"
  cp /usr/share/immich/docker-compose.yaml $config/docker-compose.yaml
  sed 's/$port_var/'$port'/g; s/$immich_version_var/'$IMMICH_VERSION'/g; s/$db_password_var/'$DB_PASSWORD'/g' /usr/share/immich/env > $config/.env
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "convert docker-compose.yaml failed"
    exit 1
  fi

  cd $config
  export COMPOSE_PROJECT_NAME=linkease-immich

  istoreenhance_pull redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae

  istoreenhance_pull tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0

  istoreenhance_pull "linkease/immich-machine-learning:$IMMICH_VERSION"
  

  istoreenhance_pull "linkease/immich-server:$IMMICH_VERSION"
  

  docker-compose down || true
  docker-compose up -d
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the immich"
  echo "      upgrade                Upgrade the immich"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the immich"
  echo "      status                 Immich status"
  echo "      port                   Immich port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f immich
  ;;
  "start" | "stop" | "restart")
    config=`uci get immich.@main[0].config_path 2>/dev/null`
    cd $config && docker-compose ${ACTION}
  ;;
  "status")
    docker ps --all -f 'name=^/immich_server$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/immich_server$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
