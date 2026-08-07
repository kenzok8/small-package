#!/bin/sh

set -eu

NFT_DIR="/var/run/clash"
SETS_RULES="${NFT_DIR}/fw4_sets.nft"
DSTNAT_RULES="${NFT_DIR}/fw4_dstnat.nft"
MANGLE_RULES="${NFT_DIR}/fw4_mangle.nft"
OUTPUT_RULES="${NFT_DIR}/fw4_output.nft"
BUILTIN_NFT_DIR="/usr/share/clashoo/nftables"
GEOIP_CN_NFT="${BUILTIN_NFT_DIR}/geoip_cn.nft"
GEOIP6_CN_NFT="${BUILTIN_NFT_DIR}/geoip6_cn.nft"
LOCAL_OUTPUT_TABLE="clashoo_local"
QUIC_BLOCK_TABLE="clashoo_quic"
# PROXY_FWMARK: inbound TPROXY mark, ip rule -> table PROXY_ROUTE_TABLE -> lo.
# CORE_ROUTING_MARK: mihomo outbound SO_MARK (= routing-mark in config).
# Must differ: otherwise mihomo egress is pulled to lo -> unreachable.
# When changing CORE_ROUTING_MARK, also update yum_change.sh routing_mark_dec.
PROXY_FWMARK="0x162"
PROXY_ROUTE_TABLE="0x162"
CORE_ROUTING_MARK="0x1a0a"  # = 6666
ACL_BYPASS_FWMARK="0x163"
SINGBOX_BYPASS_FWMARK="0x2024"
ACL_BYPASS_PREF="8998"
DNSMASQ_BYPASS_PREF="8999"

uci_get() {
	uci -q get "$1" 2>/dev/null || true
}

bool_enabled() {
	case "$1" in
		1|true|TRUE|yes|on) return 0 ;;
		*) return 1 ;;
	esac
}

acl_bool() {
	[ -n "$1" ] || return 0
	bool_enabled "$1"
}

tun_available() {
	ip tuntap add mode tun name cotuntest >/dev/null 2>&1 || return 1
	ip link del cotuntest >/dev/null 2>&1 || true
	return 0
}

config_redir_port() {
	uci_get clashoo.config.redir_port
}

config_tproxy_port() {
	local port
	port="$(uci_get clashoo.config.tproxy_port)"
	if [ -n "$port" ]; then
		printf '%s\n' "$port"
	else
		config_redir_port
	fi
}

config_tcp_mode() {
	uci_get clashoo.config.tcp_mode
}

config_udp_mode() {
	uci_get clashoo.config.udp_mode
}

config_access_control() {
	[ "$(uci_get clashoo.config.acl_migrated)" = "1" ] && {
		printf '0\n'
		return
	}
	uci_get clashoo.config.access_control
}

acl_sections() {
	uci -q show clashoo 2>/dev/null | sed -n 's/^clashoo\.\([^.=]*\)=lan_acl$/\1/p'
}

acl_list() {
	uci_get "$1"
}

grouped_acl_enabled() {
	local section
	[ "$(uci_get clashoo.config.acl_migrated)" = "1" ] || return 1
	for section in $(acl_sections); do
		[ "$(uci_get "clashoo.${section}.enabled")" != "0" ] && return 0
	done
	return 1
}

acl_has_catchall() {
	local section
	for section in $(acl_sections); do
		[ "$(uci_get "clashoo.${section}.enabled")" != "0" ] || continue
		[ -z "$(acl_list "clashoo.${section}.ip")$(acl_list "clashoo.${section}.ip6")$(acl_list "clashoo.${section}.mac")" ] && return 0
	done
	return 1
}

lan_acl_enabled() {
	grouped_acl_enabled && return 0
	case "$(config_access_control)" in
		1|2) return 0 ;;
	esac
	return 1
}

config_enable_dns() {
	uci_get clashoo.config.enable_dns
}

config_dns_port() {
	local port=""
	if [ "$(uci_get clashoo.config.core_type)" != "singbox" ]; then
		port="$(sed -n 's/^[[:space:]]*listen:.*:[[:space:]]*['"'"'"]*\([0-9]\{1,\}\)['"'"'"]*[[:space:]]*$/\1/p' /etc/clashoo/config.yaml 2>/dev/null | head -n1)"
	fi
	[ -n "$port" ] || port="$(uci_get clashoo.config.listen_port)"
	printf '%s' "$port" | grep -Eq '^[0-9]+$' || port=1053
	printf '%s\n' "$port"
}

lan_dns_split_enabled() {
	lan_acl_enabled || return 1
	bool_enabled "$(config_enable_dns)" || return 1
	bool_enabled "$(config_ipv4_dns_hijack)" || bool_enabled "$(config_ipv6_dns_hijack)"
}

tun_acl_enabled() {
	lan_acl_enabled || return 1
	[ "$(config_tcp_mode)" = "tun" ] || [ "$(config_udp_mode)" = "tun" ]
}

