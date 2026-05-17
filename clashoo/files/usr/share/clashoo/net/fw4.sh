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
# PROXY_FWMARK: 入站 TPROXY 打的 mark，ip rule → table PROXY_ROUTE_TABLE 把包吸回本地给 mihomo 接收
# CORE_ROUTING_MARK: mihomo 自身出站 SO_MARK（= mihomo config 的 routing-mark）
# 两者必须不同值：否则 mihomo 出站会被 ip rule 误吸到 lo → network unreachable
# 参考 openclash 同一设计思路（0x162 + 6666）。
# 修改 CORE_ROUTING_MARK 需同步 /etc/init.d/clashoo 的 yml_change()
# 与 /usr/share/clashoo/runtime/yum_change.sh 的 routing_mark_dec。
PROXY_FWMARK="0x162"
PROXY_ROUTE_TABLE="0x162"
CORE_ROUTING_MARK="0x1a0a"  # = 6666

uci_get() {
	uci -q get "$1" 2>/dev/null || true
}

bool_enabled() {
	case "$1" in
		1|true|TRUE|yes|on) return 0 ;;
		*) return 1 ;;
	esac
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
	uci_get clashoo.config.access_control
}

config_bypass_china() {
	uci_get clashoo.config.bypass_china
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
	cat <<'EOF'
meta nfproto ipv4 ip daddr { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } return
meta nfproto ipv6 ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } return
EOF
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
	# 主动检测已安装的同类代理插件的 fwmark，合并进 bypass，避免抢截对方流量。
	# - passwall:  默认 mark 0x1
	# - passwall2: 默认 mark 0xff
	# - nikki:     默认 tproxy_fw_mark=0x80, tun_fw_mark=0x81（mask 0xff）
	# 仅当 init.d 存在时合并，避免对未安装插件无谓扩 bypass 范围。
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
	# 始终把 PROXY_FWMARK（入站 TPROXY mark）和 CORE_ROUTING_MARK（核心出站 mark）
	# 合并进用户 bypass_fwmark 列表，保证这两个 mark 始终被 nft return 放行。
	# 同时合并已安装的其他代理插件的 fwmark（passwall/passwall2/nikki），确保共存。
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

apply_local_output_rule() {
	local redir_port fake_ip_range tcp_mode bypass_fwmark bypass_china
	local fwmark_elements fwmark_rule china_set china_rule
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

	# mihomo 自身流量 mark 放行（防本机出站被自己劫持形成死循环）
	fwmark_rule=""
	fwmark_elements="$(merge_fwmark_tokens "$bypass_fwmark")"
	[ -n "$fwmark_elements" ] && fwmark_rule="meta mark { ${fwmark_elements} } return"

	# 国内 IP 旁路（复用 /usr/share/clashoo/nftables/geoip_cn.nft 的 clashoo_china set）
	china_set=""
	china_rule=""
	if bool_enabled "$bypass_china" && [ -s "$GEOIP_CN_NFT" ]; then
		china_set="$(cat "$GEOIP_CN_NFT")"
		china_rule="ip daddr @clashoo_china return"
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
	local proxy_tcp_dport proxy_udp_dport bypass_dscp bypass_fwmark
	redir_port="$(config_redir_port)"
	tproxy_port="$(config_tproxy_port)"
	tcp_mode="$(config_tcp_mode)"
	udp_mode="$(config_udp_mode)"
	access_control="$(config_access_control)"
	bypass_china="$(config_bypass_china)"
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
		printf '}\n'
	} > "$SETS_RULES"

	: > "$OUTPUT_RULES"

	# TCP rules: redirect or tproxy (tun mode needs no nftables rule)
	case "$tcp_mode" in
		redirect)
			tcp_match="$(render_port_match tcp "$proxy_tcp_dport")"
			cat > "$DSTNAT_RULES" <<EOF
ip daddr @clashoo_localnetwork return
$( bool_enabled "$bypass_china" && printf '%s\n' 'ip6 daddr @clashoo_china6 return' )
$( bool_enabled "$bypass_china" && printf '%s\n' 'ip daddr @clashoo_china return' )
$( [ "$access_control" = "1" ] && printf '%s\n' 'ip saddr != @clash_proxy_lan return' )
$( [ "$access_control" = "2" ] && printf '%s\n' 'ip saddr @clash_reject_lan return' )
$( [ -n "$dscp_elements" ] && printf '%s\n' "ip dscp { ${dscp_elements} } return" )
$( [ -n "$dscp_elements" ] && printf '%s\n' "ip6 dscp { ${dscp_elements} } return" )
$( [ -n "$fwmark_elements" ] && printf '%s\n' "meta mark { ${fwmark_elements} } return" )
${tcp_match} redirect to :${redir_port}
EOF
			;;
		tproxy)
			: > "$DSTNAT_RULES"
			;;
		*)
			# tun or unset: no TCP nftables rules
			: > "$DSTNAT_RULES"
			;;
	esac

	# UDP rules: tproxy via mangle (tun mode needs no nftables rule)
	# Also handle TCP tproxy mode here (both TCP+UDP in mangle)
	local need_mangle=0
	[ "$tcp_mode" = "tproxy" ] && need_mangle=1
	[ "$udp_mode" = "tproxy" ] && need_mangle=1

	if [ "$need_mangle" -eq 1 ]; then
		tcp_match="$(render_port_match tcp "$proxy_tcp_dport")"
		udp_match="$(render_port_match udp "$proxy_udp_dport")"
		{
			printf 'ip daddr @clashoo_localnetwork return\n'
			if bool_enabled "$bypass_china"; then
				printf 'meta nfproto ipv6 ip6 daddr @clashoo_china6 return\n'
				printf 'ip daddr @clashoo_china return\n'
			fi
			if [ "$access_control" = "1" ]; then
				printf 'ip saddr != @clash_proxy_lan return\n'
			fi
			if [ "$access_control" = "2" ]; then
				printf 'ip saddr @clash_reject_lan return\n'
			fi
			if [ -n "$dscp_elements" ]; then
				printf 'ip dscp { %s } return\n' "$dscp_elements"
				printf 'ip6 dscp { %s } return\n' "$dscp_elements"
			fi
			if [ -n "$fwmark_elements" ]; then
				printf 'meta mark { %s } return\n' "$fwmark_elements"
			fi
			if [ "$tcp_mode" = "tproxy" ]; then
				printf '%s tproxy to :%s meta mark set %s accept\n' "$tcp_match" "$tproxy_port" "$PROXY_FWMARK"
			fi
			if [ "$udp_mode" = "tproxy" ]; then
				printf '%s tproxy to :%s meta mark set %s accept\n' "$udp_match" "$tproxy_port" "$PROXY_FWMARK"
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
	else
		remove_firewall_include clash_fw4_mangle
	fi
	/etc/init.d/firewall restart >/dev/null 2>&1 || /etc/init.d/firewall reload >/dev/null 2>&1 || true
	apply_local_output_rule
}

remove_rules() {
	remove_local_output_rule
	remove_firewall_include clash_fw4_sets
	remove_firewall_include clash_fw4_dstnat
	remove_firewall_include clash_fw4_output
	remove_firewall_include clash_fw4_mangle
	uci commit firewall >/dev/null 2>&1 || true
	rm -f "$SETS_RULES" "$DSTNAT_RULES" "$OUTPUT_RULES" "$MANGLE_RULES"
	ip rule del fwmark "$PROXY_FWMARK" table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
	ip route del local 0.0.0.0/0 dev lo table "$PROXY_ROUTE_TABLE" >/dev/null 2>&1 || true
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
