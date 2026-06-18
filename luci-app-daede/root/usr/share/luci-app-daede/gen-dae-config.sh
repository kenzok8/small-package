#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# gen-dae-config.sh - build /etc/dae/config.dae from the dae UCI form sections,
# validate with `dae validate`, then overwrite + hot reload only on success.
#
#   generate   read UCI -> render config.dae -> validate -> overwrite + hot reload
#   import     parse existing config.dae subscription{}/node{} -> fill UCI form
#
# UCI model (package dae):
#   config subscription      tag/url, enabled
#   config node              tag/link, enabled
#   config group             name/policy, list source, list name_filter
#                            (old list filter_sub/filter_node still read as fallback)
#   config routing 'routing' private_direct/cn_direct/block_ads/fallback, list custom
#   config dns 'dns'         cn_upstream/fallback_upstream

. /lib/functions.sh

CONFIG_DAE="/etc/dae/config.dae"
TMP_GEN="/tmp/dae-gen.dae"
DAE_BIN="/usr/bin/dae"
DAE_INITD="/etc/init.d/dae"
SUBS_DIR="/etc/dae/subscriptions"
SUB_STAGE="/tmp/daede-sub.txt"

# dae single-quoted strings have no escaping; strip quotes/newlines defensively.
sanitize() {
	printf '%s' "$1" | tr -d "'" | tr -d '\n\r'
}

# dae subscription/node tags are bareword identifiers: only [A-Za-z0-9_] are
# valid tokens, so a CJK/spaced tag (e.g. 白月光) makes the parser choke. Map
# any such tag to a stable ASCII slug; pure-word tags pass through unchanged.
# Deterministic on the input, so a group's source reference resolves to the
# same slug as the subscription it points at. Empty stays empty (anonymous).
dae_tag() {
	[ -n "$1" ] || return 0
	case "$1" in
		*[!A-Za-z0-9_]*) printf 's_%s' "$(printf '%s' "$1" | md5sum | cut -c1-10)" ;;
		*)               printf '%s' "$1" ;;
	esac
}

# ===================== generate =====================

SUB_BUF=""
NODE_BUF=""
GROUP_BUF=""
FIRST_GROUP=""

emit_sub() {
	local s="$1" tag url enabled
	config_get tag "$s" tag ""
	config_get url "$s" url ""
	config_get_bool enabled "$s" enabled 1
	[ "$enabled" = "1" ] || return 0
	url="$(sanitize "$url")"
	[ -n "$url" ] || return 0
	tag="$(dae_tag "$(sanitize "$tag")")"
	if [ -n "$tag" ]; then
		SUB_BUF="${SUB_BUF}    ${tag}: '${url}'
"
	else
		SUB_BUF="${SUB_BUF}    '${url}'
"
	fi
}

emit_node() {
	local s="$1" tag link enabled
	config_get tag "$s" tag ""
	config_get link "$s" link ""
	config_get_bool enabled "$s" enabled 1
	[ "$enabled" = "1" ] || return 0
	link="$(sanitize "$link")"
	[ -n "$link" ] || return 0
	tag="$(dae_tag "$(sanitize "$tag")")"
	if [ -n "$tag" ]; then
		NODE_BUF="${NODE_BUF}    ${tag}: '${link}'
"
	else
		NODE_BUF="${NODE_BUF}    '${link}'
"
	fi
}

emit_group() {
	local s="$1" name policy
	config_get name "$s" name ""
	config_get policy "$s" policy "min_moving_avg"
	name="$(sanitize "$name")"
	[ -n "$name" ] || return 0
	# dae fatals on duplicate outbound names; keep the first, skip later dupes
	case " $GROUP_NAMES_SEEN " in *" $name "*) return 0 ;; esac
	GROUP_NAMES_SEEN="$GROUP_NAMES_SEEN $name"
	[ -n "$FIRST_GROUP" ] || FIRST_GROUP="$name"

	GROUP_BUF="${GROUP_BUF}    ${name} {
