#!/bin/sh

CONFIG_YAML="/etc/clashoo/config.yaml"
NFT_V4="/usr/share/clashoo/nftables/geoip_cn.nft"
NFT_V6="/usr/share/clashoo/nftables/geoip6_cn.nft"
MAX_CONN=200

uci_get() {
	uci -q get "clashoo.config.$1" 2>/dev/null
}

section() {
	printf '\n===== %s =====\n' "$1"
}

yesno() {
	[ -n "$1" ] && [ "$1" != "0" ] && [ "$1" != "false" ] && echo "on" || echo "off"
}

section "配置摘要"
printf '服务开关      : %s\n' "$(yesno "$(uci_get enable)")"
printf '运行模式      : %s\n' "$(uci_get enhanced_mode)"
printf 'TCP / UDP     : %s / %s\n' "$(uci_get tcp_mode)" "$(uci_get udp_mode)"
printf '大陆绕过 v4   : %s\n' "$(yesno "$(uci_get bypass_china)")"
printf '大陆绕过 v6   : %s\n' "$(yesno "$(uci_get bypass_china_ipv6)")"
printf '接管端口      : %s' "$(uci_get bypass_port_mode)"
[ "$(uci_get bypass_port_mode)" = "custom" ] && printf ' (%s)' "$(uci_get bypass_port_custom)"
printf '\n'
printf 'IPv6 代理     : %s\n' "$(yesno "$(uci_get ipv6_proxy)")"
printf '阻断 QUIC     : %s\n' "$(yesno "$(uci_get block_quic)")"

if [ "$(uci_get bypass_port_mode)" = "common" ]; then
	printf '\n注意: 接管端口为 common，只代理 22/53/80/443/8080/8443，\n'
	printf '      游戏与 P2P 常用的高位端口不会走代理。\n'
fi

section "fake-ip 过滤"
if [ -s "$CONFIG_YAML" ]; then
	if grep -qE '^[[:space:]]*fake-ip-filter:' "$CONFIG_YAML" 2>/dev/null; then
		if grep -q 'rule-set:cn_domain' "$CONFIG_YAML" 2>/dev/null; then
			echo "含 rule-set:cn_domain (国内域名返回真实 IP)"
		else
			echo "缺少 rule-set:cn_domain"
			echo "  国内域名会拿到 fake-ip 走代理，与硬编码国内 IP 分成两条路。"
		fi
	else
		echo "配置中无 fake-ip-filter"
	fi
else
	echo "找不到 $CONFIG_YAML"
fi

section "内核分流规则"
if [ -s "$CONFIG_YAML" ]; then
	echo "-- rules 末尾 5 条 --"
	grep -E '^[[:space:]]*-[[:space:]]*["'"'"']?(GEOIP|RULE-SET|MATCH|IP-CIDR|DOMAIN)' "$CONFIG_YAML" 2>/dev/null | tail -5
	echo
	if grep -qiE '^[[:space:]]*-[[:space:]]*["'"'"']?(GEOIP,[[:space:]]*CN,|RULE-SET,[[:space:]]*[A-Za-z0-9_.-]*(cn|china)[A-Za-z0-9_.-]*,)' "$CONFIG_YAML" 2>/dev/null; then
		echo "国内直连兜底: 有"
		grep -inE '^[[:space:]]*-[[:space:]]*["'"'"']?(GEOIP,[[:space:]]*CN,|RULE-SET,[[:space:]]*[A-Za-z0-9_.-]*(cn|china)[A-Za-z0-9_.-]*,)' "$CONFIG_YAML" 2>/dev/null | head -3
	else
		echo "国内直连兜底: 无"
		echo "  防火墙漏判的国内 IP 进内核后会落到 MATCH 走代理。"
	fi
fi

section "IP 库"
for f in "$NFT_V4" "$NFT_V6"; do
	if [ -s "$f" ]; then
		printf '%-46s %6s 条  %s\n' "$f" \
			"$(grep -cE '^[[:space:]]*[0-9a-fA-F].*/' "$f" 2>/dev/null)" \
			"$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null)"
	else
		printf '%-46s 缺失\n' "$f"
	fi
done
if [ -s /etc/clashoo/ruleset/cn-ip.txt ]; then
	printf '%-46s %6s 条  %s\n' "/etc/clashoo/ruleset/cn-ip.txt" \
		"$(wc -l < /etc/clashoo/ruleset/cn-ip.txt 2>/dev/null | tr -d ' ')" \
		"$(date -r /etc/clashoo/ruleset/cn-ip.txt '+%Y-%m-%d %H:%M' 2>/dev/null)"
fi
for f in /etc/clashoo/Country.mmdb /etc/clashoo/geoip.metadb; do
	[ -f "$f" ] && printf '%-46s %s\n' "$f" "$(ls -lh "$f" 2>/dev/null | awk '{print $5}')"