config_ipv4_dns_hijack() {
	uci_get clashoo.config.ipv4_dns_hijack
}

config_ipv6_dns_hijack() {
	uci_get clashoo.config.ipv6_dns_hijack
}

config_ipv4_proxy() {
	uci_get clashoo.config.ipv4_proxy
}

config_ipv6_proxy() {
	uci_get clashoo.config.ipv6_proxy
}

singbox_tun_active() {
	[ "$(uci_get clashoo.config.core_type)" = "singbox" ] || return 1
	[ "$(config_tcp_mode)" = "tun" ] || [ "$(config_udp_mode)" = "tun" ]
}

config_bypass_china() {
	uci_get clashoo.config.bypass_china
}

config_bypass_china_ipv6() {
	local value
	value="$(uci_get clashoo.config.bypass_china_ipv6)"
	if [ -n "$value" ]; then
		printf '%s\n' "$value"
	else
		config_bypass_china
	fi
}

config_block_quic() {
	uci_get clashoo.config.block_quic
}

config_bypass_port_mode() {
	uci_get clashoo.config.bypass_port_mode
}

config_bypass_port_custom() {
	uci_get clashoo.config.bypass_port_custom
}

config_legacy_bypass_port() {
	uci_list clashoo.config.bypass_port
}

config_proxy_tcp_dport() {
	local mode custom legacy value
	mode="$(config_bypass_port_mode)"
	custom="$(config_bypass_port_custom)"
	legacy="$(uci_get clashoo.config.proxy_tcp_dport)"
	[ -z "$legacy" ] && legacy="$(config_legacy_bypass_port)"

	case "$mode" in
		all)
			# 空值在 render_port_match 中表示该协议的全部端口
			printf '%s\n' ''
			;;
		common)
			printf '%s\n' '22,53,80,443,8080,8443'
			;;
		custom)
			value="$custom"
			[ -z "$value" ] && value="$legacy"
			printf '%s\n' "$value"
			;;
		*)
			printf '%s\n' "$legacy"
			;;
	esac
}

config_proxy_udp_dport() {
	local mode custom legacy value
	mode="$(config_bypass_port_mode)"
	custom="$(config_bypass_port_custom)"
	legacy="$(uci_get clashoo.config.proxy_udp_dport)"
	[ -z "$legacy" ] && legacy="$(config_legacy_bypass_port)"

	case "$mode" in
		all)
			printf '%s\n' ''
			;;
		common)
			printf '%s\n' '22,53,80,443,8080,8443'
			;;
		custom)
			value="$custom"
			[ -z "$value" ] && value="$legacy"
			printf '%s\n' "$value"
			;;
		*)
			printf '%s\n' "$legacy"
			;;
	esac
}

config_bypass_dscp() {
	uci_list clashoo.config.bypass_dscp
}

config_bypass_fwmark() {
	uci_list clashoo.config.bypass_fwmark
}

config_fake_ip_range6() {
	local value
	value="$(uci_get clashoo.config.fake_ip_range6)"
	[ -n "$value" ] || value="fc00::/18"
	[ "$(uci_get clashoo.config.enhanced_mode)" = "redir-host" ] && return 0
	bool_enabled "$(uci_get clashoo.config.enable_ipv6)" || return 0
	printf '%s\n' "$value"
}

config_fake_ip_range() {
	local value
	value="$(uci_get clashoo.config.fake_ip_range)"
	[ -n "$value" ] && {
		printf '%s\n' "$value"
		return
	}
	printf '198.18.0.1/16\n'
}

uci_list() {
	local key="$1"
	uci -q show "$key" 2>/dev/null | sed -n "s/^${key}=//p" | sed "s/'//g"
}

ensure_firewall_include() {
	local name="$1"
	local path="$2"
	local chain="${3:-}"
	local position="${4:-chain-pre}"

	uci -q batch <<-EOF >/dev/null
		set firewall.${name}=include
		set firewall.${name}.type='nftables'
		set firewall.${name}.path='${path}'
		set firewall.${name}.position='${position}'
		$( [ -n "$chain" ] && printf "set firewall.%s.chain='%s'\n" "$name" "$chain" )
		commit firewall
EOF
}

remove_firewall_include() {
	local name="$1"
	uci -q delete firewall."${name}" >/dev/null 2>&1 || true
}

render_common_returns() {
	local fake6
	fake6="$(config_fake_ip_range6)"
	printf '%s\n' 'meta nfproto ipv4 ip daddr { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } return'
	if [ -n "$fake6" ]; then
		printf 'meta nfproto ipv6 ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } ip6 daddr != %s return\n' "$fake6"
	else
		printf '%s\n' 'meta nfproto ipv6 ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } return'
	fi
}

render_ip_elements() {
	local list="$1"
	local first=1 entry
	for entry in $list; do
		if [ "$first" -eq 0 ]; then
			printf ', '
		fi
		printf '%s' "$entry"
		first=0
	done
}