"
	# Build the source: 'source' entries that match a subscription tag become
	# subtag(), the rest (node tags / keywords) become name(). Old filter_sub /
	# filter_node configs still work as a fallback when 'source' is unset.
	SUBS_ACC=""; NODES_ACC=""; KW_ACC=""
	# source: new field, else old filter_sub (decoupled from the name filter so
	# editing one never silently drops the other)
	config_list_foreach "$s" source _collect_source
	[ -z "$SUBS_ACC" ] && [ -z "$NODES_ACC" ] && config_list_foreach "$s" filter_sub _collect_source
	# optional name filter narrows the subscription pool only (AND); hand-picked
	# nodes are explicit choices and stay in unconditionally
	config_list_foreach "$s" name_filter _collect_kw
	[ -z "$KW_ACC" ] && config_list_foreach "$s" filter_node _collect_kw
	local andclause=""
	[ -n "$KW_ACC" ] && andclause=" && name(${KW_ACC})"

	local emitted=0
	# multiple filter lines = OR, so subtag and name lines union the sources
	if [ -n "$SUBS_ACC" ]; then
		GROUP_BUF="${GROUP_BUF}        filter: subtag(${SUBS_ACC})${andclause}
"
		emitted=1
	fi
	if [ -n "$NODES_ACC" ]; then
		GROUP_BUF="${GROUP_BUF}        filter: name(${NODES_ACC})
"
		emitted=1
	fi
	# name filter with no source = filter the whole pool by name
	if [ "$emitted" = 0 ] && [ -n "$KW_ACC" ]; then
		GROUP_BUF="${GROUP_BUF}        filter: name(${KW_ACC})
"
	fi
	GROUP_BUF="${GROUP_BUF}        policy: ${policy}
    }
"
	SUBS_ACC=""; NODES_ACC=""; KW_ACC=""
}

SUBS_ACC=""
NODES_ACC=""
KW_ACC=""
# Subscription tags, space-padded for membership tests (" tag " match).
SUB_TAGS=""
collect_subtag() {
	local t; config_get t "$1" tag ""
	t="$(dae_tag "$(sanitize "$t")")"
	[ -n "$t" ] && SUB_TAGS="${SUB_TAGS} ${t} "
}
is_subtag() {
	case "$SUB_TAGS" in *" $1 "*) return 0 ;; *) return 1 ;; esac
}
# dae filter args are bare only for plain identifiers; anything with regex
# chars / CJK / spaces must be wrapped as regex: '...' or the lexer chokes.
filter_arg() {
	case "$1" in
		*[!A-Za-z0-9_]*) printf "regex: '%s'" "$1" ;;
		*)               printf '%s' "$1" ;;
	esac
}
# name-filter args do substring matching: regex metachars -> regex:, else keyword:.
# Intentionally stricter than filter_arg: a plain CJK keyword here stays a
# substring `keyword:` match, whereas filter_arg wraps any non-word char as regex.
kw_arg() {
	if printf '%s' "$1" | grep -q '[][|().*+?^$\\]'; then
		printf "regex: '%s'" "$1"
	else
		printf "keyword: '%s'" "$1"
	fi
}
# classify a source entry: subscription tag -> subtag bucket, else name bucket
_collect_source() {
	local v="$(sanitize "$1")"
	[ -n "$v" ] || return 0
	# subscription refs resolve to the (ASCII) dae tag; node-name refs keep the
	# original text (matched as a quoted regex against node names)
	local dt="$(dae_tag "$v")"
	if is_subtag "$dt"; then
		SUBS_ACC="${SUBS_ACC:+$SUBS_ACC, }$(filter_arg "$dt")"
	else
		NODES_ACC="${NODES_ACC:+$NODES_ACC, }$(filter_arg "$v")"
	fi
}
_collect_kw() {
	local v="$(sanitize "$1")"
	[ -n "$v" ] || return 0
	KW_ACC="${KW_ACC:+$KW_ACC, }$(kw_arg "$v")"
}

generate() {
	config_load dae

	# global overridable knobs (fall back to defaults)
	local dial_mode log_level wan_interface lan_interface
	config_get dial_mode config dial_mode "domain"
	config_get log_level config log_level "info"
	config_get wan_interface config wan_interface "auto"
	config_get lan_interface config lan_interface ""

	SUB_BUF=""; NODE_BUF=""; GROUP_BUF=""; FIRST_GROUP=""; GROUP_NAMES_SEEN=""
	SUB_TAGS=""
	config_foreach collect_subtag subscription
	config_foreach emit_sub subscription
	config_foreach emit_node node
	config_foreach emit_group group

	# fall back to a default group when none defined
	if [ -z "$GROUP_BUF" ]; then
		GROUP_BUF="    proxy {
        policy: min_moving_avg
    }
