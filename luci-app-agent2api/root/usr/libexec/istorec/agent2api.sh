#!/bin/sh
# Agent2API iStore lifecycle script.
# Called by luci-app-agent2api through taskd.docker_map; not meant for manual use.

ACTION=${1}
shift 1

# Pull the image, and on failure explain how to enable KSpeeder acceleration.
# The KSpeeder/iStoreEnhance registry mirror is configured at the Docker level,
# so a normal "docker pull" already goes through it when iStoreEnhance is active.
istoreenhance_pull() {
  local image_name="$1"
  echo "docker pull ${image_name}"
  if docker pull "$image_name"; then
    return 0
  fi
  local isInstall=$(command -v iStoreEnhance)
  local isRun=$(pgrep iStoreEnhance)
  if [ -n "$isRun" ]; then
    local registry_mirror=$(docker info 2>/dev/null | awk -F': ' '/Registry Mirrors:/ {found=1; next} found && NF {if ($0 ~ /registry.linkease.net/) {print; exit}}')
    if [ -n "$registry_mirror" ]; then
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
}

do_install() {
  local http_port=`uci get agent2api.@main[0].http_port 2>/dev/null`
  local image_name=`uci get agent2api.@main[0].image_name 2>/dev/null`
  local config=`uci get agent2api.@main[0].config_path 2>/dev/null`

  [ -z "$image_name" ] && image_name="aimodcc/agent2api:latest"
  [ -z "$http_port" ] && http_port=3065

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi

  mkdir -p "$config" || exit 1

  istoreenhance_pull "${image_name}"
  docker rm -f agent2api

  set -- docker run --restart=unless-stopped -d \
    --dns=172.17.0.1 \
    -v "$config:/data" \
    -p "$http_port:3065"

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || set -- "$@" -e "TZ=$tz"

  # Small-memory friendly: cap the two in-memory image caches (MiB).
  set -- "$@" -e AGENT2API_IMAGE_CACHE_MB=64 -e AGENT2API_IMAGE_COMPRESS_CACHE_MB=64

  set -- "$@" --name agent2api "$image_name"

  printf '%s ' "$@"
  printf '\n'
  "$@"
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the Agent2API"
  echo "      upgrade                Upgrade the Agent2API"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the Agent2API"
  echo "      status                 Agent2API status"
  echo "      port                   Agent2API port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f agent2api
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} agent2api
  ;;
  "status")
    docker ps --all -f 'name=^/agent2api$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/agent2api$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
