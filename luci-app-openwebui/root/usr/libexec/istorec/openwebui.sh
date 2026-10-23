#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
shift 1

do_install() {
  local port=`uci get openwebui.@main[0].port 2>/dev/null`
  local image_name=`uci get openwebui.@main[0].image_name 2>/dev/null`
  local config=`uci get openwebui.@main[0].config_path 2>/dev/null`

  if [ -z "$config" ]; then
    echo "config path is empty!"
    exit 1
  fi

  [ -z "$port" ] && port=10086
  mkdir -p $config

  [ -z "$image_name" ] && image_name="backplane/open-webui:main"
  echo "docker pull ${image_name}"
  docker pull ${image_name}
  RET=$?                                                                                              
  if [ ! "$RET" = "0" ]; then                                                                         
    echo "download failed"                                                                            
    exit 1                                       
  fi
  docker rm -f openwebui

  local cmd="docker run --restart=unless-stopped -d -h OpenWebUIServer \
    -e OPENAI_API_KEY=your_secret_key \
    -p $port:8080 \
    -v \"$config:/app/backend/data\" "

  cmd="$cmd\
  --dns=172.17.0.1 \
  --dns=223.5.5.5 "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --name openwebui \"$image_name\""

  echo "$cmd"
  eval "$cmd"
  echo "Initial..."
  sleep 10
  echo "Done"
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the openwebui"
  echo "      upgrade                Upgrade the openwebui"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the openwebui"
  echo "      status                 OpenWebUI status"
  echo "      port                   OpenWebUI port"
}

# Read the exact container TCP binding, never another application's port.
# Empty success means no LAN-visible publication; failures stay failures.
do_entry_port() {
    local bindings address candidate extra port=''
    bindings=$(docker inspect --format '{{range (index .NetworkSettings.Ports "8080/tcp")}}{{printf "%s %s\n" .HostIp .HostPort}}{{end}}' openwebui) || return 1
    while read -r address candidate extra; do
        [ -n "$address$candidate$extra" ] || continue
        [ -z "$extra" ] || return 1
        case "$candidate" in ''|*[!0-9]*) return 1 ;; esac
        [ "${#candidate}" -le 5 ] && [ "$candidate" -ge 1 ] && [ "$candidate" -le 65535 ] || return 1
        case "$address" in 127.*|::1|'[::1]') continue ;; esac
        [ -z "$port" ] || [ "$port" = "$candidate" ] || return 1
        port=$candidate
    done <<EOF
$bindings
EOF
    [ -z "$port" ] || printf '%s\n' "$port"
    return 0
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f openwebui
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} openwebui
  ;;
  "status")
    docker ps --all -f 'name=^/openwebui$' --format '{{.State}}'
  ;;
  "port")
    do_entry_port
  ;;
  *)
    usage
    exit 1
  ;;
esac
