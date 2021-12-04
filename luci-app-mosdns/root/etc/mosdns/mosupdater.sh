#!/bin/bash -e
set -o pipefail
rm -rf  /tmp/mosdns
mkdir /tmp/mosdns
wget https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/geoip-only-cn-private.dat -nv -O /tmp/mosdns/geoip.dat
wget https://cdn.jsdelivr.net/gh/Loyalsoldier/domain-list-custom@release/geosite.dat -nv -O /tmp/mosdns/geosite.dat
find /tmp/mosdns/* -size -20k -exec rm {} \;
syncconfig=$(uci -q get mosdns.mosdns.syncconfig)
if [ $syncconfig -eq 1 ]; then
wget https://cdn.jsdelivr.net/gh/QiuSimons/openwrt-mos@master/luci-app-mosdns/root/etc/mosdns/config.yaml -nv -O /tmp/mosdns/config.yaml
find /tmp/mosdns/* -size -2k -exec rm {} \;
fi
chmod -R  755  /tmp/mosdns
cp -rf /tmp/mosdns/* /etc/mosdns
rm -rf  /tmp/mosdns
exit 0