render_token_elements() {
	printf '%s\n' "$1" | tr ',\t' '  ' | awk '
		BEGIN { first = 1 }
		{
			for (i = 1; i <= NF; i++) {
				if ($i == "")
					continue
				if (!first)
					printf ", "
				printf "%s", $i
				first = 0
			}
		}'
}

detect_coexist_fwmarks() {
	# Merge co-installed proxy plugin fwmarks into bypass to avoid intercepting
	# their traffic. Only when init.d exists (passwall:0x1 passwall2:0xff
	# nikki:tproxy 0x80/tun 0x81 mask 0xff).
	local marks=""
	[ -x /etc/init.d/passwall ]  && marks="$marks 0x1"
	[ -x /etc/init.d/passwall2 ] && marks="$marks 0xff"
	if [ -x /etc/init.d/nikki ]; then
		local nm
		nm="$(uci -q get nikki.routing.tproxy_fw_mark) $(uci -q get nikki.routing.tun_fw_mark)"
		[ -z "$(echo "$nm" | tr -d ' ')" ] && nm="0x80 0x81"
		marks="$marks $nm"
	fi
	printf '%s\n' "$marks"
}

merge_fwmark_tokens() {
	# Always bypass PROXY_FWMARK (inbound TPROXY) and CORE_ROUTING_MARK (core egress)
	# so nft never traps them. Also merge co-installed plugin fwmarks for coexistence.
	local coexist
	coexist="$(detect_coexist_fwmarks)"
	printf '%s %s %s %s\n' "$1" "$PROXY_FWMARK" "$CORE_ROUTING_MARK" "$coexist" | tr ',\t' '  ' | awk '
		BEGIN { first = 1 }
		{
			for (i = 1; i <= NF; i++) {
				if ($i == "" || seen[$i]++)
					continue
				if (!first)
					printf ", "
				printf "%s", $i
				first = 0
			}
		}'
}

render_port_match() {
	local proto="$1"
	local ports="$2"
	local port_elements

	port_elements="$(render_token_elements "$ports")"
	if [ -n "$port_elements" ]; then
		printf 'meta l4proto %s %s dport { %s }' "$proto" "$proto" "$port_elements"
	else
		printf 'meta l4proto %s' "$proto"
	fi
}

render_acl_dns_rules() {
	local redirect_port="$1" section ipv4 ipv6 mac ipv4_elements ipv6_elements mac_elements action
	for section in $(acl_sections); do
		[ "$(uci_get "clashoo.${section}.enabled")" != "0" ] || continue
		if acl_bool "$(uci_get "clashoo.${section}.dns")"; then
			action="counter redirect to :${redirect_port}"
		elif singbox_tun_active; then
			action="meta mark set ${SINGBOX_BYPASS_FWMARK} ct mark set meta mark counter return"
		else
			action="counter return"
		fi
		ipv4="$(acl_list "clashoo.${section}.ip")"
		ipv6="$(acl_list "clashoo.${section}.ip6")"
		mac="$(acl_list "clashoo.${section}.mac")"
		ipv4_elements="$(render_ip_elements "$ipv4")"
		ipv6_elements="$(render_ip_elements "$ipv6")"
		mac_elements="$(render_ip_elements "$mac")"

		if [ -z "$ipv4_elements$ipv6_elements$mac_elements" ]; then
			bool_enabled "$(config_ipv4_dns_hijack)" && printf 'meta nfproto ipv4 meta l4proto { tcp, udp } th dport 53 %s\n' "$action"
			bool_enabled "$(config_ipv6_dns_hijack)" && printf 'meta nfproto ipv6 meta l4proto { tcp, udp } th dport 53 %s\n' "$action"
			continue
		fi
		if [ -n "$ipv4_elements" ] && bool_enabled "$(config_ipv4_dns_hijack)"; then
			printf 'meta nfproto ipv4 ip saddr { %s } meta l4proto { tcp, udp } th dport 53 %s\n' "$ipv4_elements" "$action"
		fi
		if [ -n "$ipv6_elements" ] && bool_enabled "$(config_ipv6_dns_hijack)"; then
			printf 'meta nfproto ipv6 ip6 saddr { %s } meta l4proto { tcp, udp } th dport 53 %s\n' "$ipv6_elements" "$action"
		fi
		if [ -n "$mac_elements" ]; then
			bool_enabled "$(config_ipv4_dns_hijack)" && printf 'meta nfproto ipv4 ether saddr { %s } meta l4proto { tcp, udp } th dport 53 %s\n' "$mac_elements" "$action"
			bool_enabled "$(config_ipv6_dns_hijack)" && printf 'meta nfproto ipv6 ether saddr { %s } meta l4proto { tcp, udp } th dport 53 %s\n' "$mac_elements" "$action"
		fi
	done
}

render_acl_proxy_rules() {
	local mode="$1" proto="$2" port_match="$3" target_port="$4"
	local section ipv4 ipv6 mac ipv4_elements ipv6_elements mac_elements enabled action4 action6

	for section in $(acl_sections); do
		[ "$(uci_get "clashoo.${section}.enabled")" != "0" ] || continue
		enabled="$(uci_get "clashoo.${section}.proxy")"
		case "$mode" in
			redirect)
				if acl_bool "$enabled"; then
					if singbox_tun_active; then
						action4="${port_match} ct mark set ${SINGBOX_BYPASS_FWMARK} counter redirect to :${target_port}"
					else
						action4="${port_match} counter redirect to :${target_port}"
					fi
					action6="$action4"
				elif singbox_tun_active; then
					action4="meta l4proto ${proto} meta mark set ${SINGBOX_BYPASS_FWMARK} ct mark set meta mark counter return"
					action6="$action4"
				else
					action4="meta l4proto ${proto} counter return"
					action6="$action4"
				fi
				;;
			tproxy)
				if acl_bool "$enabled"; then
					if singbox_tun_active; then
						action4="${port_match} ct mark set ${SINGBOX_BYPASS_FWMARK} tproxy ip to :${target_port} meta mark set ${PROXY_FWMARK} counter accept"
						action6="${port_match} ct mark set ${SINGBOX_BYPASS_FWMARK} tproxy ip6 to :${target_port} meta mark set ${PROXY_FWMARK} counter accept"
					else
						action4="${port_match} tproxy ip to :${target_port} meta mark set ${PROXY_FWMARK} counter accept"
						action6="${port_match} tproxy ip6 to :${target_port} meta mark set ${PROXY_FWMARK} counter accept"
					fi
				elif singbox_tun_active; then
					action4="meta l4proto ${proto} meta mark set ${SINGBOX_BYPASS_FWMARK} ct mark set meta mark counter return"
					action6="$action4"
				else
					action4="meta l4proto ${proto} counter return"
					action6="$action4"
				fi
				;;
			tun)
				if acl_bool "$enabled"; then
					action4="meta l4proto ${proto} counter return"
				elif singbox_tun_active; then
					action4="meta l4proto ${proto} meta mark set ${SINGBOX_BYPASS_FWMARK} ct mark set meta mark counter accept"
				else
					action4="meta l4proto ${proto} meta mark set ${ACL_BYPASS_FWMARK} counter accept"
				fi
				action6="$action4"
				;;
		esac

		ipv4="$(acl_list "clashoo.${section}.ip")"
		ipv6="$(acl_list "clashoo.${section}.ip6")"
		mac="$(acl_list "clashoo.${section}.mac")"
		ipv4_elements="$(render_ip_elements "$ipv4")"
		ipv6_elements="$(render_ip_elements "$ipv6")"
		mac_elements="$(render_ip_elements "$mac")"

		if [ -z "$ipv4_elements$ipv6_elements$mac_elements" ]; then
			bool_enabled "$(config_ipv4_proxy)" && printf 'meta nfproto ipv4 %s\n' "$action4"
			bool_enabled "$(config_ipv6_proxy)" && printf 'meta nfproto ipv6 %s\n' "$action6"
			continue
		fi
		if [ -n "$ipv4_elements" ] && bool_enabled "$(config_ipv4_proxy)"; then
			printf 'meta nfproto ipv4 ip saddr { %s } %s\n' "$ipv4_elements" "$action4"
		fi
		if [ -n "$ipv6_elements" ] && bool_enabled "$(config_ipv6_proxy)"; then
			printf 'meta nfproto ipv6 ip6 saddr { %s } %s\n' "$ipv6_elements" "$action6"
		fi
		if [ -n "$mac_elements" ]; then
			bool_enabled "$(config_ipv4_proxy)" && printf 'meta nfproto ipv4 ether saddr { %s } %s\n' "$mac_elements" "$action4"
			bool_enabled "$(config_ipv6_proxy)" && printf 'meta nfproto ipv6 ether saddr { %s } %s\n' "$mac_elements" "$action6"
		fi
	done
}

# Split proxied clients to the core DNS while ACL-bypassed clients use dnsmasq.
# Gated on UCI IPv4/IPv6 toggles.
# return 0: no output when both off, avoid set -e false-positive.
render_dns_hijack() {
	local access_control="$1" redirect_port=53
	if lan_dns_split_enabled; then
		redirect_port="$(config_dns_port)"
	fi
	if grouped_acl_enabled; then
		render_acl_dns_rules "$redirect_port"
		acl_has_catchall && return 0
	else
		[ "$access_control" = "1" ] && printf '%s\n' 'ip saddr != @clash_proxy_lan return'
		[ "$access_control" = "2" ] && printf '%s\n' 'ip saddr @clash_reject_lan return'
	fi
	bool_enabled "$(config_ipv4_dns_hijack)" && \
		printf '%s\n' "meta nfproto ipv4 meta l4proto { tcp, udp } th dport 53 counter redirect to :${redirect_port}"
	bool_enabled "$(config_ipv6_dns_hijack)" && \
		printf '%s\n' "meta nfproto ipv6 meta l4proto { tcp, udp } th dport 53 counter redirect to :${redirect_port}"
	return 0
}

