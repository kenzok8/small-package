#!/bin/sh

sectionname=$(echo $0 | cut -d '_' -f 2 | sed 's/^OO!%!OO//')
getcmac=$(uci get banmac.$sectionname.banlist_mac | tr 'A-Z' 'a-z')
iptables -I FORWARD -m mac --mac-source $getcmac -j DROP
hostname=$(grep -n $getcmac /tmp/dhcp.leases | cut -d ' ' -f 4)
hostip=$(grep -n $getcmac /tmp/dhcp.leases | cut -d ' ' -f 3)
echo "★禁网设备：$hostname($hostip) MAC地址：$getcmac 操作日期：$(date +%Y年%m月%d日\ %H点%M分%S秒)" >> /etc/banmaclog

for i in $(seq 0 1);do
	for j in $(seq 0 1);do
		for x in $(iw dev phy${i}-ap${j} station dump | grep -i station | awk '{print$2}');do
			if [ $x = $getcmac ]; then
				iw dev phy${i}-ap${j} station del $x
			fi
		done
	done
done
