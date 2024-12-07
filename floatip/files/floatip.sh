#!/bin/sh

# random number 0-255
random() {
	local num=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null | hexdump -ve '1/1 "%u"')
	if [[ -z "$num" ]]; then
		num=$(($(grep -om1 '[0-9][0-9]$' /proc/uptime) * 255 / 100))
	fi
	echo ${num:-1}
}

host_alive() {
	ping -4 -c 2 -A -t 1 -W 1 -q "$1" >/dev/null
}

set_up() {
	local ipaddr="$1"
	echo "set my floatip to $ipaddr" >&2
	if ! uci -q get network.floatip.ipaddr | grep -Fwq $ipaddr; then
		if [[ "x$(uci -q get network.floatip)" = xinterface ]]; then
			uci -q batch <<-EOF >/dev/null
				delete network.floatip.ipaddr
				add_list network.floatip.ipaddr=$ipaddr
			EOF
		else
			uci -q batch <<-EOF >/dev/null
				set network.floatip=interface
				set network.floatip.proto=static
				add_list network.floatip.ipaddr=$ipaddr
				set network.floatip.device=br-lan
				set network.floatip.auto=0
			EOF
		fi
		uci commit network
	fi
	ifup floatip
}

. /lib/functions.sh

fallback_loop() {
	local set_ip check_ip set_net set_prefix
	config_get set_ip "main" set_ip
	config_get check_ip "main" check_ip
	eval "$(ipcalc.sh "$set_ip" )";set_net=$NETWORK;set_prefix=$PREFIX;set_ip=$IP
	[[ "$set_net" = 0.0.0.0 ]] && set_net=192.168.100.0
	[[ "$set_prefix" = 0 ]] && set_prefix=24
	[[ "$set_ip" = 0.0.0.0 ]] && set_ip=192.168.100.3
	local ipaddr="$set_ip/$set_prefix"
	local valid_check_ip cip
	for cip in $check_ip; do
		eval "$(ipcalc.sh $cip $set_prefix )"
		[[ "$NETWORK" = "$set_net" ]] && valid_check_ip="$valid_check_ip $cip"
	done
	valid_check_ip="$valid_check_ip "

	local order_check_ip="$valid_check_ip"
	local found_alive consume_time
	local dead_counter=0 floatip_up=0
	while :; do
		found_alive=0
		consume_time=0
		echo "checking host(s) $order_check_ip alive"
		for cip in $order_check_ip; do
			if host_alive $cip; then
				echo "host $cip alive"
				found_alive=1
				# reorder to reduce check time
				order_check_ip=" ${cip}${valid_check_ip// $cip / }"
				break
			fi
			consume_time=$(($consume_time + 2))
		done
		if [[ $found_alive = 1 ]]; then
			if [[ $floatip_up = 1 ]]; then
				echo "set down floatip" >&2
				ifdown floatip
				floatip_up=0
			else
				dead_counter=0
			fi
			[[ $consume_time -lt 10 ]] && sleep $((10 - $consume_time))
			continue
		fi
		if [[ $floatip_up = 1 ]]; then
			[[ $consume_time -lt 5 ]] && sleep $((5 - $consume_time))
			continue
		fi
		dead_counter=$(($dead_counter + 1))
		if [[ $dead_counter -lt 3 ]]; then
			[[ $consume_time -lt 10 ]] && sleep $((10 - $consume_time))
			continue
		fi
		echo "no host alive, set up floatip $ipaddr"
		set_up "$ipaddr"
		floatip_up=1
		sleep 5
	done
}

main_loop() {
	local set_ip set_net set_prefix
	config_get set_ip "main" set_ip
	eval "$(ipcalc.sh "$set_ip" )";set_net=$NETWORK;set_prefix=$PREFIX;set_ip=$IP
	[[ "$set_net" = 0.0.0.0 ]] && set_net=192.168.100.0
	[[ "$set_prefix" = 0 ]] && set_prefix=24
	[[ "$set_ip" = 0.0.0.0 ]] && set_ip=192.168.100.3
	local ipaddr="$set_ip/$set_prefix"
	while :; do
		# sleep 2-6s
		sleep $(( random / 60 + 2))
		echo "checking host $set_ip alive"
		if host_alive $set_ip; then
			echo "host $set_ip alive"
			continue
		fi
		echo "no host alive, set up floatip $ipaddr"
		set_up "$ipaddr"
		break
	done
}

main() {
	local role
	config_load floatip
	config_get role "main" role
	if [[ "$role" = "main" ]]; then
		main_loop
	elif  [[ "$role" = "fallback" ]]; then
		fallback_loop
	fi
}

main
