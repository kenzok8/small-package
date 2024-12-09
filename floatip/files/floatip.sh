#!/bin/sh

DEFAULT_PREFIX=24

# random number 0-255
random() {
	local num=$(dd if=/dev/urandom bs=1 count=1 2>/dev/null | hexdump -ve '1/1 "%u"')
	if [[ -z "$num" ]]; then
		num=$(($(grep -om1 '[0-9][0-9]$' /proc/uptime) * 255 / 100))
	fi
	echo ${num:-1}
}

# check host alive, timeout in 2 seconds
host_alive() {
	ping -4 -c 2 -A -t 1 -W 1 -q "$1" >/dev/null
	# arping -f -q -b -c 2 -w 2 -i 1 -I br-lan "$1"
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

set_lan_ping() {
	if [[ "$1" = 0 ]]; then
		if [[ "x$(uci -q get firewall.floatip_lan_offline)" = xrule ]]; then
			uci -q delete firewall.floatip_lan_offline.enabled
			uci changes | grep -Fq 'firewall.floatip_lan_offline.enabled' || return 0
		else
			uci -q batch <<-EOF >/dev/null
				set firewall.floatip_lan_offline=rule
				set firewall.floatip_lan_offline.name=FloatIP-LAN-Offline
				set firewall.floatip_lan_offline.src=lan
				set firewall.floatip_lan_offline.proto=icmp
				set firewall.floatip_lan_offline.icmp_type=echo-request
				set firewall.floatip_lan_offline.family=ipv4
				set firewall.floatip_lan_offline.target=DROP
			EOF
		fi
	else
		uci -q set firewall.floatip_lan_offline.enabled=0 || return 0
		uci changes | grep -Fq 'firewall.floatip_lan_offline.enabled' || return 0
	fi
	uci commit firewall
	/etc/init.d/firewall reload 2>&1
}

safe_sleep() {
	local sec="$1"
	[[ "$sec" -lt 1 ]] && sec=1
	sleep $sec
}

. /lib/functions.sh

fallback_loop() {
	local set_ip check_ip set_net set_prefix
	config_get set_ip "main" set_ip
	[[ -n "$set_ip" ]] || return 1
	[[ "$set_ip" = "*/*" ]] || set_ip="$set_ip/$DEFAULT_PREFIX"
	eval "$(ipcalc.sh "$set_ip" )";set_net=$NETWORK;set_prefix=$PREFIX;set_ip=$IP
	local ipaddr="$set_ip/$set_prefix"
	echo "ipaddr=$ipaddr"

	local valid_check_ip cip
	config_get check_ip "main" check_ip
	for cip in $check_ip; do
		eval "$(ipcalc.sh $cip/$set_prefix )"
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
			safe_sleep $((10 - $consume_time))
			continue
		fi
		if [[ $floatip_up = 1 ]]; then
			safe_sleep $((5 - $consume_time))
			continue
		fi
		dead_counter=$(($dead_counter + 1))
		if [[ $dead_counter -lt 3 ]]; then
			safe_sleep $((10 - $consume_time))
			continue
		fi
		echo "no host alive, set up floatip $ipaddr" >&2
		set_up "$ipaddr"
		floatip_up=1
		sleep 5
	done
}

main_loop() {
	local set_ip set_prefix
	config_get set_ip "main" set_ip
	[[ -n "$set_ip" ]] || return 1
	[[ "$set_ip" = "*/*" ]] || set_ip="$set_ip/$DEFAULT_PREFIX"
	eval "$(ipcalc.sh "$set_ip" )";set_prefix=$PREFIX;set_ip=$IP
	local ipaddr="$set_ip/$set_prefix"
	echo "ipaddr=$ipaddr"

	local check_urls check_url_timeout
	config_get check_urls "main" check_url
	config_get check_url_timeout "main" check_url_timeout '5'
	local dead_counter=0 floatip_up=0 url_pass check_url curl_code consume_time found_alive
	# sleep 2-6s
	sleep $(( $(random) / 60 + 2))
	while :; do
		consume_time=0
		if [[ $floatip_up = 0 ]]; then
			found_alive=0
			echo "checking host $set_ip alive"
			if host_alive $set_ip; then
				echo "host $set_ip alive"
				found_alive=1
			else
				consume_time=$(($consume_time + 2))
			fi
		fi
		url_pass=1
		for check_url in $check_urls ; do
			curl -L --fail --show-error --no-progress-meter -o /dev/null \
				--connect-timeout "$check_url_timeout" --max-time "$check_url_timeout" \
				-I "$check_url" 2>&1
			curl_code=$?
			[[ $curl_code = 0 ]] && continue
			[[ $curl_code = 6 || $curl_code = 7 || $curl_code = 28 ]] && \
				consume_time=$(($consume_time + $check_url_timeout))
			echo "check_url $check_url fail, code $curl_code"
			url_pass=0
			break
		done
		if [[ $floatip_up = 0 ]]; then
			if [[ $url_pass = 1 ]]; then
				# notify fallback node to offline
				set_lan_ping
				if [[ $found_alive = 0 ]]; then
					echo "no host alive, and url passed, set up floatip $ipaddr" >&2
					set_up "$ipaddr"
					floatip_up=1
				fi
			else
				set_lan_ping 0
			fi
			safe_sleep $((5 - $consume_time))
			continue
		else
			if [[ $url_pass = 0 ]]; then
				dead_counter=$(($dead_counter + 1))
				if [[ $dead_counter -lt 3 ]]; then
					safe_sleep $((5 - $consume_time))
					continue
				fi
				echo "set down floatip, and disable ping" >&2
				ifdown floatip
				set_lan_ping 0
				floatip_up=0
			fi
			dead_counter=0
		fi
		sleep 20
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

if [[ -n "$1" ]]; then
	[[ "$1" -ge 0 && "$1" -lt 32 ]] && DEFAULT_PREFIX=$1
fi

main