apply_local_output_rule() {
	local redir_port fake_ip_range tcp_mode bypass_fwmark bypass_china
	local fwmark_elements fwmark_rule china_set china_rule dnsmasq_rule dnsmasq_uid
	redir_port="$(config_redir_port)"
	fake_ip_range="$(config_fake_ip_range)"
	tcp_mode="$(config_tcp_mode)"
	bypass_fwmark="$(config_bypass_fwmark)"
	bypass_china="$(config_bypass_china)"

	# Keep local-output redirect usable when tun mode is selected but tun
	# device is unavailable on the system.
	if [ "$tcp_mode" = "tun" ] && ! tun_available; then
		tcp_mode="redirect"
	fi

	nft delete table ip ${LOCAL_OUTPUT_TABLE} >/dev/null 2>&1 || true

	# Only apply local output redirect when tcp_mode is redirect
	[ "$tcp_mode" != "redirect" ] && return 0

	# bypass mihomo's own marks (prevent self-hijack -> dead loop)
	fwmark_rule=""
	fwmark_elements="$(merge_fwmark_tokens "$bypass_fwmark")"
	[ -n "$fwmark_elements" ] && fwmark_rule="meta mark { ${fwmark_elements} } return"

	# CN IP bypass (uses clashoo_china set from geoip_cn.nft)
	china_set=""
	china_rule=""
	if bool_enabled "$bypass_china" && [ -s "$GEOIP_CN_NFT" ]; then
		china_set="$(cat "$GEOIP_CN_NFT")"
		china_rule="ip daddr @clashoo_china return"
	fi

	dnsmasq_rule=""
	if lan_dns_split_enabled; then
		dnsmasq_uid="$(id -u dnsmasq 2>/dev/null)"
		printf '%s' "$dnsmasq_uid" | grep -Eq '^[0-9]+$' && dnsmasq_rule="meta skuid ${dnsmasq_uid} return"
	fi

	nft -f - <<EOF
table ip ${LOCAL_OUTPUT_TABLE} {
	set clashoo_localnetwork {
		type ipv4_addr
		flags interval
		auto-merge
		elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8,
		             169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16,
		             224.0.0.0/4, 240.0.0.0/4 }
	}
	${china_set}
	chain output {
		type nat hook output priority dstnat; policy accept;
		${dnsmasq_rule}
		${fwmark_rule}
		ip daddr @clashoo_localnetwork return
		${china_rule}
		ip daddr ${fake_ip_range} tcp dport != 53 redirect to :${redir_port}
		meta l4proto tcp redirect to :${redir_port}
	}
}
EOF
}

remove_local_output_rule() {
	nft delete table ip ${LOCAL_OUTPUT_TABLE} >/dev/null 2>&1 || true
}

remove_acl_bypass_rules() {
	local dnsmasq_uid
	ip rule del pref "$ACL_BYPASS_PREF" fwmark "$ACL_BYPASS_FWMARK" lookup main >/dev/null 2>&1 || true
	ip -6 rule del pref "$ACL_BYPASS_PREF" fwmark "$ACL_BYPASS_FWMARK" lookup main >/dev/null 2>&1 || true
	dnsmasq_uid="$(id -u dnsmasq 2>/dev/null)"
	if printf '%s' "$dnsmasq_uid" | grep -Eq '^[0-9]+$'; then
		ip rule del pref "$DNSMASQ_BYPASS_PREF" uidrange "${dnsmasq_uid}-${dnsmasq_uid}" lookup main >/dev/null 2>&1 || true
		ip -6 rule del pref "$DNSMASQ_BYPASS_PREF" uidrange "${dnsmasq_uid}-${dnsmasq_uid}" lookup main >/dev/null 2>&1 || true
	fi
}

apply_acl_bypass_rules() {
	local dnsmasq_uid
	remove_acl_bypass_rules
	tun_acl_enabled || return 0
	ip rule add pref "$ACL_BYPASS_PREF" fwmark "$ACL_BYPASS_FWMARK" lookup main >/dev/null 2>&1 || true
	ip -6 rule add pref "$ACL_BYPASS_PREF" fwmark "$ACL_BYPASS_FWMARK" lookup main >/dev/null 2>&1 || true
	dnsmasq_uid="$(id -u dnsmasq 2>/dev/null)"
	if printf '%s' "$dnsmasq_uid" | grep -Eq '^[0-9]+$'; then
		ip rule add pref "$DNSMASQ_BYPASS_PREF" uidrange "${dnsmasq_uid}-${dnsmasq_uid}" lookup main >/dev/null 2>&1 || true
		ip -6 rule add pref "$DNSMASQ_BYPASS_PREF" uidrange "${dnsmasq_uid}-${dnsmasq_uid}" lookup main >/dev/null 2>&1 || true
	fi
}

