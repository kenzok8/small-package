#!/bin/sh
# EasyTier Firewall Management
# Manages firewall rules and network interfaces for EasyTier

# 引入工具函数
. /usr/share/easytier/utils.sh 2>/dev/null || true

# 添加单条防火墙规则
# 参数: $1=规则名称 $2=协议 $3=端口 $4=描述
add_firewall_rule() {
	local rule_name="$1"
	local proto="$2"
	local port="$3"
	local desc="$4"
	
	[ -z "$port" ] && return 1
	
	log_message "INFO" "easytier" "添加防火墙规则 ${rule_name} 放行端口 ${port}" "/tmp/easytier.log"
	
	uci -q delete "firewall.${rule_name}"
	uci set "firewall.${rule_name}=rule"
	uci set "firewall.${rule_name}.name=${rule_name}"
	uci set "firewall.${rule_name}.target=ACCEPT"
	uci set "firewall.${rule_name}.src=wan"
	uci set "firewall.${rule_name}.proto=${proto}"
	uci set "firewall.${rule_name}.dest_port=${port}"
	uci set "firewall.${rule_name}.enabled=1"
}

# 设置所有 EasyTier 防火墙规则
# 需要设置的变量: tcp_port, udp_port, ws_port, wss_port, wg_port, quic_port, socks_port
set_firewall_rules() {
	[ -n "$tcp_port" ] && add_firewall_rule "easytier_tcp_udp" "tcp udp" "$tcp_port" "EasyTier TCP/UDP"
	[ -n "$udp_port" ] && add_firewall_rule "easytier_udp" "udp" "$udp_port" "EasyTier UDP"
	[ -n "$ws_port" ] && add_firewall_rule "easytier_ws" "tcp" "$ws_port" "EasyTier WS"
	[ -n "$wss_port" ] && add_firewall_rule "easytier_wss" "tcp" "$wss_port" "EasyTier WSS"
	[ -n "$wg_port" ] && add_firewall_rule "easytier_wg" "udp" "$wg_port" "EasyTier WG"
	[ -n "$quic_port" ] && add_firewall_rule "easytier_quic" "tcp udp" "$quic_port" "EasyTier QUIC"
	[ -n "$socks_port" ] && add_firewall_rule "easytier_socks5" "tcp" "$socks_port" "EasyTier SOCKS5"
}

# 设置网络接口
# 参数: $1=接口名称 $2=IP地址(可选)
setup_network_interface() {
	local tunname="${1:-tun0}"
	local ipaddr="$2"
	
	uci -q delete network.EasyTier >/dev/null 2>&1
	
	if [ -z "$(uci -q get network.EasyTier)" ]; then
		uci set network.EasyTier='interface'
		if [ -z "$ipaddr" ]; then
			uci set network.EasyTier.proto='none'
		else
			uci set network.EasyTier.proto='static'
			uci set network.EasyTier.ipaddr="$ipaddr"
			uci set network.EasyTier.netmask='255.0.0.0'
		fi
		log_message "INFO" "easytier" "添加网络接口 EasyTier 绑定虚拟接口 ${tunname}" "/tmp/easytier.log"
		uci set network.EasyTier.device="$tunname"
		uci set network.EasyTier.ifname="$tunname"
	fi
}

# 设置防火墙区域
setup_firewall_zone() {
	if [ -z "$(uci -q get firewall.easytierzone)" ]; then
		log_message "INFO" "easytier" "添加防火墙规则，放行网络接口 EasyTier 允许出入转发，开启IP动态伪装 MSS钳制" "/tmp/easytier.log"
		uci set firewall.easytierzone='zone'
		uci set firewall.easytierzone.input='ACCEPT'
		uci set firewall.easytierzone.output='ACCEPT'
		uci set firewall.easytierzone.forward='ACCEPT'
		uci set firewall.easytierzone.masq='1'
		uci set firewall.easytierzone.mtu_fix='1'
		uci set firewall.easytierzone.name='EasyTier'
		uci set firewall.easytierzone.network='EasyTier'
	fi
}

# 设置转发规则
# 参数: $1=et_forward 配置值
setup_forwarding_rules() {
	local et_forward="$1"
	
	if [ "${et_forward#*etfwlan}" != "$et_forward" ]; then
		log_message "INFO" "easytier" "允许从虚拟网络 EasyTier 到局域网 lan 的流量" "/tmp/easytier.log"
		uci set firewall.easytierfwlan=forwarding
		uci set firewall.easytierfwlan.dest='lan'
		uci set firewall.easytierfwlan.src='EasyTier'
	else
		uci -q delete firewall.easytierfwlan
	fi
	
	if [ "${et_forward#*etfwwan}" != "$et_forward" ]; then
		log_message "INFO" "easytier" "允许从虚拟网络 EasyTier 到广域网 wan 的流量" "/tmp/easytier.log"
		uci set firewall.easytierfwwan=forwarding
		uci set firewall.easytierfwwan.dest='wan'
		uci set firewall.easytierfwwan.src='EasyTier'
	else
		uci -q delete firewall.easytierfwwan
	fi
	
	if [ "${et_forward#*lanfwet}" != "$et_forward" ]; then
		log_message "INFO" "easytier" "允许从局域网 lan 到虚拟网络 EasyTier 的流量" "/tmp/easytier.log"
		uci set firewall.lanfweasytier=forwarding
		uci set firewall.lanfweasytier.dest='EasyTier'
		uci set firewall.lanfweasytier.src='lan'
	else
		uci -q delete firewall.lanfweasytier
	fi
	
	if [ "${et_forward#*wanfwet}" != "$et_forward" ]; then
		log_message "INFO" "easytier" "允许从广域网 wan 到虚拟网络 EasyTier 的流量" "/tmp/easytier.log"
		uci set firewall.wanfweasytier=forwarding
		uci set firewall.wanfweasytier.dest='EasyTier'
		uci set firewall.wanfweasytier.src='wan'
	else
		uci -q delete firewall.wanfweasytier
	fi
}

