#!/bin/sh
# Copyright 2020-2021 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.

chmod +x /sbin/cronsync.sh
chmod +x /sbin/set_sms_ports.sh
chmod +x /sbin/smsled-init.sh
chmod +x /sbin/smsled.sh
rm -rf /tmp/luci-indexcache
rm -rf /tmp/luci-modulecache/

work=false
for port in /dev/ttyUSB*
do
    [[ -e $port ]] || continue
    gcom -d $port info &> /tmp/testusb
    testUSB=`cat /tmp/testusb | grep "Error\|Can't"`
    if [ -z "$testUSB" ]; then 
        work=$port
        break
    fi
done
rm -rf /tmp/testusb

if [ $work != false ]; then
uci set sms_tool.@sms_tool[0].readport=$work
uci set sms_tool.@sms_tool[0].sendport=$work
uci set sms_tool.@sms_tool[0].ussdport=$work
uci set sms_tool.@sms_tool[0].atport=$work
uci commit sms_tool
fi

DEVICE=$(cat /tmp/sysinfo/board_name)

if [[ "$DEVICE" == *"mf289f"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1"
		uci commit sms_tool

fi
	
if [[ "$DEVICE" == *"mf286r"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyACM0"
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyACM0"
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyACM0"
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyACM0"
		uci commit sms_tool

fi

if [[ "$DEVICE" == *"mf286d"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1"
		uci commit sms_tool

fi

if [[ "$DEVICE" == *"mf286"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1"
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1"
		uci commit sms_tool

fi
