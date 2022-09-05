#!/bin/sh

# run in router
APPNAME=$1

if [ -z "${APPNAME}" ]; then
  APPNAME=ubuntu
fi

mkdir -p /usr/lib/lua/luci/view/${APPNAME}
cp ./luasrc/controller/${APPNAME}.lua /usr/lib/lua/luci/controller/
cp ./luasrc/view/${APPNAME}/* /usr/lib/lua/luci/view/${APPNAME}/
cp -rf ./root/* /
rm -rf /tmp/luci-*