apply_block_quic_rule() {
	local fake_ip_range china_set china_rule scope
	nft delete table inet ${QUIC_BLOCK_TABLE} >/dev/null 2>&1 || true
	bool_enabled "$(config_block_quic)" || return 0

	fake_ip_range="$(config_fake_ip_range)"
	china_set=""
	scope="ip daddr ${fake_ip_range}"
	if [ "$(uci_get clashoo.config.enhanced_mode)" != "fake-ip" ]; then
		if bool_enabled "$(config_bypass_china)" && [ -s "$GEOIP_CN_NFT" ]; then
			china_set="$(cat "$GEOIP_CN_NFT")"
			china_rule="ip daddr @clashoo_china return"
		fi
		scope=""
	fi

	nft -f - <<EOF
table inet ${QUIC_BLOCK_TABLE} {
	${china_set}
	chain prerouting {
		type filter hook prerouting priority mangle - 1; policy accept;
		${china_rule:-}
		${scope} udp dport 443 counter reject with icmpx type port-unreachable
	}

	chain forward {
		type filter hook forward priority -10; policy accept;
		${china_rule:-}
		${scope} udp dport 443 counter reject with icmpx type port-unreachable
	}
}
EOF
}

remove_block_quic_rule() {
	nft delete table inet ${QUIC_BLOCK_TABLE} >/dev/null 2>&1 || true
}

write_empty_set() {
	local set_name="$1"
	local set_type="$2"

	printf 'set %s {\n\ttype %s;\n\tflags interval;\n\tauto-merge;\n}\n\n' "$set_name" "$set_type"
}

append_set_from_file_or_empty() {
	local file_path="$1"
	local set_name="$2"
	local set_type="$3"

	if [ -s "$file_path" ]; then
		cat "$file_path"
		printf '\n'
	else
		write_empty_set "$set_name" "$set_type"
	fi
}

generate_rules() {
	local redir_port tproxy_port tcp_mode udp_mode access_control fake_ip_range proxy_lan_ips reject_lan_ips
	local proxy_tcp_dport proxy_udp_dport bypass_dscp bypass_fwmark bypass_china bypass_china_ipv6
	local acl_catchall=0
	redir_port="$(config_redir_port)"
	tproxy_port="$(config_tproxy_port)"
	tcp_mode="$(config_tcp_mode)"
	udp_mode="$(config_udp_mode)"
	access_control="$(config_access_control)"
	grouped_acl_enabled && acl_has_catchall && acl_catchall=1
	bypass_china="$(config_bypass_china)"
	bypass_china_ipv6="$(config_bypass_china_ipv6)"
	proxy_tcp_dport="$(config_proxy_tcp_dport)"
	proxy_udp_dport="$(config_proxy_udp_dport)"
	bypass_dscp="$(config_bypass_dscp)"
	bypass_fwmark="$(config_bypass_fwmark)"
	fake_ip_range="$(config_fake_ip_range)"
	proxy_lan_ips="$(uci_list clashoo.config.proxy_lan_ips)"
	reject_lan_ips="$(uci_list clashoo.config.reject_lan_ips)"

	# When tun device is unavailable, fall back to non-tun transparent modes
	# so routing rules still take effect for sing-box redirect/tproxy inbounds.
	if [ "$tcp_mode" = "tun" ] || [ "$udp_mode" = "tun" ]; then
		if ! tun_available; then
			[ "$tcp_mode" = "tun" ] && tcp_mode="redirect"
			[ "$udp_mode" = "tun" ] && udp_mode="tproxy"
		fi
	fi

	mkdir -p "$NFT_DIR"

	# Build optional elements lines (nftables rejects empty elements = {})
	local proxy_elements reject_elements dscp_elements fwmark_elements
	proxy_elements="$(render_ip_elements "$proxy_lan_ips")"
	reject_elements="$(render_ip_elements "$reject_lan_ips")"
	dscp_elements="$(render_token_elements "$bypass_dscp")"
	fwmark_elements="$(merge_fwmark_tokens "$bypass_fwmark")"
	tcp_match="$(render_port_match tcp "$proxy_tcp_dport")"
	udp_match="$(render_port_match udp "$proxy_udp_dport")"

	{
		printf 'set clashoo_localnetwork {\n\ttype ipv4_addr;\n\tflags interval;\n\tauto-merge;\n'
		printf '\telements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 }\n}\n\n'

		append_set_from_file_or_empty "$GEOIP_CN_NFT" clashoo_china ipv4_addr
		append_set_from_file_or_empty "$GEOIP6_CN_NFT" clashoo_china6 ipv6_addr

		printf 'set clash_proxy_lan {\n\ttype ipv4_addr;\n\tflags interval;\n\tauto-merge;\n'
		[ -n "$proxy_elements" ] && printf '\telements = { %s }\n' "$proxy_elements"
		printf '}\n\n'

		printf 'set clash_reject_lan {\n\ttype ipv4_addr;\n\tflags interval;\n\tauto-merge;\n'
		[ -n "$reject_elements" ] && printf '\telements = { %s }\n' "$reject_elements"
		printf '}\n\n'

		if grouped_acl_enabled && [ "$tcp_mode" = "tun" ]; then
			printf 'chain clashoo_acl_tun_tcp {\n'
			render_acl_proxy_rules tun tcp "$tcp_match" "$tproxy_port"
			printf '}\n\n'
		fi
		if grouped_acl_enabled && [ "$udp_mode" = "tun" ]; then
			printf 'chain clashoo_acl_tun_udp {\n'
			render_acl_proxy_rules tun udp "$udp_match" "$tproxy_port"
			printf '}\n'
		fi
	} > "$SETS_RULES"

	: > "$OUTPUT_RULES"


# DNS hijack rules go atop DSTNAT_RULES: must run for all TCP modes
		# (redirect/tproxy/tun) and BEFORE proxy redirect rules so port 53 is not stolen.
	render_dns_hijack "$access_control" > "$DSTNAT_RULES"

	
# TCP rules: redirect mode appends proxy redirect; tproxy/tun skip this chain
	case "$tcp_mode" in
		redirect)
			tcp_match="$(render_port_match tcp "$proxy_tcp_dport")"
			cat >> "$DSTNAT_RULES" <<EOF