# 清理所有 EasyTier 防火墙规则
clean_firewall_rules() {
	uci -q delete network.EasyTier >/dev/null 2>&1
	uci -q delete firewall.easytierzone >/dev/null 2>&1
	uci -q delete firewall.easytierfwlan >/dev/null 2>&1
	uci -q delete firewall.easytierfwwan >/dev/null 2>&1
	uci -q delete firewall.lanfweasytier >/dev/null 2>&1
	uci -q delete firewall.wanfweasytier >/dev/null 2>&1
	uci -q delete firewall.easytier_tcp >/dev/null 2>&1
	uci -q delete firewall.easytier_udp >/dev/null 2>&1
	uci -q delete firewall.easytier_tcp_udp >/dev/null 2>&1
	uci -q delete firewall.easytier_wss >/dev/null 2>&1
	uci -q delete firewall.easytier_ws >/dev/null 2>&1
	uci -q delete firewall.easytier_wg >/dev/null 2>&1
	uci -q delete firewall.easytier_quic >/dev/null 2>&1
	uci -q delete firewall.easytier_wireguard >/dev/null 2>&1
	uci -q delete firewall.easytier_socks5 >/dev/null 2>&1
	uci -q delete firewall.easytier_webserver >/dev/null 2>&1
	uci -q delete firewall.easytier_webapi >/dev/null 2>&1
	uci -q delete firewall.easytier_webhtml >/dev/null 2>&1
}

# 设置 Web 控制台防火墙规则
# 参数: $1=web_port $2=api_port $3=html_port $4=fw_web $5=fw_api
setup_web_firewall() {
	local web_port="$1"
	local api_port="$2"
	local html_port="$3"
	local fw_web="$4"
	local fw_api="$5"
	
	if [ -n "$web_port" ] && [ "$fw_web" = "1" ]; then
		log_message "INFO" "easytier" "添加防火墙规则 easytier_web 放行服务端口 ${web_port}" "/tmp/easytierweb.log"
		uci -q delete firewall.easytier_webserver
		uci set firewall.easytier_webserver=rule
		uci set firewall.easytier_webserver.name="easytier_webserver"
		uci set firewall.easytier_webserver.target="ACCEPT"
		uci set firewall.easytier_webserver.src="wan"
		uci set firewall.easytier_webserver.proto="tcp udp"
		uci set firewall.easytier_webserver.dest_port="$web_port"
		uci set firewall.easytier_webserver.enabled="1"
	fi
	
	if [ -n "$api_port" ] && [ "$fw_api" = "1" ]; then
		log_message "INFO" "easytier" "添加防火墙规则 easytier_web 放行API端口 ${api_port}" "/tmp/easytierweb.log"
		uci -q delete firewall.easytier_webapi
		uci set firewall.easytier_webapi=rule
		uci set firewall.easytier_webapi.name="easytier_webapi"
		uci set firewall.easytier_webapi.target="ACCEPT"
		uci set firewall.easytier_webapi.src="wan"
		uci set firewall.easytier_webapi.proto="tcp"
		uci set firewall.easytier_webapi.dest_port="$api_port"
		uci set firewall.easytier_webapi.enabled="1"
	fi
	
	if [ -n "$html_port" ] && [ "$fw_api" = "1" ] && [ "$html_port" != "$api_port" ]; then
		log_message "INFO" "easytier" "添加防火墙规则 easytier_web 放行html端口 ${html_port}" "/tmp/easytierweb.log"
		uci -q delete firewall.easytier_webhtml
		uci set firewall.easytier_webhtml=rule
		uci set firewall.easytier_webhtml.name="easytier_webhtml"
		uci set firewall.easytier_webhtml.target="ACCEPT"
		uci set firewall.easytier_webhtml.src="wan"
		uci set firewall.easytier_webhtml.proto="tcp"
		uci set firewall.easytier_webhtml.dest_port="$html_port"
		uci set firewall.easytier_webhtml.enabled="1"
	fi
}

# 应用防火墙和网络配置更改
apply_network_changes() {
	[ -n "$(uci changes network)" ] && uci commit network && /etc/init.d/network reload >/dev/null 2>&1
	[ -n "$(uci changes firewall)" ] && uci commit firewall && /etc/init.d/firewall reload >/dev/null 2>&1
}
