#!/bin/sh

script_file='/usr/share/natter2/natter-check/natter-check.py'
tmp_path=$(uci get natter2.@base[0].tmp_path)
[ ! "$tmp_path" ] && tmp_path="/tmp/natter2"

mkdir -p $tmp_path
rm -f /tmp/natter2_nat_type
rm -f $tmp_path/natter2_nat_type.tmp
python3 $script_file | egrep 'Checking TCP|Checking UDP' > $tmp_path/natter2_nat_type.tmp
TCP=$(awk -F '[:]+' '/TCP/{print $2}' $tmp_path/natter2_nat_type.tmp | sed 's/\[//g;s/\]//g')
UDP=$(awk -F '[:]+' '/UDP/{print $2}' $tmp_path/natter2_nat_type.tmp | sed 's/\[//g;s/\]//g')
rm -f $tmp_path/natter2_nat_type.tmp
[ ! "$TCP" ] && TCP="未知"
[ ! "$UDP" ] && UDP="未知"

echo "TCP: NAT $TCP" > /tmp/natter2_nat_type
echo "UDP: NAT $UDP" >> /tmp/natter2_nat_type
