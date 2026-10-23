#!/bin/sh

ACTION=${1}
shift 1

do_install() {
  local config=`uci get webvirtcloud.@webvirtcloud[0].config_path 2>/dev/null`
  local IMAGE_NAME=`uci get webvirtcloud.@webvirtcloud[0].image_name 2>/dev/null`
  local tz=`uci get webvirtcloud.@webvirtcloud[0].time_zone 2>/dev/null`
  local port=`uci get webvirtcloud.@webvirtcloud[0].http_port 2>/dev/null`

  if [ -z "$config" ]; then
      echo "config path is empty!"
      exit 1
  fi
  [ -z "$port" ] && port=6009

  echo "start vmease"
  /etc/init.d/vmease start
  sleep 1

  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f webvirtcloud
  mkdir -p "$config"
  rm -rf "$config/vmwebvirt"
  cp /usr/sbin/vmeasedaemon "$config/vmwebvirt"

  local cmd="docker run --restart=unless-stopped -d \
    --cgroupns=host \
    --tmpfs /tmp \
    --tmpfs /run/lock \
    -v /sys/fs/cgroup:/sys/fs/cgroup \
    -v \"$config/dbconfig:/srv/webvirtcloud/dbconfig\" \
    -v \"$config/libvirt:/etc/libvirt\" \
    -v \"$config/images:/var/lib/libvirt/images\" \
    -v \"$config/vmwebvirt:/usr/sbin/vmwebvirt\" \
    -v /var/run/vmease:/srv/vmease \
    -p $port:80 \
    --privileged \
    --dns=172.17.0.1 \
    --dns=223.5.5.5 "

  if [ -z "$tz" ]; then
    tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  fi
  [ -z "$tz" ] || cmd="$cmd -e TZ=\"$tz\""

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"

  cmd="$cmd --name webvirtcloud \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"

  sleep 8
  echo "Running status:"
  /usr/sbin/vmeasedaemon runningStatus --pretty
}

do_gpu_passthrough() {
  echo "TODO"
  return 0
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the webvirtcloud"
  echo "      upgrade                Upgrade the webvirtcloud"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the webvirtcloud"
  echo "      status                 webvirtcloud status"
  echo "      port                   webvirtcloud port"
}

# Read the exact container TCP binding, never another application's port.
# Empty success means no LAN-visible publication; failures stay failures.
do_entry_port() {
    local bindings address candidate extra port=''
    bindings=$(docker inspect --format '{{range (index .NetworkSettings.Ports "80/tcp")}}{{printf "%s %s\n" .HostIp .HostPort}}{{end}}' webvirtcloud) || return 1
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
    docker rm -f webvirtcloud
  ;;
  "start")
    /etc/init.d/vmease start
    sleep 1
    docker ${ACTION} webvirtcloud
  ;;
  "stop")
    docker ${ACTION} webvirtcloud
  ;;
  "restart")
    /etc/init.d/vmease start
    sleep 1
    docker ${ACTION} webvirtcloud
  ;;
  "status")
    docker ps --all -f 'name=^/webvirtcloud$' --format '{{.State}}'
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
