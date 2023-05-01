#!/bin/sh
# Copyright 2020-2023 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.

chmod +x /etc/init.d/smsled 2>&1 &
chmod +x /sbin/smsled-init.sh 2>&1 &
chmod +x /sbin/cronsync.sh 2>&1 &
chmod +x /sbin/set_sms_ports.sh 2>&1 &
chmod +x /sbin/smsled.sh 2>&1 &
rm -rf /tmp/luci-indexcache 2>&1 &
rm -rf /tmp/luci-modulecache/ 2>&1 &

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
uci set sms_tool.@sms_tool[0].readport=$work 2>&1 &
uci set sms_tool.@sms_tool[0].sendport=$work 2>&1 &
uci set sms_tool.@sms_tool[0].ussdport=$work 2>&1 &
uci set sms_tool.@sms_tool[0].atport=$work 2>&1 &
uci commit sms_tool 2>&1 &
fi

DEVICE=$(cat /tmp/sysinfo/board_name)

if [[ "$DEVICE" == *"mf289f"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1" 2>&1 &
		uci commit sms_tool 2>&1 &

fi
	
if [[ "$DEVICE" == *"mf286r"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyACM0" 2>&1 &
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyACM0" 2>&1 &
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyACM0" 2>&1 &
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyACM0" 2>&1 &
		uci commit sms_tool 2>&1 &

fi

if [[ "$DEVICE" == *"mf286d"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1" 2>&1 &
		uci commit sms_tool 2>&1 &

fi

if [[ "$DEVICE" == *"mf286"* ]]; then
	
		uci set sms_tool.@sms_tool[0].readport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].sendport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].ussdport="/dev/ttyUSB1" 2>&1 &
		uci set sms_tool.@sms_tool[0].atport="/dev/ttyUSB1" 2>&1 &
		uci commit sms_tool 2>&1 &

fi