$( render_common_returns )
$( bool_enabled "$bypass_china_ipv6" && printf '%s\n' 'ip6 daddr @clashoo_china6 return' )
$( bool_enabled "$bypass_china" && printf '%s\n' 'ip daddr @clashoo_china return' )
$( [ -n "$dscp_elements" ] && printf '%s\n' "ip dscp { ${dscp_elements} } return" )
$( [ -n "$dscp_elements" ] && printf '%s\n' "ip6 dscp { ${dscp_elements} } return" )
$( [ -n "$fwmark_elements" ] && printf '%s\n' "meta mark { ${fwmark_elements} } return" )
$( ! bool_enabled "$(config_ipv4_proxy)" && printf '%s\n' 'meta nfproto ipv4 return' )
$( ! bool_enabled "$(config_ipv6_proxy)" && printf '%s\n' 'meta nfproto ipv6 return' )
$( grouped_acl_enabled && render_acl_proxy_rules redirect tcp "$tcp_match" "$redir_port" )
$( [ "$access_control" = "1" ] && printf '%s\n' 'ip saddr != @clash_proxy_lan return' )
$( [ "$access_control" = "2" ] && printf '%s\n' 'ip saddr @clash_reject_lan return' )
$( [ "$acl_catchall" -eq 0 ] && { singbox_tun_active && printf '%s ct mark set %s redirect to :%s\n' "$tcp_match" "$SINGBOX_BYPASS_FWMARK" "$redir_port" || printf '%s redirect to :%s\n' "$tcp_match" "$redir_port"; } )
EOF
			;;
	esac

	# UDP rules: tproxy via mangle. TUN uses mangle only for LAN ACL bypass.
	# Also handle TCP tproxy mode here (both TCP+UDP in mangle).
	local need_mangle=0 tun_acl=0
	[ "$tcp_mode" = "tproxy" ] && need_mangle=1
	[ "$udp_mode" = "tproxy" ] && need_mangle=1
	if tun_acl_enabled "$access_control"; then
		need_mangle=1
		tun_acl=1
	fi

	if [ "$need_mangle" -eq 1 ]; then
		tcp_match="$(render_port_match tcp "$proxy_tcp_dport")"
		udp_match="$(render_port_match udp "$proxy_udp_dport")"
		{
			render_common_returns
			if bool_enabled "$bypass_china_ipv6"; then
				printf 'meta nfproto ipv6 ip6 daddr @clashoo_china6 return\n'
			fi
			if bool_enabled "$bypass_china"; then
				printf 'ip daddr @clashoo_china return\n'
			fi
			if [ -n "$dscp_elements" ]; then
				printf 'ip dscp { %s } return\n' "$dscp_elements"
				printf 'ip6 dscp { %s } return\n' "$dscp_elements"
			fi
			if [ -n "$fwmark_elements" ]; then
				printf 'meta mark { %s } return\n' "$fwmark_elements"
			fi
			bool_enabled "$(config_ipv4_proxy)" || printf 'meta nfproto ipv4 return\n'
			bool_enabled "$(config_ipv6_proxy)" || printf 'meta nfproto ipv6 return\n'
			if grouped_acl_enabled; then
				[ "$tcp_mode" = "tproxy" ] && render_acl_proxy_rules tproxy tcp "$tcp_match" "$tproxy_port"
				[ "$tcp_mode" = "tun" ] && printf 'meta l4proto tcp jump clashoo_acl_tun_tcp\n'
				[ "$udp_mode" = "tproxy" ] && render_acl_proxy_rules tproxy udp "$udp_match" "$tproxy_port"
				[ "$udp_mode" = "tun" ] && printf 'meta l4proto udp jump clashoo_acl_tun_udp\n'
			elif [ "$tun_acl" -eq 1 ]; then
				[ "$access_control" = "1" ] && printf 'ip saddr != @clash_proxy_lan meta mark set %s return\n' "$ACL_BYPASS_FWMARK"
				[ "$access_control" = "2" ] && printf 'ip saddr @clash_reject_lan meta mark set %s return\n' "$ACL_BYPASS_FWMARK"
			else
				[ "$access_control" = "1" ] && printf 'ip saddr != @clash_proxy_lan return\n'
				[ "$access_control" = "2" ] && printf 'ip saddr @clash_reject_lan return\n'
			fi
			if bool_enabled "$(config_block_quic)"; then
				printf 'meta l4proto udp udp dport 443 return\n'
			fi
			if [ "$tcp_mode" = "tproxy" ] && [ "$acl_catchall" -eq 0 ]; then
				if singbox_tun_active; then
					printf '%s ct mark set %s tproxy to :%s meta mark set %s accept\n' "$tcp_match" "$SINGBOX_BYPASS_FWMARK" "$tproxy_port" "$PROXY_FWMARK"
				else
					printf '%s tproxy to :%s meta mark set %s accept\n' "$tcp_match" "$tproxy_port" "$PROXY_FWMARK"
				fi
			fi
			if [ "$udp_mode" = "tproxy" ] && [ "$acl_catchall" -eq 0 ]; then
				if singbox_tun_active; then
					printf '%s ct mark set %s tproxy to :%s meta mark set %s accept\n' "$udp_match" "$SINGBOX_BYPASS_FWMARK" "$tproxy_port" "$PROXY_FWMARK"
				else
					printf '%s tproxy to :%s meta mark set %s accept\n' "$udp_match" "$tproxy_port" "$PROXY_FWMARK"
				fi
			fi
		} > "$MANGLE_RULES"
	else
		: > "$MANGLE_RULES"
	fi
}

