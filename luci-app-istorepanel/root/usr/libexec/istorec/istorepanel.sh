#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

do_install() {
  local port=`uci get istorepanel.@main[0].port 2>/dev/null`
  local image_name=`uci get istorepanel.@main[0].image_name 2>/dev/null`
  local config=`uci get istorepanel.@main[0].config_path 2>/dev/null`
  local entrance=`uci get istorepanel.@main[0].entrance 2>/dev/null`
  local username=`uci get istorepanel.@main[0].username 2>/dev/null`
  local password=`uci get istorepanel.@main[0].password 2>/dev/null`
  local ver=`uci get istorepanel.@main[0].ver 2>/dev/null`

  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  [ -z "$port" ] && port=10086
  [ -z "$ver" ] && ver='v1.10.10-lts'
  [ -z "$username" ] && username='1panel'
  [ -z "$password" ] && password='password'
  [ -z "$entrance" ] && entrance='entrance'

  mkdir -p $config

  cat > $config/env <<EOF
  export PANEL_BASE_DIR=${config}
  export PANEL_PORT=${port}
  export DEFAULT_ENTRANCE=${entrance}
  export DEFAULT_USERNAME=${username}
  export DEFAULT_PASSWORD=${password}
  export PANELVER=${ver}
EOF

  [ -z "$image_name" ] && image_name="linkease/istorepanel:latest"
  echo "docker pull ${image_name}"
  docker pull ${image_name}
  docker rm -f istorepanel

  if [ ! -f "/tmp/localtime" ]; then
    /etc/init.d/system reload
  fi

  local cmd="docker run --restart=unless-stopped -d -h 1PanelServer \
    --cgroupns=host \
    --cap-add SYS_ADMIN \
    --tmpfs /tmp \
    --network host \
    -v /sys/fs/cgroup:/sys/fs/cgroup \
    -v /var/run:/var2/run \
    -v \"$config:/iStorePanel\" "

  cmd="$cmd\
  --dns=172.17.0.1 \
  --dns=223.5.5.5 "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name istorepanel \"$image_name\""

  echo "$cmd"
  eval "$cmd"

  echo "Installing 1panel"
  for b in {1..30}
  do
    sleep 3
    docker_status=`docker ps --all -f 'name=istorepanel' --format '{{.State}}'`
    if [[ $docker_status == *running* ]]; then
      docker exec istorepanel /app/reinstall.sh
      break;
    else
      echo "istorepanel is not running, wait..."
    fi
  done
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the istorepanel"
  echo "      upgrade                Upgrade the istorepanel"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the istorepanel"
  echo "      status                 1Panel status"
  echo "      port                   1Panel port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f istorepanel
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} istorepanel
  ;;
  "status")
    docker ps --all -f 'name=istorepanel' --format '{{.State}}'
  ;;
  "port")
    echo `uci get istorepanel.@main[0].port 2>/dev/null`
  ;;
  *)
    usage
    exit 1
  ;;
esac