done

set_count() {
	nft list set inet fw4 "$1" 2>/dev/null | tr ',' '\n' | grep -cE '[0-9a-fA-F]+[.:].*/'
}

section "防火墙绕过规则"
if nft list sets inet fw4 2>/dev/null | grep -q clashoo_china; then
	for ch in dstnat mangle_prerouting; do
		nft -a list chain inet fw4 "$ch" 2>/dev/null |
			grep -E '@clashoo_china6? ' | sed "s|^[[:space:]]*|  ${ch}: |"
	done
	echo
	echo "已加载元素数（nft auto-merge 会合并相邻网段，少于文件行数属正常）:"
	printf '  clashoo_china  : %s\n' "$(set_count clashoo_china)"
	printf '  clashoo_china6 : %s\n' "$(set_count clashoo_china6)"
else
	echo "当前 nftables 中没有 clashoo_china 集合（绕过未启用或服务未运行）"
fi

section "出口劈叉检查"
SECRET="$(uci_get dash_pass)"
PORT="$(uci_get dash_port)"
LAN_IP="$(uci -q get network.lan.ipaddr 2>/dev/null | awk -F/ '{print $1}')"
[ -n "$LAN_IP" ] || LAN_IP="127.0.0.1"
CONN_JSON="/tmp/.clashoo_diag_conn.$$"

if [ -z "$PORT" ]; then
	echo "未配置控制端口，跳过"
elif ! curl -m 5 -s -H "Authorization: Bearer ${SECRET}" \
	"http://${LAN_IP}:${PORT}/connections" -o "$CONN_JSON" 2>/dev/null; then
	echo "无法访问内核 API (http://${LAN_IP}:${PORT})，跳过"
elif [ ! -s "$CONN_JSON" ]; then
	echo "内核 API 返回为空，跳过"
else
	jsonfilter -i "$CONN_JSON" -e '@["connections"][*]["metadata"]["destinationIP"]' \
		2>/dev/null > "${CONN_JSON}.ip"
	jsonfilter -i "$CONN_JSON" -e '@["connections"][*]["chains"][0]' \
		2>/dev/null > "${CONN_JSON}.ch"

	total="$(wc -l < "${CONN_JSON}.ip" 2>/dev/null | tr -d ' ')"
	[ -n "$total" ] || total=0

	if [ "$total" -eq 0 ]; then
		echo "当前无活动连接"
	elif [ "$total" != "$(wc -l < "${CONN_JSON}.ch" 2>/dev/null | tr -d ' ')" ]; then
		echo "内核 API 字段数不一致，跳过"
	else
		awk 'NR==FNR { a[FNR] = $0; next } { print a[FNR] "\t" $0 }' \
			"${CONN_JSON}.ip" "${CONN_JSON}.ch" 2>/dev/null \
			| awk -F'\t' '$2 != "DIRECT" && $1 != "" && $1 !~ /^(198\.18\.|::|fc00:|fd)/ { print $1 "\t" $2 }' \
			| sort -u | head -n "$MAX_CONN" > "${CONN_JSON}.chk"

		split=0
		: > "${CONN_JSON}.bad"
		while IFS="$(printf '\t')" read -r dip chain; do
			[ -n "$dip" ] || continue
			if nft get element inet fw4 clashoo_china "{ $dip }" >/dev/null 2>&1 ||
				nft get element inet fw4 clashoo_china6 "{ $dip }" >/dev/null 2>&1; then
				split=$((split + 1))
				printf '  %-40s -> %s\n' "$dip" "$chain" >> "${CONN_JSON}.bad"
			fi
		done < "${CONN_JSON}.chk"

		printf '活动连接 %s 条，其中走代理的去重目的地 %s 个（上限 %s）\n' \
			"$total" "$(wc -l < "${CONN_JSON}.chk" 2>/dev/null | tr -d ' ')" "$MAX_CONN"
		if [ "$split" -gt 0 ]; then
			printf '国内 IP 却走了代理: %s 个\n\n' "$split"
			head -20 "${CONN_JSON}.bad"
			echo
			echo "这些连接的出口是代理节点 IP，而同一应用命中绕过的连接出口是家宽 IP。"
			echo "同一会话出现两个公网出口，游戏与银行类服务可能判定为异常。"
		else
			echo "未发现国内 IP 走代理的连接"
		fi
		rm -f "${CONN_JSON}.chk" "${CONN_JSON}.bad" 2>/dev/null
	fi
	rm -f "${CONN_JSON}.ip" "${CONN_JSON}.ch" 2>/dev/null
fi
rm -f "$CONN_JSON" 2>/dev/null

printf '\n'