apply_rules() {
	generate_rules
	ensure_firewall_include clash_fw4_sets "$SETS_RULES" '' table-pre
	ensure_firewall_include clash_fw4_dstnat "$DSTNAT_RULES" dstnat
	remove_firewall_include clash_fw4_output
	if [ -s "$MANGLE_RULES" ]; then
		_route_table_dec="$((PROXY_ROUTE_TABLE))"
		ensure_firewall_include clash_fw4_mangle "$MANGLE_RULES" mangle_prerouting
		ip rule show 2>/dev/null | grep -q "fwmark ${PROXY_FWMARK}.*lookup ${_route_table_dec}" ||
			ip rule add fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		ip route show table "$PROXY_ROUTE_TABLE" 2>/dev/null | grep -q 'local 0.0.0.0/0 dev lo' ||
			ip route add local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		if bool_enabled "$(config_ipv6_proxy)"; then
			ip -6 rule show 2>/dev/null | grep -q "fwmark ${PROXY_FWMARK}.*lookup ${_route_table_dec}" ||
				ip -6 rule add fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
			ip -6 route show table "$PROXY_ROUTE_TABLE" 2>/dev/null | grep -q 'local default dev lo' ||
				ip -6 route add local ::/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		else
			ip -6 rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
			ip -6 route del local ::/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		fi
	else
		remove_firewall_include clash_fw4_mangle
		ip rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		ip route del local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		ip -6 rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
		ip -6 route del local ::/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	fi
	/etc/init.d/firewall restart >/dev/null 2>&1 || /etc/init.d/firewall reload >/dev/null 2>&1 || true
	apply_acl_bypass_rules
	apply_local_output_rule
	apply_block_quic_rule
}

remove_rules() {
	remove_acl_bypass_rules
	remove_local_output_rule
	remove_block_quic_rule
	remove_firewall_include clash_fw4_sets
	remove_firewall_include clash_fw4_dstnat
	remove_firewall_include clash_fw4_output
	remove_firewall_include clash_fw4_mangle
	remove_firewall_include clash_fw4_forward
	uci commit firewall >/dev/null 2>&1 || true
	rm -f "$SETS_RULES" "$DSTNAT_RULES" "$OUTPUT_RULES" "$MANGLE_RULES"
	ip rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	ip route del local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	ip -6 rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	ip -6 route del local ::/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	/etc/init.d/firewall restart >/dev/null 2>&1 || /etc/init.d/firewall reload >/dev/null 2>&1 || true
}

case "${1:-}" in
	apply)
		apply_rules
		;;
	remove)
		remove_rules
		;;
	*)
		echo "Usage: $0 {apply|remove}" >&2
		exit 1
		;;
esac
