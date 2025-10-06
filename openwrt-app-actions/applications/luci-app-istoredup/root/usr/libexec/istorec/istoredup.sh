#!/bin/sh

ACTION=${1}
shift 1

do_install() {
  local IMAGE_NAME=`uci get istoredup.@istoredup[0].image_name 2>/dev/null`
  local arch=`uname -m`
  if [ "$arch" = "x86_64" -o "$arch" = "aarch64" ]; then 
    echo "${arch} supported"
  else
    echo "Unsupported ${arch} NOW"
    sleep 10
    exit 1
  fi

  if [ -z ${IMAGE_NAME} ]; then
    if [ "$arch" = "x86_64" ]; then
      IMAGE_NAME=linkease/istoredupx86_64:latest
    else
      IMAGE_NAME=linkease/istoreduprk35xx:latest
    fi
  fi

  echo "docker pull ${IMAGE_NAME}"
  docker pull ${IMAGE_NAME}
  docker rm -f istoredup

  local hasvlan=`docker network inspect dsm-net -f '{{.Name}}' 2>/dev/null`
  if [ ! "$hasvlan" = "dsm-net" ]; then
    docker network create -o com.docker.network.bridge.name=dsm-br --driver=bridge dsm-net
  fi
  local mask=`ubus call network.interface.lan status | jsonfilter -e '@["ipv4-address"][0].mask'`

  local cmd="docker run --restart=unless-stopped -d \
    -h iStoreDuplica \
    -v /var/run/vmease:/host/run/vmease \
    --privileged \
    --net=dsm-net \
    --sysctl net.netfilter.nf_conntrack_acct=1 \
    --sysctl net.ipv4.conf.all.forwarding=1 \
    --dns=172.17.0.1 "

  cmd="$cmd -v /mnt:/mnt"
  mountpoint -q /mnt && cmd="$cmd:rslave"
  cmd="$cmd --stop-timeout 120 --name istoredup \"$IMAGE_NAME\""

  echo "$cmd"
  eval "$cmd"
  echo "wait running"
  sleep 5
  echo "done"
}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the istoredup"
  echo "      upgrade                Upgrade the istoredup"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the istoredup"
  echo "      status                 iStoreDup status"
  echo "      port                   iStoreDup port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f istoredup
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} istoredup
  ;;
  "status")
    docker ps --all -f 'name=^/istoredup$' --format '{{.State}}'
  ;;
  "port")
    docker exec istoredup ip -f inet addr show br-lan|sed -En -e 's/.*inet ([0-9.]+).*/\1/p'
  ;;
  "show-ip")
    IP=`docker exec istoredup ip -f inet addr show br-lan|sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`
    if [ -z "$IP" ]; then
      echo "reset ip"
      docker exec istoredup /etc/init.d/setupvmease start
      sleep 5
      IP=`docker exec istoredup ip -f inet addr show br-lan|sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`
    fi
    echo $IP
  ;;
  *)
    usage
    exit 1
  ;;
esac
