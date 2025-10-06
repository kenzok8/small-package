#!/bin/sh

sectionname=$(echo $0 | cut -d '_' -f 2 | sed 's/^OO!%!OO//')
getcmac=$(uci get banmac.$sectionname.banlist_mac | tr 'A-Z' 'a-z')
iptables -D FORWARD -m mac --mac-source $getcmac -j DROP

sed -i "s/$(cat /etc/banmaclog | grep $getcmac | head -n 1)//;/^\s*$/d" /etc/banmaclog
