#!/bin/sh

ACTION=${1}
shift 1


# 1. 判断iStoreEnhance是否运行
# 2. 使用 docker info 获取包含 registry.linkease.net 的镜像服务器地址
# 3. 如果1和2都满足，则直接 docker pull registry.linkease.net:5443/onething1/wxedge
# 4. 反之运行docker pull
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
  local path=`uci get wxedge.@wxedge[0].cache_path 2>/dev/null`
  local image_name=`uci get wxedge.@wxedge[0].image_name 2>/dev/null`

  if [ -z "$path" ]; then
      echo "path is empty!"
      exit 1
  fi

  [ -z "$image_name" ] && image_name="onething1/wxedge"
  istoreenhance_pull "$image_name"
  docker rm -f wxedge

  local cmd="docker run --restart=unless-stopped -d \
    --privileged \
    --network=host \
    --dns=127.0.0.1 \
    --tmpfs /run \
    --tmpfs /tmp \
    -v \"$path:/storage\" \
    -v \"$path/containerd:/var/lib/containerd\" \
    -e PLACE=CTKS"

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name wxedge \"$image_name\""

  echo "$cmd"
  eval "$cmd"

  if [ "$?" = "0" ]; then
    if [ "`uci -q get firewall.wxedge.enabled`" = 0 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.wxedge.enabled="1"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  fi

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the wxedge"
  echo "      upgrade                Upgrade the wxedge"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the wxedge"
  echo "      status                 Onething Edge status"
  echo "      port                   Onething Edge port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f wxedge
    if [ "`uci -q get firewall.wxedge.enabled`" = 1 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.wxedge.enabled="0"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} wxedge
  ;;
  "status")
    docker ps --all -f 'name=^/wxedge$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/wxedge$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac
