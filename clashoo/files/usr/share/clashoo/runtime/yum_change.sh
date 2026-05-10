#!/bin/sh

[ -n "$(echo $SHELL)" ] && export SHELL=/bin/sh

# Source OpenWrt UCI shell API (config_load/config_foreach/config_get etc.)
. /lib/functions.sh 2>/dev/null || true

# Source DNS helper functions (dns_yaml_list_item, dns_normalize_server, etc.)
_YUM_DIR="$(dirname "$0" 2>/dev/null)"
[ -n "$_YUM_DIR" ] && [ -f "$_YUM_DIR/dns_helpers.sh" ] && . "$_YUM_DIR/dns_helpers.sh"

# 自定义/上传配置（config_type=2 上传, 3 自定义）跳过 yum_change.sh，
# 保留 proxy-providers/proxies/rules 等完整不动。只添加运行时必需字段。
_config_type=$(uci get clashoo.config.config_type 2>/dev/null)
if [ "$_config_type" = "2" ] || [ "$_config_type" = "3" ]; then
	CONFIG_YAML="/etc/clashoo/config.yaml"

	# --- 运行时字段注入 ---
	_dash_port=$(uci get clashoo.config.dash_port 2>/dev/null)
	[ -z "$_dash_port" ] && _dash_port=9090
	_da_password=$(uci get clashoo.config.dash_pass 2>/dev/null)
	_safe_password=$(printf '%s' "$_da_password" | sed 's/[\/&]/\\&/g')
	_http_port=$(uci get clashoo.config.http_port 2>/dev/null)
	[ -z "$_http_port" ] && _http_port=8080
	_socks_port=$(uci get clashoo.config.socks_port 2>/dev/null)
	[ -z "$_socks_port" ] && _socks_port=1080
	_redir_port=$(uci get clashoo.config.redir_port 2>/dev/null)
	[ -z "$_redir_port" ] && _redir_port=7891
	_mixed_port=$(uci get clashoo.config.mixed_port 2>/dev/null)
	[ -z "$_mixed_port" ] && _mixed_port=7890
	_allow_lan=$(uci get clashoo.config.allow_lan 2>/dev/null)
	[ "$_allow_lan" = "1" ] && _allow_lan=true || _allow_lan=false
	[ -z "$_allow_lan" ] && _allow_lan=true
	_mode=$(uci get clashoo.config.p_mode 2>/dev/null)
	[ -z "$_mode" ] && _mode=rule
	[ "$_mode" = "script" ] && _mode=rule
	_log_level=$(uci get clashoo.config.level 2>/dev/null)
	[ -z "$_log_level" ] && _log_level=info
	_tun_mode=$(uci get clashoo.config.tun_mode 2>/dev/null)
	_core_type=$(uci get clashoo.config.core_type 2>/dev/null)
	_stack=$(uci get clashoo.config.stack 2>/dev/null)
	[ -z "$_stack" ] && _stack=system

	# 字段替换/前置（存在则 sed 替换，不存在则 1i\ 前置）
	if grep -Eq '^port:' "$CONFIG_YAML"; then
		sed -i "s@^port:.*@port: $_http_port@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\port: $_http_port" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^socks-port:' "$CONFIG_YAML"; then
		sed -i "s@^socks-port:.*@socks-port: $_socks_port@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\socks-port: $_socks_port" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^redir-port:' "$CONFIG_YAML"; then
		sed -i "s@^redir-port:.*@redir-port: $_redir_port@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\redir-port: $_redir_port" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^mixed-port:' "$CONFIG_YAML"; then
		sed -i "s@^mixed-port:.*@mixed-port: $_mixed_port@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\mixed-port: $_mixed_port" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^allow-lan:' "$CONFIG_YAML"; then
		sed -i "s@^allow-lan:.*@allow-lan: $_allow_lan@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\allow-lan: $_allow_lan" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^mode:' "$CONFIG_YAML"; then
		sed -i "s@^mode:.*@mode: $_mode@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\mode: $_mode" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^log-level:' "$CONFIG_YAML"; then
		sed -i "s@^log-level:.*@log-level: $_log_level@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\log-level: $_log_level" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^external-controller:' "$CONFIG_YAML"; then
		sed -i "s@^external-controller:.*@external-controller: 0.0.0.0:$_dash_port@g" "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\external-controller: 0.0.0.0:$_dash_port" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^secret:' "$CONFIG_YAML"; then
		sed -i 's@^secret:.*@secret: "'"$_safe_password"'"@g' "$CONFIG_YAML" 2>/dev/null
	else
		sed -i "1i\secret: \"$_safe_password\"" "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^external-ui:' "$CONFIG_YAML"; then
		sed -i 's@^external-ui:.*@external-ui: "./dashboard"@g' "$CONFIG_YAML" 2>/dev/null
	else
		sed -i '1i\external-ui: "./dashboard"' "$CONFIG_YAML" 2>/dev/null
	fi
	if grep -Eq '^routing-mark:' "$CONFIG_YAML"; then
		sed -i 's@^routing-mark:.*@routing-mark: 6666@g' "$CONFIG_YAML" 2>/dev/null
	else
		sed -i '1i\routing-mark: 6666' "$CONFIG_YAML" 2>/dev/null
	fi

	if [ "${_tun_mode:-0}" -eq 1 ] && [ "$_core_type" != "singbox" ]; then
		awk '
			/^tun:/ { skip=1; next }
			skip && /^[^[:space:]#][^:]*:/ { skip=0 }
			!skip { print }
		' "$CONFIG_YAML" > /tmp/_clashoo_tun.yaml 2>/dev/null && mv /tmp/_clashoo_tun.yaml "$CONFIG_YAML"
		cat >> "$CONFIG_YAML" <<-TUN_EOF

		tun:
		  enable: true
		  stack: ${_stack}
		  auto-route: true
		  auto-redirect: true
		  auto-detect-interface: true
		  dns-hijack:
		    - any:53
		    - tcp://any:53
		TUN_EOF
	elif grep -Eq '^tun:' "$CONFIG_YAML"; then
		awk '/^tun:/{f=1} f && /enable:/{sub(/enable:.*/, "enable: false"); f=0} {print}' "$CONFIG_YAML" > /tmp/_clashoo_tun.yaml 2>/dev/null && mv /tmp/_clashoo_tun.yaml "$CONFIG_YAML"
	fi

	# 提取 provider URL 域名 -> 构造 fake-ip-filter 条目
	_fip_entries=""
	while IFS= read -r _url_line; do
		_url=$(printf '%s' "$_url_line" | sed "s/.*url: *\"//; s/\"//")
		_domain=$(printf '%s' "$_url" | sed -n 's#.*https\?://\([^/]*\).*#\1#p')
		if [ -n "$_domain" ]; then
			_fip_entries="${_fip_entries}    - \"${_domain}\"
"
		fi
	done <<-EOT
		$(grep -E '^\s+url:.*https?://' "$CONFIG_YAML" | grep -v 'generate_204\|raw\.githubusercontent\.com')
	EOT

	# 若配置无 dns 段，追加含 fake-ip-filter 的 DNS 块
	if ! grep -Eq '^dns:' "$CONFIG_YAML"; then
		_listen_port=$(uci get clashoo.config.listen_port 2>/dev/null)
		[ -z "$_listen_port" ] && _listen_port=1053
		_enhanced_mode=$(uci get clashoo.config.enhanced_mode 2>/dev/null)
		[ -z "$_enhanced_mode" ] && _enhanced_mode=fake-ip
		_default_ns=$(uci get clashoo.config.default_nameserver 2>/dev/null)
		[ -z "$_default_ns" ] && _default_ns="223.5.5.5 119.29.29.29"

		cat >> "$CONFIG_YAML" <<-DNS_EOF

		dns:
		  enable: true
		  listen: 0.0.0.0:${_listen_port}
		  enhanced-mode: ${_enhanced_mode}
		DNS_EOF
			# fake-ip-filter 插入 dns: 块内部
			if [ -n "$_fip_entries" ]; then
				echo "  fake-ip-filter:" >> "$CONFIG_YAML"
				printf '%s' "$_fip_entries" >> "$CONFIG_YAML"
			fi
		cat >> "$CONFIG_YAML" <<-DNS_EOF
		  default-nameserver:
		DNS_EOF
		for _ns in $_default_ns; do
			echo "    - '$_ns'" >> "$CONFIG_YAML"
		done
		cat >> "$CONFIG_YAML" <<-DNS_EOF
		  nameserver:
		    - 'https://doh.pub/dns-query'
		    - 'https://dns.alidns.com/dns-query'
		DNS_EOF
	else
		# dns 段已存在但缺少 fake-ip-filter -> 追加
		if ! grep -Eq '^\s+fake-ip-filter:' "$CONFIG_YAML"; then
			if [ -n "$_fip_entries" ]; then
				echo "  fake-ip-filter:" >> "$CONFIG_YAML"
				printf '%s' "$_fip_entries" >> "$CONFIG_YAML"
			fi
		fi
	fi
	exit 0
fi

		REAL_LOG="/usr/share/clashoo/clashoo_real.txt"
		if [ "$lang" = "en" ] || [ "$lang" = "auto" ];then
				echo "Setting DNS" >$REAL_LOG   
		elif [ "$lang" = "zh_cn" ];then
				 echo "设定DNS" >$REAL_LOG
		fi

		mode=$(uci get clashoo.config.mode 2>/dev/null)
		p_mode=$(uci get clashoo.config.p_mode 2>/dev/null)
		da_password=$(uci get clashoo.config.dash_pass 2>/dev/null)
		safe_password=$(printf '%s' "$da_password" | sed 's/[\/&]/\\&/g')
		redir_port=$(uci get clashoo.config.redir_port 2>/dev/null)
		http_port=$(uci get clashoo.config.http_port 2>/dev/null)
		socks_port=$(uci get clashoo.config.socks_port 2>/dev/null)
		dash_port=$(uci get clashoo.config.dash_port 2>/dev/null)
		bind_addr=$(uci get clashoo.config.bind_addr 2>/dev/null)
		allow_lan=$(uci get clashoo.config.allow_lan 2>/dev/null)
		log_level=$(uci get clashoo.config.level 2>/dev/null)
		CONFIG_START="/tmp/dns.yaml"
		enhanced_mode=$(uci get clashoo.config.enhanced_mode 2>/dev/null)
		mixed_port=$(uci get clashoo.config.mixed_port 2>/dev/null)
		enable_ipv6=$(uci get clashoo.config.enable_ipv6 2>/dev/null)
		[ "$enable_ipv6" = "1" ] && enable_ipv6="true" || enable_ipv6="false"
		[ "$allow_lan" = "1" ] && allow_lan="true" || allow_lan="false"
		# routing-mark 必须与 /usr/share/clashoo/net/fw4.sh:CORE_ROUTING_MARK (0x1a0a=6666) 一致。
		# 不能复用 PROXY_FWMARK(0x162)：那个 mark 被 ip rule 吸到 lo（TPROXY 入站重定向用途），
		# 复用会让核心出站 network unreachable。用户 uci bypass_fwmark 仅用于 nft 额外 bypass。
		routing_mark_dec=6666

		core=$(uci get clashoo.config.core 2>/dev/null)
		core_type=$(uci get clashoo.config.core_type 2>/dev/null)
		interf_name=$(uci get clashoo.config.interf_name 2>/dev/null)
		tun_mode=$(uci get clashoo.config.tun_mode 2>/dev/null)
		stack=$(uci get clashoo.config.stack 2>/dev/null)
		[ -z "$stack" ] && stack="system"
		listen_port=$(uci get clashoo.config.listen_port 2>/dev/null)
		TEMP_FILE="/tmp/clashdns.yaml"
		interf=$(uci get clashoo.config.interf 2>/dev/null)
		CONFIG_YAML="/etc/clashoo/config.yaml"
		sniffer_streaming=$(uci get clashoo.config.sniffer_streaming 2>/dev/null)
		has_runtime_block=0
		has_dns_block=0

		grep -Eq '^mixed-port:|^port:|^external-controller:|^secret:|^socks-port:|^redir-port:' "$CONFIG_YAML" && has_runtime_block=1
		grep -Eq '^dns:' "$CONFIG_YAML" && has_dns_block=1

		rm -rf "$TEMP_FILE" 2>/dev/null
		rm -f "$CONFIG_START" 2>/dev/null
		: > "$CONFIG_START"
		
		if [ "$has_runtime_block" -eq 0 ]; then
			echo " " >>/tmp/dns.yaml 2>/dev/null
			sed -i "1i\#****CLASH-CONFIG-START****#" "$CONFIG_START" 2>/dev/null
			sed -i "2i\port: ${http_port}" "$CONFIG_START" 2>/dev/null
			sed -i "/port: ${http_port}/a\socks-port: ${socks_port}" "$CONFIG_START" 2>/dev/null 
			sed -i "/socks-port: ${socks_port}/a\redir-port: ${redir_port}" "$CONFIG_START" 2>/dev/null 
			sed -i "/redir-port: ${redir_port}/a\mixed-port: ${mixed_port}" "$CONFIG_START" 2>/dev/null 
			sed -i "/mixed-port: ${mixed_port}/a\ipv6: ${enable_ipv6}" "$CONFIG_START" 2>/dev/null
			sed -i "/ipv6: ${enable_ipv6}/a\allow-lan: ${allow_lan}" "$CONFIG_START" 2>/dev/null
			if [ "$allow_lan" = "true" ]; then
				sed -i "/allow-lan: ${allow_lan}/a\bind-address: \"${bind_addr}\"" "$CONFIG_START" 2>/dev/null 
				sed -i "/bind-address: \"${bind_addr}\"/a\mode: ${p_mode}" "$CONFIG_START" 2>/dev/null
				sed -i "/mode: ${p_mode}/a\log-level: ${log_level}" "$CONFIG_START" 2>/dev/null 
				sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" "$CONFIG_START" 2>/dev/null 
				sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" "$CONFIG_START" 2>/dev/null 
				sed -i "/secret: \"${da_password}\"/a\external-ui: \"./dashboard\"" "$CONFIG_START" 2>/dev/null 
				sed -i -e "\$a " "$CONFIG_START" 2>/dev/null
			else
				sed -i "/allow-lan: ${allow_lan}/a\mode: rule" "$CONFIG_START" 2>/dev/null
				sed -i "/mode: rule/a\log-level: ${log_level}" "$CONFIG_START" 2>/dev/null 
				sed -i "/log-level: ${log_level}/a\external-controller: 0.0.0.0:${dash_port}" "$CONFIG_START" 2>/dev/null 
				sed -i "/external-controller: 0.0.0.0:${dash_port}/a\secret: \"${da_password}\"" "$CONFIG_START" 2>/dev/null 
				sed -i "/secret: \"${da_password}\"/a\external-ui: \"./dashboard\"" "$CONFIG_START" 2>/dev/null 
				sed -i -e "\$a " "$CONFIG_START" 2>/dev/null
			fi
		fi

cat "$CONFIG_START" >> "$TEMP_FILE" 2>/dev/null
if [ "${interf:-0}" -eq 1 ] && [ ! -z "$interf_name" ] ;then
cat >> "/tmp/interf_name.yaml" <<-EOF
interface-name: ${interf_name} 
EOF

cat /tmp/interf_name.yaml >> "$TEMP_FILE" 2>/dev/null
sed -i -e "\$a " $TEMP_FILE 2>/dev/null

fi

authentication_set()
{
   local section="$1"
   config_get "username" "$section" "username" ""
   config_get "password" "$section" "password" ""
   config_get_bool "enabled" "$section" "enabled" "1"

    if [ "$enabled" = "0" ]; then
      return
    fi

	echo "   - \"$username:$password\"" >>/tmp/authentication.yaml

	   
}
   config_load "clashoo"
   config_foreach authentication_set "authentication"
   
if [ -f /tmp/authentication.yaml ];then
sed -i "1i\authentication:" /tmp/authentication.yaml 
fi

cat /tmp/authentication.yaml >> $TEMP_FILE 2>/dev/null
sed -i -e "\$a " $TEMP_FILE 2>/dev/null



rm -f /tmp/tun.yaml 2>/dev/null

if [ "${tun_mode:-0}" -eq 1 ];then

if [ "$core_type" != "singbox" ];then

cat >> "/tmp/tun.yaml" <<-EOF
tun:
  enable: true 
  stack: ${stack}
  auto-route: true
  auto-redirect: true
  auto-detect-interface: true
  dns-hijack:
    - any:53
    - tcp://any:53
EOF


if [ "${core:-0}" -eq 3 ];then

cat >> "/tmp/tun.yaml" <<-EOF
  device-url: dev://utun
  dns-listen: 0.0.0.0:${listen_port}   
EOF
fi

cat /tmp/tun.yaml >> $TEMP_FILE 2>/dev/null
		
fi
fi

hosts_set()
{
   local section="$1"
   config_get "address" "$section" "address" ""
   config_get "ip" "$section" "ip" ""
   config_get_bool "enabled" "$section" "enabled" "1"

    if [ "$enabled" = "0" ]; then
      return
    fi

	echo "  '$address': '$ip'" >>/tmp/hosts.yaml

	   
}
if [ "$enhanced_mode" == "redir-host" ];then
   config_load "clashoo"
   config_foreach hosts_set "hosts"
fi
   
if [ -f /tmp/hosts.yaml ];then
sed -i "1i\hosts:" /tmp/hosts.yaml 
fi
cat /tmp/hosts.yaml >> $TEMP_FILE 2>/dev/null
sed -i -e "\$a " $TEMP_FILE 2>/dev/null

sleep 1

enable_dns=$(uci get clashoo.config.enable_dns 2>/dev/null) 

# 无论订阅是否自带 dns: 块，UCI DNS 设置（nameserver/fallback）始终覆盖订阅值
if [ "${enable_dns:-0}" -eq 1 ]; then


cat >> "/tmp/enable_dns.yaml" <<-EOF
dns:
  enable: true
  listen: 0.0.0.0:${listen_port}   
EOF


if [ "$enable_ipv6" == "true" ];then
cat >> "/tmp/enable_dns.yaml" <<-EOF
  ipv6: true
EOF
fi

cat /tmp/enable_dns.yaml >> $TEMP_FILE 2>/dev/null
	
default_nameserver=$(uci get clashoo.config.default_nameserver 2>/dev/null)		
legacy_default_nameserver=$(uci get clashoo.config.defaul_nameserver 2>/dev/null)
for list in $default_nameserver $legacy_default_nameserver; do 
[ -n "$list" ] && dns_yaml_list_item "$list" >>/tmp/default_nameserver.yaml
done

if [ -f /tmp/default_nameserver.yaml ];then
sed -i "1i\  default-nameserver:" /tmp/default_nameserver.yaml
fi


	
cat >> "/tmp/default_nameserver.yaml" <<-EOF
  enhanced-mode: $enhanced_mode
EOF
cat /tmp/default_nameserver.yaml >> $TEMP_FILE 2>/dev/null

dns_ecs=$(uci get clashoo.config.dns_ecs 2>/dev/null)
dns_ecs_override=$(uci get clashoo.config.dns_ecs_override 2>/dev/null)

if [ "$enhanced_mode" == "fake-ip" ];then

fake_ip_range=$(uci get clashoo.config.fake_ip_range 2>/dev/null)
cat >> "/tmp/fake_ip_range.yaml" <<-EOF
  fake-ip-range: $fake_ip_range
EOF

cat /tmp/fake_ip_range.yaml >> $TEMP_FILE 2>/dev/null
fi

if [ "$enhanced_mode" == "fake-ip" ];then

fake_ip_filter=$(uci get clashoo.config.fake_ip_filter 2>/dev/null)		
for list in $fake_ip_filter; do 
echo "   - '$list'">>/tmp/fake_ip_filter.yaml
done

if [ -f /tmp/fake_ip_filter.yaml ];then
sed -i "1i\  fake-ip-filter:" /tmp/fake_ip_filter.yaml
fi

cat /tmp/fake_ip_filter.yaml >> $TEMP_FILE 2>/dev/null
fi

dns_apply_ecs()
{
   local server="$1"
   [ -n "$dns_ecs" ] || { printf '%s' "$server"; return; }
   case "$server" in
      *'#'*)
         server="${server}&ecs=${dns_ecs}"
         ;;
      *)
         server="${server}#ecs=${dns_ecs}"
         ;;
   esac
   if [ "${dns_ecs_override:-0}" = "1" ]; then
      server="${server}&ecs-override=true"
   fi
   printf '%s' "$server"
}
	
dnsservers_set()
{
   local section="$1"
   config_get "ser_address" "$section" "ser_address" ""
   config_get "protocol" "$section" "protocol" ""
   config_get "ser_type" "$section" "ser_type" ""
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "ser_port" "$section" "ser_port" ""

   if [ "$enabled" = "0" ]; then
      return
   fi
   
   if [ -z "$ser_type" ]; then
      return
   fi

   local server
   server=$(dns_normalize_server "$ser_address" "$protocol" "$ser_port")
   server=$(dns_apply_ecs "$server")
   [ -n "$server" ] || return

   case "$ser_type" in
      nameserver)
         dns_yaml_list_item "$server" >>/tmp/nameservers.yaml
         ;;
      fallback)
         dns_yaml_list_item "$server" >>/tmp/fallback.yaml
         ;;
      direct-nameserver)
         dns_yaml_list_item "$server" >>/tmp/direct_nameservers.yaml
         ;;
      proxy-server-nameserver)
         dns_yaml_list_item "$server" >>/tmp/proxy_nameservers.yaml
         ;;
   esac
	
}
   config_load "clashoo"
   config_foreach dnsservers_set "dnsservers"
   
if [ -f /tmp/nameservers.yaml ];then
sed -i "1i\  nameserver:" /tmp/nameservers.yaml 
fi
cat /tmp/nameservers.yaml >> $TEMP_FILE 2>/dev/null

if [ -f /tmp/direct_nameservers.yaml ];then
sed -i "1i\  direct-nameserver:" /tmp/direct_nameservers.yaml 
fi
cat /tmp/direct_nameservers.yaml >> $TEMP_FILE 2>/dev/null

if [ -f /tmp/proxy_nameservers.yaml ];then
sed -i "1i\  proxy-server-nameserver:" /tmp/proxy_nameservers.yaml 
fi
cat /tmp/proxy_nameservers.yaml >> $TEMP_FILE 2>/dev/null

dns_policy_item_append()
{
   local item="$1"
   local server
   server=$(dns_normalize_server "$item" "" "")
   server=$(dns_apply_ecs "$server")
   [ -n "$server" ] || return
   dns_yaml_list_item "$server" >> "$DNS_POLICY_ITEM_FILE"
}

dns_policy_set()
{
   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   [ "$enabled" = "0" ] && return
   config_get "policy_type" "$section" "policy_type" "nameserver-policy"
   config_get "matcher" "$section" "matcher" ""
   [ -n "$matcher" ] || return

   case "$policy_type" in
      proxy-server-nameserver-policy)
         DNS_POLICY_FILE=/tmp/proxy_nameserver_policy.yaml
         ;;
      *)
         DNS_POLICY_FILE=/tmp/nameserver_policy.yaml
         ;;
   esac

   DNS_POLICY_ITEM_FILE="/tmp/dns_policy_item_$$.yaml"
   rm -f "$DNS_POLICY_ITEM_FILE"
   config_list_foreach "$section" "nameserver" dns_policy_item_append
   [ -s "$DNS_POLICY_ITEM_FILE" ] || { rm -f "$DNS_POLICY_ITEM_FILE"; return; }

   printf "  '%s':\n" "$(dns_yaml_sq "$matcher")" >> "$DNS_POLICY_FILE"
   cat "$DNS_POLICY_ITEM_FILE" >> "$DNS_POLICY_FILE"
   rm -f "$DNS_POLICY_ITEM_FILE"
}

config_foreach dns_policy_set "dns_policy"

if [ -f /tmp/nameserver_policy.yaml ];then
sed -i "1i\  nameserver-policy:" /tmp/nameserver_policy.yaml
fi
cat /tmp/nameserver_policy.yaml >> $TEMP_FILE 2>/dev/null

if [ -f /tmp/proxy_nameserver_policy.yaml ];then
sed -i "1i\  proxy-server-nameserver-policy:" /tmp/proxy_nameserver_policy.yaml
fi
cat /tmp/proxy_nameserver_policy.yaml >> $TEMP_FILE 2>/dev/null

if [ -f /tmp/fallback.yaml ];then
sed -i "1i\  fallback:" /tmp/fallback.yaml 

fallback_filter_geoip=$(uci get clashoo.config.fallback_filter_geoip 2>/dev/null)
[ -n "$fallback_filter_geoip" ] || fallback_filter_geoip=0
[ "$fallback_filter_geoip" = "1" ] && fallback_filter_geoip=true || fallback_filter_geoip=false
fallback_filter_ipcidr=$(uci get clashoo.config.fallback_filter_ipcidr 2>/dev/null)
cat >> "/tmp/fallback.yaml" <<-EOF
  fallback-filter:
   geoip: ${fallback_filter_geoip}
   ipcidr:
