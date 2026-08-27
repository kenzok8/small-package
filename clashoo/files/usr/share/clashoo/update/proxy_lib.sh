# shellcheck shell=sh
# Shared proxy detection for clashoo's own outbound requests.
#
# clashoo's self-initiated downloads (update checks, component/panel/core/geoip
# downloads, subscriptions) and health checks must reach GitHub through the
# running core, otherwise they leak out direct and stall behind the GFW. Route
# them through the core's mixed port whenever a core is running — in BOTH modes:
#   - core-only mode deliberately skips TPROXY to coexist with other plugins;
#   - normal mode used to rely on transparent redirect, but the router's OWN
#     output redirect is fragile (e.g. PPPoE/GL.iNet stacks where Redirect to
#     loopback never completes — issue #25), so don't depend on it. The explicit
#     mixed port works on every network stack.
# When no core is running (e.g. bootstrapping the very first core download),
# returns empty so the caller falls back to direct / mirror sources.
#
# Port source depends on the running Clashoo kernel. The liveness gate uses the
# procd owner instead of a binary name, because other proxy plugins may run the
# same binaries:
#   sing-box                      -> /etc/sing-box/config.json mixed inbound
#                                    (an imported profile may carry its own port)
#   mihomo / clash-meta / smart   -> /etc/clashoo/config.yaml mixed-port
#                                    (a custom config's port may differ from uci)
# uci mixed_port is the last-resort fallback for both.
clashoo_running_core_type() {
	_cdp_type="$(uci -q get clashoo.config.core_type 2>/dev/null)"
	case "$_cdp_type" in
		singbox)
			# Clashoo owns this service only after it has configured the
			# packaged sing-box init script for its own runtime config.
			[ "$(uci -q get sing-box.main.conffile 2>/dev/null)" = "/etc/sing-box/config.json" ] || return 1
			_cdp_service="sing-box"
			_cdp_filter='@["sing-box"].instances.*.pid'
			;;
		*)
			_cdp_type="mihomo"
			_cdp_service="clashoo"
			_cdp_filter='@.clashoo.instances.*.pid'
			;;
	esac

	_cdp_pid="$(ubus call service list "{\"name\":\"$_cdp_service\",\"verbose\":true}" 2>/dev/null \
		| jsonfilter -e "$_cdp_filter" 2>/dev/null | head -n1)"
	[ -n "$_cdp_pid" ] && [ -d "/proc/$_cdp_pid" ] || return 1
	printf '%s' "$_cdp_type"
}

clashoo_detect_proxy() {
	_cdp_type="$(clashoo_running_core_type)" || return 0
	_cdp_port=""
	if [ "$_cdp_type" = "singbox" ]; then
		_cdp_port="$(jsonfilter -i /etc/sing-box/config.json \
			-e '@.inbounds[@.type="mixed"].listen_port' 2>/dev/null | head -n 1)"
	else
		# prefer mixed-port (HTTP+SOCKS) over plain port; a single two-pattern
		# sed would return whichever appears first by line order, so loop by key
		for _cdp_key in mixed-port port socks-port; do
			_cdp_port="$(sed -n "s/^[[:space:]]*${_cdp_key}:[[:space:]]*\([0-9][0-9]*\).*/\1/p" \
				/etc/clashoo/config.yaml 2>/dev/null | head -n 1)"
			[ -n "$_cdp_port" ] && break
		done
	fi
	[ -n "$_cdp_port" ] || _cdp_port="$(uci -q get clashoo.config.mixed_port 2>/dev/null)"
	[ -n "$_cdp_port" ] || return 0
	printf 'http://127.0.0.1:%s' "$_cdp_port"
}