"
		FIRST_GROUP="proxy"
	fi

	# routing / dns singletons
	local private_direct cn_direct block_ads fallback cn_up fb_up
	config_get_bool private_direct routing private_direct 1
	config_get_bool cn_direct routing cn_direct 1
	config_get_bool block_ads routing block_ads 0
	config_get fallback routing fallback "$FIRST_GROUP"
	[ -n "$fallback" ] || fallback="$FIRST_GROUP"
	fallback="$(sanitize "$fallback")"
	config_get cn_up dns cn_upstream "udp://dns.alidns.com:53"
	config_get fb_up dns fallback_upstream "tcp+udp://dns.google:53"
	cn_up="$(sanitize "$cn_up")"
	fb_up="$(sanitize "$fb_up")"

	{
		echo "# Auto-generated by luci-app-daede form. Manual edits are overwritten on next save."
		echo "global {"
		echo "    tproxy_port: 12345"
		echo "    tproxy_port_protect: true"
		echo "    log_level: ${log_level}"
		[ -n "$lan_interface" ] && echo "    lan_interface: ${lan_interface}"
		echo "    wan_interface: ${wan_interface}"
		echo "    auto_config_kernel_parameter: true"
		echo "    dial_mode: ${dial_mode}"
		echo "    tcp_check_url: 'http://cp.cloudflare.com,1.1.1.1,2606:4700:4700::1111'"
		echo "    udp_check_dns: 'dns.google:53,8.8.8.8,2001:4860:4860::8888'"
		echo "    check_interval: 30s"
		echo "    check_tolerance: 50ms"
		echo "}"
		echo ""

		if [ -n "$SUB_BUF" ]; then
			echo "subscription {"
			printf '%s' "$SUB_BUF"
			echo "}"
			echo ""
		fi

		if [ -n "$NODE_BUF" ]; then
			echo "node {"
			printf '%s' "$NODE_BUF"
			echo "}"
			echo ""
		fi

		echo "dns {"
		echo "    ipversion_prefer: 4"
		echo "    upstream {"
		echo "        cndns: '${cn_up}'"
		echo "        fallbackdns: '${fb_up}'"
		echo "    }"
		echo "    routing {"
		echo "        request {"
		[ "$block_ads" = "1" ] && echo "            qname(geosite:category-ads-all) -> reject"
		echo "            qname(geosite:cn) -> cndns"
		echo "            fallback: fallbackdns"
		echo "        }"
		echo "    }"
		echo "}"
		echo ""

		echo "group {"
		printf '%s' "$GROUP_BUF"
		echo "}"
		echo ""

		echo "routing {"
		echo "    pname(NetworkManager) -> direct"
		# multicast / broadcast direct (geoip:private doesn't cover these)
		echo "    dip(224.0.0.0/3) -> direct"
		echo "    dip(255.255.255.255/32) -> direct"
		echo "    dip('ff00::/8') -> direct"
		[ "$private_direct" = "1" ] && echo "    dip(geoip:private) -> direct"
		# NTP time sync direct
		echo "    l4proto(udp) && dport(123) -> direct"
		# OS connectivity checks direct (avoid captive-portal false positives)
		echo "    domain(connectivitycheck.gstatic.com) -> direct"
		echo "    domain(msftconnecttest.com) -> direct"
		if [ "$cn_direct" = "1" ]; then
			echo "    dip(geoip:cn) -> direct"
			echo "    domain(geosite:cn) -> direct"
		fi
		[ "$block_ads" = "1" ] && echo "    domain(geosite:category-ads-all) -> block"
		config_list_foreach routing custom _emit_custom
		echo "    fallback: ${fallback}"
		echo "}"
	} > "$TMP_GEN"
	chmod 600 "$TMP_GEN"  # dae rejects world/group-accessible config files

	# overwrite live config only if validation passes
	local out
	out="$("$DAE_BIN" validate -c "$TMP_GEN" 2>&1)"
	if [ $? -ne 0 ]; then
		echo "validate failed: $(echo "$out" | head -1)" >&2
		rm -f "$TMP_GEN"
		return 1
	fi

	mkdir -p /etc/dae
	cat "$TMP_GEN" > "$CONFIG_DAE"
	chmod 600 "$CONFIG_DAE"
	rm -f "$TMP_GEN"

	if /usr/bin/pgrep -x dae >/dev/null 2>&1; then
		"$DAE_INITD" hot_reload >/dev/null 2>&1
	fi
	echo "ok"
	return 0
}

