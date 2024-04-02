#!/bin/sh
#
# (c) 2010-2021 Cezary Jackiewicz <cezary@eko.one.pl>
#
# (c) 2021 modified by Rafał Wabik - IceG - From eko.one.pl forum
#

IP=$1
[ -z "$IP" ] && exit 0
[ -e /usr/bin/wget ] || exit 0
getvaluen() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1 | sed 's/[^0-9]//g')
}

getvaluens() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1 | sed 's/[^0-9-]//g')
}

getvalue() {
	echo $(awk -F[\<\>] '/<'$2'>/ {print $3}' /tmp/$1)
}

cookie=$(mktemp)
/usr/bin/wget -t 25 -O /tmp/webserver-token "http://$IP/api/webserver/token" >/dev/null 2>&1
token=$(getvaluen webserver-token token)
if [ -z "$token" ]; then
	/usr/bin/wget -t 25 -O /tmp/webserver-token "http://$IP/api/webserver/SesTokInfo" >/dev/null 2>&1
	sesinfo=$(getvalue webserver-token SesInfo)
fi
if [ -z "$sesinfo" ]; then
	/usr/bin/wget -q -O /dev/null --keep-session-cookies --save-cookies $cookie "http://$IP/html/home.html"
fi

files="device/signal monitoring/status net/current-plmn net/signal-para device/information device/basic_information"
for f in $files; do
	nf=$(echo $f | sed 's!/!-!g')
	if [ -n "$token" ]; then
		/usr/bin/wget -t 3 -O /tmp/$nf "http://$IP/api/$f" --header "__RequestVerificationToken: $token" >/dev/null 2>&1
	elif [ -n "$sesinfo" ]; then
		/usr/bin/wget -t 3 -O /tmp/$nf "http://$IP/api/$f" --header "Cookie: $sesinfo" >/dev/null 2>&1
	else
		/usr/bin/wget -t 3 -O /tmp/$nf "http://$IP/api/$f" --load-cookies=$cookie >/dev/null 2>&1
	fi
done

# Protocol
# Driver=qmi_wwan & Driver=cdc_mbim & Driver=cdc_ether & Driver=huawei_cdc_ncm
PV=$(cat /sys/kernel/debug/usb/devices)
PVCUT=$(echo $PV | awk -F 'Vendor=12d1 ProdID=' '{print $2}' | cut -c-1108)
if echo "$PVCUT" | grep -q "Driver=qmi_wwan"
then
    PROTO="QMI"
elif echo "$PVCUT" | grep -q "Driver=cdc_mbim"
then
    PROTO="MBIM"
elif echo "$PVCUT" | grep -q "Driver=cdc_ether"
then
    PROTO="ECM"
elif echo "$PVCUT" | grep -q "Driver=huawei_cdc_ncm"
then
    PROTO="NCM"
fi

RSSI=$(getvaluen device-signal rssi)
if [ -n "$RSSI" ]; then
	CSQ=$(((-1*RSSI + 113)/2))
	CSQ_PER=$(($CSQ * 100/31))
else
	CSQ_PER=$(getvaluen monitoring-status SignalStrength)
	if [ -n "$CSQ_PER" ]; then
		CSQ=$((($CSQ_PER*31)/100))
	fi
fi

MODEN=$(getvaluen monitoring-status CurrentNetworkType)
case $MODEN in
	1)  MODE="GSM";;
	2)  MODE="GPRS";;
	3)  MODE="EDGE";;
	4)  MODE="WCDMA";;
	5)  MODE="HSDPA";;
	6)  MODE="HSUPA";;
	7)  MODE="HSPA";;
	8)  MODE="TDSCDMA";;
	9)  MODE="HSPA+";;
	10) MODE="EVDO rev. 0";;
	11) MODE="EVDO rev. A";;
	12) MODE="EVDO rev. B";;
	13) MODE="1xRTT";;
	14) MODE="UMB";;
	15) MODE="1xEVDV";;
	16) MODE="3xRTT";;
	17) MODE="HSPA+64QAM";;
	18) MODE="HSPA+MIMO";;
	19) MODE="LTE";;
	21) MODE="IS95A";;
	22) MODE="IS95B";;
	23) MODE="CDMA1x";;
	24) MODE="EVDO rev. 0";;
	25) MODE="EVDO rev. A";;
	26) MODE="EVDO rev. B";;
	27) MODE="Hybrydowa CDMA1x";;
	28) MODE="Hybrydowa EVDO rev. 0";;
	29) MODE="Hybrydowa EVDO rev. A";;
	30) MODE="Hybrydowa EVDO rev. B";;
	31) MODE="EHRPD rev. 0";;
	32) MODE="EHRPD rev. A";;
	33) MODE="EHRPD rev. B";;
	34) MODE="Hybrydowa EHRPD rev. 0";;
	35) MODE="Hybrydowa EHRPD rev. A";;
	36) MODE="Hybrydowa EHRPD rev. B";;
	41) MODE="WCDMA (UMTS)";;
	42) MODE="HSDPA";;
	43) MODE="HSUPA";;
	44) MODE="HSPA";;
	45) MODE="HSPA+";;
	46) MODE="DC-HSPA+";;
	61) MODE="TD SCDMA";;
	62) MODE="TD HSDPA";;
	63) MODE="TD HSUPA";;
	64) MODE="TD HSPA";;
	65) MODE="TD HSPA+";;
	81) MODE="802.16E";;
	101) MODE="LTE";;
	*)  MODE="-";;
esac

if [ "x$MODE" = "xLTE" ]; then
	RSRP=$(getvaluens device-signal rsrp)
	SINR=$(getvaluens device-signal sinr)
	RSRQ=$(getvaluens device-signal rsrq)
fi

MODEL=$(getvalue device-information DeviceName)
if [ -n "$MODEL" ]; then
	class=$(getvalue device-information Classify)
	MODEL="Huawei $MODEL ($class)"
else
	MODEL=$(getvalue device-basic_information devicename)
	class=$(getvalue device-basic_information classify)
	[ -n "$MODEL" ] && MODEL="Huawei $MODEL ($class)"
fi

FW=$(getvalue device-information SoftwareVersion)
if [ -n "$FW" ]; then
	rev=$(getvalue device-information HardwareVersion)
	FW="$rev / $FW"
fi

COPSA=$(getvaluen net-current-plmn Numeric)
COPSB=$(echo "${COPSA}" | cut -c1-3)
COPSC=$(echo -n $COPSA | tail -c 2)
COPS_MCC="$COPSB"
COPS_MNC="$COPSC"

COPS=$(getvalue net-current-plmn ShortName)

LAC_HEX=$(getvalue net-signal-para Lac)
if [ -z "$LAC_HEX" ]; then
	/usr/bin/wget -t 3 -O /tmp/add-param "http://$IP/config/deviceinformation/add_param.xml" > /dev/null 2>&1
	LAC_HEX=$(getvalue add-param lac)
	rm /tmp/add-param
fi
if [ -z "$LAC_HEX" ]
then
	LAC_HEX='-'
fi

CID_HEX=$(getvalue net-signal-para CellID)
if [ -z "$CID_HEX" ]; then
	CID_HEX=$(getvalue device-signal cell_id)
	[ -n "$CID_HEX" ] && CID_HEX=$(printf %0X $CID_HEX)
fi

if [ -z "$CID_HEX" ]
then
	CID_HEX='-'
fi

rm $cookie
break