EOF
if [ -n "$fallback_filter_ipcidr" ]; then
	for cidr in $fallback_filter_ipcidr; do
		echo "    - $cidr" >> /tmp/fallback.yaml
	done
else
	echo "    - 240.0.0.0/4" >> /tmp/fallback.yaml
fi

sed -i -e "\$a " /tmp/fallback.yaml 2>/dev/null
fi
cat /tmp/fallback.yaml >> $TEMP_FILE 2>/dev/null

fi

rm -rf /tmp/tun.yaml /tmp/enable_dns.yaml /tmp/fallback.yaml /tmp/nameservers.yaml /tmp/direct_nameservers.yaml /tmp/proxy_nameservers.yaml /tmp/nameserver_policy.yaml /tmp/proxy_nameserver_policy.yaml /tmp/dns_policy_item_*.yaml /tmp/fake_ip_filter.yaml /tmp/default_nameserver.yaml /tmp/hosts.yaml /tmp/authentication.yaml /tmp/dnshijack.yaml /tmp/fake_ip_range.yaml /tmp/dns.yaml /tmp/interf_name.yaml
		
	
		if [ "${enable_dns}" == "0" ];then
		
			if [ ! -z "$(grep "^dns:" "$CONFIG_YAML")" ]; then
				sed -i "/dns:/i\#clash-openwrt" $CONFIG_YAML 2>/dev/null
				sed -i "/#clash-openwrt/a\#=============" $CONFIG_YAML 2>/dev/null
				sed -i '1,/#clash-openwrt/d' $CONFIG_YAML 2>/dev/null
				
				sed -i '/#=============/ d' $CONFIG_YAML 2>/dev/null
			fi
			cat $CONFIG_YAML >> $TEMP_FILE 2>/dev/null
			mv $TEMP_FILE $CONFIG_YAML 2>/dev/null
			
		elif [ "${enable_dns}" == "1" ];then
		

			if [ ! -z "$(grep "^proxy-providers:" "$CONFIG_YAML")" ]; then
			  sed -i "/^proxy-providers:/i\#clash-openwrt" $CONFIG_YAML 2>/dev/null
			elif [ ! -z "$(grep "^proxies:" "$CONFIG_YAML")" ]; then
			  sed -i "/^proxies:/i\#clash-openwrt" $CONFIG_YAML 2>/dev/null
			fi
		
			sed -i "/#clash-openwrt/a\#=============" $CONFIG_YAML 2>/dev/null
			sed -i "/#=============/a\ " $CONFIG_YAML 2>/dev/null
			sed -i '1,/#clash-openwrt/d' $CONFIG_YAML 2>/dev/null
			
			mv /etc/clashoo/config.yaml /etc/clashoo/dns.yaml
			cat $TEMP_FILE /etc/clashoo/dns.yaml > $CONFIG_YAML 2>/dev/null
			rm -rf /etc/clashoo/dns.yaml
			sed -i '/#=============/ d' $CONFIG_YAML 2>/dev/null
			# 兼容部分订阅中 dns.listen 缩进异常（4 空格），修正为标准 2 空格
			sed -i 's/^    listen:/  listen:/g' $CONFIG_YAML 2>/dev/null
		fi

		if grep -Eq '^external-controller:' "$CONFIG_YAML"; then
			sed -i "s@^external-controller:.*@external-controller: 0.0.0.0:${dash_port}@g" "$CONFIG_YAML" 2>/dev/null
		else
			sed -i "/^mixed-port:/a\external-controller: 0.0.0.0:${dash_port}" "$CONFIG_YAML" 2>/dev/null
		fi

		if grep -Eq '^secret:' "$CONFIG_YAML"; then
			sed -i "s@^secret:.*@secret: \"${safe_password}\"@g" "$CONFIG_YAML" 2>/dev/null
		else
			sed -i "/^external-controller:/a\secret: \"${safe_password}\"" "$CONFIG_YAML" 2>/dev/null
		fi

		if grep -Eq '^external-ui:' "$CONFIG_YAML"; then
			sed -i 's@^external-ui:.*@external-ui: "./dashboard"@g' "$CONFIG_YAML" 2>/dev/null
		else
			sed -i '/^secret:/a\external-ui: "./dashboard"' "$CONFIG_YAML" 2>/dev/null
		fi

		# Keep core outbound exempt from local redirect/tproxy loops.
		if grep -Eq '^routing-mark:' "$CONFIG_YAML"; then
			sed -i "s@^routing-mark:.*@routing-mark: ${routing_mark_dec}@g" "$CONFIG_YAML" 2>/dev/null
		else
			sed -i "/^mode:/a\routing-mark: ${routing_mark_dec}" "$CONFIG_YAML" 2>/dev/null
		fi

		# Sniffer compatibility block (streaming friendly).
		# Clean existing root-level sniffer block first, then re-append when enabled.
		awk '
			BEGIN { skip = 0 }
			{
				if ($0 ~ /^sniffer:[[:space:]]*$/) {
					skip = 1
					next
				}
				if (skip && $0 ~ /^[^[:space:]#][^:]*:[[:space:]]*.*$/) {
					skip = 0
				}
				if (!skip)
					print $0
			}
		' "$CONFIG_YAML" > "${CONFIG_YAML}.tmp" 2>/dev/null && mv "${CONFIG_YAML}.tmp" "$CONFIG_YAML" 2>/dev/null

		if [ "${sniffer_streaming:-0}" = "1" ] || [ "${sniffer_streaming}" = "true" ]; then
cat >> "$CONFIG_YAML" <<-EOF

sniffer:
  enable: true
  force-dns-mapping: true
  parse-pure-ip: true
  sniff:
    HTTP:
      ports:
        - 80
        - 8080
      override-destination: true
    TLS:
      ports:
        - 443
        - 8443
      override-destination: true
    QUIC:
      ports:
        - 443
        - 8443
      override-destination: true
  force-domain:
    - "+.youtube.com"
    - "+.googlevideo.com"
    - "+.netflix.com"
    - "+.nflxvideo.net"
    - "+.disneyplus.com"
    - "+.hulu.com"
    - "+.hbomax.com"
EOF
		fi

		rm -rf  $TEMP_FILE 2>/dev/null
		
add_address(){
	# 包内 /usr/share/clashoo/server.list 保持只读；合并后的 fake-ip 过滤源写到 /tmp
	mkdir -p /tmp/clashoo
	local SRC="/usr/share/clashoo/server.list"
	local DST="/tmp/clashoo/fake_filter.list"
	local SERVERS_CONF="/tmp/clashoo/_servers.conf"
	local ADDRESS_LIST="/tmp/clashoo/_address.list"

	: >"$SERVERS_CONF"
	servers_get()
	{
	   local section="$1"
	   config_get "server" "$section" "server" ""
	   [ -n "$server" ] && echo "$server" >>"$SERVERS_CONF"
	}
	config_load "clashoo"
	config_foreach servers_get "servers"

	: >"$ADDRESS_LIST"
	if [ -s "$SERVERS_CONF" ]; then
		while IFS= read -r line; do
			[ -z "$line" ] && continue
			grep -Fxq "$line" "$SRC" 2>/dev/null && continue
			echo "$line" >>"$ADDRESS_LIST"
		done <"$SERVERS_CONF"
	fi

	{
		if [ -s "$ADDRESS_LIST" ]; then
			echo "#START"
			cat "$ADDRESS_LIST"
			echo "#END"
		fi
		cat "$SRC" 2>/dev/null
	} > "$DST"
	chmod 644 "$DST" 2>/dev/null

	rm -f "$SERVERS_CONF" "$ADDRESS_LIST" /tmp/server.conf 2>/dev/null
}


		#fake_ip=$(egrep '^ {0,}enhanced-mode' /etc/clashoo/config.yaml |grep enhanced-mode: |awk -F ': ' '{print $2}')
		fake_ip=$(uci get clashoo.config.enhanced_mode 2>/dev/null)

		if [ "${fake_ip}" == "fake-ip" ];then
		
		add_address >/dev/null 2>&1
		wait
		CUSTOM_FILE="/tmp/clashoo/fake_filter.list"
		FAKE_FILTER_FILE="/tmp/clashoo/fake_filter.yaml"
		num=$(grep -c '' "$CUSTOM_FILE" 2>/dev/null)

		rm -rf "$FAKE_FILTER_FILE" 2>/dev/null

			if [ -s "$CUSTOM_FILE" ]; then

				count_num=1
				while [ "$count_num" -le "${num:-0}" ]
				do
				line=$(sed -n "${count_num}p" "$CUSTOM_FILE")
				if [ -z "$(echo "$line" | grep '^ \{0,\}#' 2>/dev/null)" ]; then
					 echo "   - '$line'" >> "$FAKE_FILTER_FILE"
				fi
				count_num=$(( count_num + 1 ))
				done


			fi


			if [ "$lang" = "en" ] || [ "$lang" = "auto" ];then
				echo "Setting Up Fake-IP Filter" >$REAL_LOG 
			elif [ "$lang" = "zh_cn" ];then
				 echo "正在设置Fake-IP黑名单" >$REAL_LOG
			fi	

			# fake-ip-filter is already rendered in the generated DNS block above.
			# Do not delete/reinsert it here, otherwise list items may be orphaned
			# and break the DNS listen line parsing.
		fi	
	
