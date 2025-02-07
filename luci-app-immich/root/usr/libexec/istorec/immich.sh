#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

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
  docker pull tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "download failed"
    exit 1
  fi
  docker pull "immich-app/immich-machine-learning:$IMMICH_VERSION"
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "download failed"
    exit 1
  fi
  docker pull "immich-app/immich-server:$IMMICH_VERSION"
  RET=$?
  if [ ! "$RET" = "0" ]; then
    echo "download failed"
    exit 1
  fi
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
    docker ps --all -f 'name=^/linkease-immich_frontend_1$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/linkease-immich_frontend_1$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
