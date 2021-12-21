#!/bin/bash -e
wanstatus=$(ifconfig | grep wan)
if [ -z "$wanstatus" ]; then
  echo "101.226.4.6"
fi
DNS1=`ubus call network.interface.wan status | jsonfilter -e '@["dns-server"][1]'`
if [[ $DNS1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "$DNS1"
else
  echo "101.226.4.6"
fi
