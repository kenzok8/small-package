#!/bin/sh

# run in router
APPNAME=$1

CURR=`pwd`
if [ -z "${APPNAME}" ]; then
  APPNAME=`basename "$CURR"|cut -d '-' -f 3`
fi

if [ -z "${APPNAME}" ]; then
  echo "please run in luci-app-xxx paths"
  exit 1
fi

if [ ! -d luasrc ]; then
  echo "luasrc not found, please run in luci-app-xxx paths"
  exit 1
fi

mkdir -p /usr/lib/lua/luci/view/${APPNAME}
cp ./luasrc/controller/${APPNAME}.lua /usr/lib/lua/luci/controller/
cp ./luasrc/view/${APPNAME}/* /usr/lib/lua/luci/view/${APPNAME}/
cp -rf ./luasrc/model/* /usr/lib/lua/luci/model/
cp -rf ./root/* /
rm -rf /tmp/luci-*

