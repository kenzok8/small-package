#!/bin/sh
# Author Xiaobao(xiaobao@linkease.com)

ACTION=${1}
WRLOCK=/var/lock/ubuntu.lock
LOGFILE=/var/log/ubuntu.log
LOGEND="XU6J03M6"
shift 1

IMAGE_NAME=''
# linkease/desktop-ubuntu-full-arm64:latest
# linkease/desktop-ubuntu-standard-arm64:latest
# linkease/desktop-ubuntu-full-amd64:latest
# linkease/desktop-ubuntu-standard-amd64:latest

check_params() {

  if [ -z "${WRLOCK}" ]; then
    echo "lock file not found"
    exit 1
  fi

  if [ -z "${LOGFILE}" ]; then
    echo "logger file not found"
    exit 1
  fi

}

lock_run() {
  local lock="$WRLOCK"
  exec 300>$lock
  flock -n 300 || return
  do_run
  flock -u 300
  return
}

run_action() {
  if check_params; then
    lock_run
  fi
}

get_image() {
  local version=`uci get ubuntu.@ubuntu[0].version 2>/dev/null`
  
  ARCH="arm64"
  if echo `uname -m` | grep -Eqi 'x86_64'; then
    ARCH='amd64'
  elif  echo `uname -m` | grep -Eqi 'aarch64'; then
    ARCH='arm64'
  else
    ARCH='arm64'
  fi

  IMAGE_NAME=linkease/desktop-ubuntu-${version}-${ARCH}:latest
}

do_install() {
  local PASSWORD=`uci get ubuntu.@ubuntu[0].password 2>/dev/null`
  local PORT=`uci get ubuntu.@ubuntu[0].port 2>/dev/null`
  [ -z "$PASSWORD" ] && PASSWORD="password"
  [ -z "$PORT" ] && PORT=6901
  echo "docker create pcnet" >${LOGFILE}
  local mntv="/mnt:/mnt"
  mountpoint -q /mnt && mntv="$mntv:rslave"
  get_image
  echo "docker pull ${IMAGE_NAME}" >>${LOGFILE}
  docker pull ${IMAGE_NAME} >>${LOGFILE} 2>&1
  docker rm -f ubuntu

  #  --net="docker-pcnet" \

  docker run -d --name ubuntu \
   --dns=223.5.5.5 -u=0:0 \
    -v=${mntv} \
    --shm-size=512m \
    -p ${PORT}:6901 \
    -e VNC_PW=${PASSWORD} \
    -e VNC_USE_HTTP=0 \
    --restart unless-stopped \
    $IMAGE_NAME >>${LOGFILE} 2>&1

  RET=$?
  if [ "${RET}" = "0" ]; then
    # mark END, remove the log file
    echo ${LOGEND} >> ${LOGFILE}
    sleep 5
    rm -f ${LOGFILE}
  else
    # reserve the log
    echo "docker run ${IMAGE_NAME} failed" >>${LOGFILE}
    echo ${LOGEND} >> ${LOGFILE}
  fi
  exit ${RET}
}

# run in lock
do_run() {
  case ${ACTION} in
    "install")
      do_install
    ;;
    "upgrade")
      do_install
    ;;
  esac
}

usage() {
  echo "usage: wxedge sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the ubuntu"
  echo "      upgrade                Upgrade the ubuntu"
  echo "      remove                 Remove the ubuntu"
}

case ${ACTION} in
  "install")
    run_action
  ;;
  "upgrade")
    run_action
  ;;
  "remove")
    docker rm -f ubuntu
  ;;
  *)
    usage
  ;;
esac

