#!/bin/sh

#
# (c) 2024-2025 Cezary Jackiewicz <cezary@eko.one.pl>
#

. /lib/functions.sh

RES="/usr/share/modemdata"
ECM=""

SEPARATOR=""
parse_section() {
	[ -n "$SEPARATOR" ] && echo "$SEPARATOR"
	local section="$1"
	config_get device "$section" device ""
	config_get network "$section" network ""
	config_get force_plmn "$section" force_plmn "0"

	if echo "x$device" | grep -q "192.168."; then
		ECM="$RES/addon/ecm/huawei.sh $device"
	else
		ECM=""
		if [ ! -e /var/state/3ginfo-detected ]; then
			[ -z "$device" ] && device=$(/usr/share/3ginfo/detectdevice.sh)
			[ -z "$network" ] && network=$(/usr/share/3ginfo/detectsection.sh "$section")
		fi
		config_get pincode "$section" pincode ""
		if [ -n "$pincode" ] && [ ! -e /var/state/3ginfo-pincode ]; then
			[ -n "$device" ] && sms_tool -d "$device" at "at+cpin=\"$pincode\""
		fi
	fi
	echo "["
	$RES/network.sh "$network" | tr -d '\n'
	echo ","
	if [ -n "$ECM" ]; then
		$ECM params
	else
		$RES/params.sh "$device" "$force_plmn" | tr -d '\n'
	fi
	echo "]"
	SEPARATOR=","
}

config_load 3ginfo
echo -e "Content-type: application/json\n\n"
echo '{"res":['
config_foreach parse_section 3ginfo
echo ']}'
touch /var/state/3ginfo-detected
touch /var/state/3ginfo-pincode

exit 0
