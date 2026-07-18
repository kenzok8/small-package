#!/bin/sh

APPLY=0
TIMEOUT="${CLASHOO_DNS_TEST_TIMEOUT:-2}"
START_TS="$(date +%s 2>/dev/null || echo 0)"

while [ $# -gt 0 ]; do
	case "$1" in
		--apply) APPLY=1 ;;
	esac
	shift
done

json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

json_pair() {
	printf '"%s":"%s"' "$1" "$(json_escape "$2")"
}

is_ipv4() {
	echo "$1" | grep -Eq '^[0-9]+(\.[0-9]+){3}$'
}

append_unique() {
	list="$1"
	item="$2"
	[ -n "$item" ] || { printf '%s' "$list"; return; }
	case " $list " in
		*" $item "*) printf '%s' "$list" ;;
		*) printf '%s %s' "$list" "$item" ;;
	esac
}

current_default_nameservers() {
	uci -q get clashoo.config.default_nameserver 2>/dev/null || true
}

current_dns_servers() {
	uci -q show clashoo 2>/dev/null | awk -F= '
	function clean(v) {
		gsub(/^'\''|'\''$/, "", v);
		return v;
	}
	/^clashoo\.@dnsservers\[[0-9]+\]\./ {
		line=$1;
		val=clean($2);
		sub(/^clashoo\.@dnsservers\[/, "", line);
		idx=line;
		sub(/\].*$/, "", idx);
		opt=line;
		sub(/^[0-9]+\]\./, "", opt);
		data[idx, opt]=val;
		seen[idx]=1;
	}
	END {
		for (idx in seen) {
			if (data[idx, "enabled"] == "0") continue;
			role=data[idx, "ser_type"];
			addr=data[idx, "ser_address"];
			proto=data[idx, "protocol"];
			port=data[idx, "ser_port"];
			if (addr == "") continue;
			if (proto != "" && proto != "none" && addr !~ /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//) {
				addr=proto addr;
				if (port != "" && addr !~ /:[0-9]+$/) addr=addr ":" port;
			}
			print role "|" addr;
		}
	}'
}

servers_for_role() {
	role="$1"
	current_dns_servers | awk -F'|' -v role="$role" '$1 == role { print $2 }'
}

candidate_host_port() {
	uri="$1"
	default_port="$2"
	hostport="${uri#*://}"
	hostport="${hostport%%/*}"
	host="${hostport%%:*}"
	port="${hostport##*:}"
	[ "$port" != "$hostport" ] || port="$default_port"
	printf '%s %s\n' "$host" "$port"
}

probe_tls() {
	uri="$1"
	set -- $(candidate_host_port "$uri" 853)
	host="$1"
	port="$2"
	command -v nc >/dev/null 2>&1 || return 1
	nc -w "$TIMEOUT" "$host" "$port" >/dev/null 2>&1
}

probe_ip_dns() {
	ip="$1"
	domain="$2"
	command -v nslookup >/dev/null 2>&1 || return 1
	nslookup "$domain" "$ip" >/dev/null 2>&1
}

probe_latency_ms() {
	candidate="$1"
	domain="$2"
	if [ "${candidate#https://}" != "$candidate" ]; then
		if printf '%s' "$candidate" | grep -q '?'; then
			q="$candidate&name=$domain&type=A"
		else
			q="$candidate?name=$domain&type=A"
		fi
		command -v curl >/dev/null 2>&1 || return 1
		t="$(curl -fsS --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" \
			-H 'accept: application/dns-json' -o /dev/null -w '%{time_total}' "$q" 2>/dev/null)" || return 1
		printf '%s' "$t" | awk '{ms=$1*1000; if (ms<1) ms=1; printf "%d", ms}'
	elif [ "${candidate#tls://}" != "$candidate" ]; then
		probe_tls "$candidate" || return 1
		printf '900'
	elif [ "${candidate#udp://}" != "$candidate" ]; then
		probe_ip_dns "${candidate#udp://}" "$domain" || return 1
		printf '950'
	elif [ "${candidate#tcp://}" != "$candidate" ]; then
		probe_ip_dns "${candidate#tcp://}" "$domain" || return 1
		printf '950'
	else
		is_ipv4 "$candidate" && probe_ip_dns "$candidate" "$domain" || return 1
		printf '950'
	fi
}

select_best() {
	list="$1"
	domain="$2"
	fallback="$3"
	best=""
	best_score=999999
	order=0
	for candidate in $list; do
		order=$((order + 1))
		ms="$(probe_latency_ms "$candidate" "$domain")" || { FAILED_COUNT=$((FAILED_COUNT + 1)); continue; }
		score=$((ms * 100 + order))
		if [ "$score" -lt "$best_score" ]; then
			best="$candidate"
			best_score="$score"
		fi
	done
	[ -n "$best" ] || best="$fallback"
	printf '%s' "$best"
}

