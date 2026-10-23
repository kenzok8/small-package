#!/bin/sh

ACTION=${1}
shift 1

do_install() {
  if echo `uname -m` | grep -Eqi 'x86_64'; then
    echo "Support x86_64"
  else
    echo "Not x86_64, only support x86_64, exit"
    sleep 3
    exit 1
  fi

  if [ -e /dev/kvm ]; then
    echo "/dev/kvm exists"
  else
    echo "/dev/kvm does not exist"
    sleep 3
    exit 2
  fi

  local config=`uci get pve.@pve[0].config_path 2>/dev/null`
  local root_pwd=`uci get pve.@pve[0].root_pwd 2>/dev/null`
  local IMAGE_NAME=`uci get pve.@pve[0].image_name 2>/dev/null`
  local tz=`uci get pve.@pve[0].time_zone 2>/dev/null`
  local port=`uci get pve.@pve[0].http_port 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi
  [ -z "$port" ] && port=8006

  echo "start vmease"
  /etc/init.d/vmease start
  sleep 1

  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f pve
  mkdir -p "$config"

  local cmd="docker run --restart=unless-stopped -d \
    --privileged \
    --tmpfs /tmp \
    --tmpfs /run/lock \
	  --hostname pve \
    -e "ISTOREOS=1" \
    -v \"/var/run:/host/var/run\" \
    -v \"$config/vz:/var/lib/vz\" \
    -v \"$config/pve-cluster:/var/lib/pve-cluster\" \
	  --device /dev/kvm:/dev/kvm \
    -p $port:8006 \
    --dns=172.17.0.1 \
    --dns=223.5.5.5 "

  [ -e "/dev/vfio" ] && cmd="$cmd -v \"/dev/vfio:/dev/vfio\""
  if [ -z "$tz" ]; then
    tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  fi
  [ -z "$tz" ] || cmd="$cmd -e TZ=\"$tz\""
  [ -z "$root_pwd" ] || cmd="$cmd -e root_password=\"$root_pwd\""

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"

  cmd="$cmd --name pve \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

  echo "Waiting"
  sleep 8
  echo "Done"
}

do_gpu_passthrough() {
  echo "TODO"
  return 0
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the pve"
  echo "      upgrade                Upgrade the pve"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the pve"
  echo "      status                 pve status"
  echo "      port                   pve port"
}

# Read the exact container TCP binding, never another application's port.
# Empty success means no LAN-visible publication; failures stay failures.
do_entry_port() {
    local bindings address candidate extra port=''
    bindings=$(docker inspect --format '{{range (index .NetworkSettings.Ports "8006/tcp")}}{{printf "%s %s\n" .HostIp .HostPort}}{{end}}' pve) || return 1
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
    docker rm -f pve
  ;;
  "start")
    /etc/init.d/vmease start
    sleep 1
    docker ${ACTION} pve
  ;;
  "stop")
    docker ${ACTION} pve
  ;;
  "restart")
    /etc/init.d/vmease start
    sleep 1
    docker ${ACTION} pve
  ;;
  "status")
    docker ps --all -f 'name=^/pve$' --format '{{.State}}'
  ;;
  "port")
    do_entry_port
  ;;
  "gpu-passthrough")
    do_gpu_passthrough
  ;;
  *)
    usage
    exit 1
  ;;
esac
