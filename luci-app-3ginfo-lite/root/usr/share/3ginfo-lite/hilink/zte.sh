#!/bin/sh
#
# (c) 2010-2021 Cezary Jackiewicz <cezary@eko.one.pl>
#
# (c) 2021 modified by Rafał Wabik - IceG - From eko.one.pl forum
#

IP=$1
[ -z "$IP" ] && exit 0

T=$(mktemp)
wget -q -O $T "http://$IP/goform/goform_get_cmd_process?multi_data=1&cmd=manufacturer_name,model_name,network_provider,network_type,lte_rsrp,lte_rsrq,lte_rssi,lte_snr,cell_id,lac_code,hmcc,hmnc,rmcc,rmnc,rssi,rscp,ecio"

. /usr/share/libubox/jshn.sh
json_load "$(cat $T)"

json_get_vars manufacturer_name model_name network_provider network_type lte_rsrp lte_rsrq lte_rssi lte_snr cell_id lac_code hmcc hmnc rmcc rmnc rssi rscp ecio

if [ -n "$lte_rssi" ]; then
	RSSI=$lte_rssi
fi
if [ -n "$rssi" ]; then
	CSQ=$(((rssi+113)/2))
	CSQ_PER=$(($CSQ * 100/31))
else
	CSQ=0
	CSQ_PER=0
fi
echo "+CSQ: $CSQ,99"

MODEL=$manufacturer_name $model_name

MODE=$network_type

echo "^SYSINFOEX:x,x,x,x,,x,\"$network_type\",x,\"$network_type\""

if [ -n "$hmcc" ]; then
	COPS_MCC==$(printf "%03d" $hmcc)
else
	[ -n "$rmcc" ] && COPS_MCC==$(printf "%03d" $rmcc)
fi

if [ -n "$hmnc" ]; then
	COPS_MNC=$(printf "%02d" $hmnc)
else
	[ -n "$rmnc" ] && COPS_MNC=$(printf "%02d" $rmnc)
fi
echo "+COPS: 0,2,\"$mcc$mnc\",x"

if [ "x$network_type" = "xLTE" ]; then
	echo "^LTERSRP: $lte_rsrp,$lte_rsrq"
	RSRP=$lte_rsrp
	RSRQ=$lte_rsrq
else
	echo "^CSNR: $rscp,$ecio"
fi

echo "+CREG: 2,1,\"$lac_code\",\"$cell_id\""
CID_HEX=$cell_id
LAC_HEX=$lac_code

rm $T