add_dnsserver() {
	role="$1"
	addr="$2"
	proto="$3"
	port="$4"
	sec="$(uci -q add clashoo dnsservers)" || return 1
	[ -n "$sec" ] || return 1
	uci -q set clashoo."$sec".enabled='1' || return 1
	uci -q set clashoo."$sec".ser_type="$role" || return 1
	uci -q set clashoo."$sec".ser_address="$addr" || return 1
	uci -q set clashoo."$sec".protocol="$proto" || return 1
	if [ -n "$port" ]; then
		uci -q set clashoo."$sec".ser_port="$port" || return 1
	fi
	return 0
}

set_default_nameserver() {
	uci -q delete clashoo.config.default_nameserver >/dev/null 2>&1 || true
	uci -q add_list clashoo.config.default_nameserver="$1" || return 1
	return 0
}

apply_result() {
	uci -q set clashoo.config.enable_dns='1' || { uci -q revert clashoo; return 1; }
	set_default_nameserver "$BOOTSTRAP" || { uci -q revert clashoo; return 1; }
	while uci -q delete clashoo.@dnsservers[0] >/dev/null 2>&1; do :; done
	add_dnsserver 'nameserver' "$NAMESERVER" 'none' '' || { uci -q revert clashoo; return 1; }
	add_dnsserver 'direct-nameserver' "$BOOTSTRAP" 'udp://' '' || { uci -q revert clashoo; return 1; }
	add_dnsserver 'proxy-server-nameserver' "$PROXY_NS" 'none' '' || { uci -q revert clashoo; return 1; }
	add_dnsserver 'fallback' "$FALLBACK_NS" 'none' '' || { uci -q revert clashoo; return 1; }
	uci -q commit clashoo || { uci -q revert clashoo; return 1; }
	return 0
}

is_domestic_dns() {
	printf '%s' "$1" | grep -qE 'alidns|doh\.pub|dnspod|223\.5\.5\.5|223\.6\.6\.6|119\.29\.29\.29|119\.28\.28\.28|114\.114|180\.184|onedns'
}
is_overseas_dns() {
	printf '%s' "$1" | grep -qE 'cloudflare|1\.1\.1\.1|1\.0\.0\.1|one\.one\.one\.one|dns\.google|8\.8\.8\.8|8\.8\.4\.4|9\.9\.9\.9|quad9|opendns|208\.67\.'
}

FAILED_COUNT=0
BOOTSTRAP_CANDIDATES="223.5.5.5 119.29.29.29 180.184.1.1"
DOMESTIC_CANDIDATES="https://dns.alidns.com/dns-query https://doh.pub/dns-query udp://223.5.5.5 udp://119.29.29.29"
FALLBACK_CANDIDATES="https://cloudflare-dns.com/dns-query https://dns.google/dns-query tls://1.1.1.1:853"

for ns in $(current_default_nameservers); do
	is_ipv4 "$ns" && BOOTSTRAP_CANDIDATES="$(append_unique "$BOOTSTRAP_CANDIDATES" "$ns")"
done
for ns in $(servers_for_role 'nameserver') $(servers_for_role 'direct-nameserver'); do
	is_domestic_dns "$ns" && DOMESTIC_CANDIDATES="$(append_unique "$DOMESTIC_CANDIDATES" "$ns")"
done
for ns in $(servers_for_role 'fallback'); do
	is_overseas_dns "$ns" && FALLBACK_CANDIDATES="$(append_unique "$FALLBACK_CANDIDATES" "$ns")"
done

BOOTSTRAP="$(select_best "$BOOTSTRAP_CANDIDATES" www.baidu.com 223.5.5.5)"
NAMESERVER="$(select_best "$DOMESTIC_CANDIDATES" www.baidu.com https://dns.alidns.com/dns-query)"
PROXY_NS="tls://1.1.1.1:853"
FALLBACK_NS="$(select_best "$FALLBACK_CANDIDATES" www.google.com https://cloudflare-dns.com/dns-query)"

APPLIED=false
if [ "$APPLY" = "1" ]; then
	if apply_result; then
		APPLIED=true
	else
		printf '{"success":false,"error":"apply_failed","message":"DNS 自动配置写入失败"}\n'
		exit 1
	fi
fi

END_TS="$(date +%s 2>/dev/null || echo "$START_TS")"
ELAPSED_MS=$(( (END_TS - START_TS) * 1000 ))

printf '{'
printf '"success":true,'
printf '"applied":%s,' "$APPLIED"
printf '"restarted":false,'
json_pair bootstrap "$BOOTSTRAP"; printf ','
json_pair nameserver "$NAMESERVER"; printf ','
json_pair direct_nameserver "$BOOTSTRAP"; printf ','
json_pair proxy_nameserver "$PROXY_NS"; printf ','
json_pair fallback "$FALLBACK_NS"; printf ','
printf '"failed_count":%s,' "$FAILED_COUNT"
printf '"elapsed_ms":%s' "$ELAPSED_MS"
printf '}\n'