_emit_custom() {
	local line="$(printf '%s' "$1" | tr -d '\n\r')"
	[ -n "$line" ] || return 0
	echo "    ${line}"
}

# ===================== import =====================
# Fill the UCI form from an existing config.dae subscription{}/node{} block.
# Idempotent: wipe same-type sections first, then rebuild from file.

import_block() {
	# $1=block name (subscription|node)  $2=uci section type  $3=link/url field
	local block="$1" stype="$2" field="$3"
	awk -v blk="$block" '
		$0 ~ "^[[:space:]]*"blk"[[:space:]]*\\{" { inb=1; next }
		inb && /^[[:space:]]*\}/ { inb=0 }
		inb { print }
	' "$CONFIG_DAE" 2>/dev/null | while IFS= read -r raw; do
		# drop comment, trim
		line="$(printf '%s' "$raw" | sed 's/#.*$//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
		[ -n "$line" ] || continue
		tag=""; val=""
		case "$line" in
			\'*|\"*)
				# starts with a quote -> untagged link
				val="$line"
				;;
			[A-Za-z0-9_]*:*)
				# identifier ':' link -> tagged (split on first colon)
				tag="$(printf '%s' "$line" | sed "s/[[:space:]]*:.*//")"
				val="$(printf '%s' "$line" | sed "s/^[^:]*:[[:space:]]*//")"
				;;
			*)
				val="$line"
				;;
		esac
		# strip surrounding quotes
		val="$(printf '%s' "$val" | sed "s/^['\"]//; s/['\"]$//")"
		[ -n "$val" ] || continue
		# skip dae example placeholders (ss://LINK, server-ip:port, localhost:1080 ...)
		case "$val" in
			*://LINK|*LINK*|*server-ip*|*://localhost:*|*example.com*) continue ;;
		esac
		sid="$(uci add dae "$stype")"
		[ -n "$tag" ] && uci set "dae.$sid.tag=$tag"
		uci set "dae.$sid.$field=$val"
		uci set "dae.$sid.enabled=1"
	done
}

do_import() {
	[ -f "$CONFIG_DAE" ] || { echo "no config.dae" >&2; return 1; }
	while uci -q delete dae.@subscription[0] >/dev/null 2>&1; do :; done
	while uci -q delete dae.@node[0] >/dev/null 2>&1; do :; done
	import_block subscription subscription url
	import_block node node link
	uci commit dae
	echo "ok"
}

# Converter writes a batch of share links to a local file that dae reads as a
# file:// subscription, so a converted airport is one subscription instead of
# hundreds of manual nodes. $1=id (airport id), reads links from SUB_STAGE.
# id is restricted to [A-Za-z0-9_] to keep the path inside SUBS_DIR.
do_write_sub() {
	local id="$1"
	case "$id" in ''|*[!A-Za-z0-9_]*) echo "bad id" >&2; return 2 ;; esac
	[ -f "$SUB_STAGE" ] || { echo "no staged data" >&2; return 1; }
	mkdir -p "$SUBS_DIR"
	# dae rejects subscription/config files readable by group/other (needs <=0640)
	cp "$SUB_STAGE" "$SUBS_DIR/$id.sub.tmp" || { echo "write failed" >&2; return 1; }
	chmod 0600 "$SUBS_DIR/$id.sub.tmp"
	mv "$SUBS_DIR/$id.sub.tmp" "$SUBS_DIR/$id.sub"
	rm -f "$SUB_STAGE"
	echo "ok"
}

do_delete_sub() {
	local id="$1"
	case "$id" in ''|*[!A-Za-z0-9_]*) return 0 ;; esac
	rm -f "$SUBS_DIR/$id.sub"
	echo "ok"
}

# ===================== entry =====================

case "$1" in
	generate)   generate ;;
	import)     do_import ;;
	write-sub)  do_write_sub "$2" ;;
	delete-sub) do_delete_sub "$2" ;;
	*) echo "usage: $0 {generate|import|write-sub <id>|delete-sub <id>}" >&2; exit 2 ;;
esac
