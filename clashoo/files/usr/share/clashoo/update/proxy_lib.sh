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
# Port source depends on the running kernel (no `ss` on this busybox, so the
# liveness gate is pidof, not a listening-socket probe):
#   sing-box                      -> /etc/sing-box/config.json mixed inbound
#                                    (an imported profile may carry its own port)
#   mihomo / clash-meta / smart   -> /etc/clashoo/config.yaml mixed-port
#                                    (a custom config's port may differ from uci)
# uci mixed_port is the last-resort fallback for both.
clashoo_detect_proxy() {
	_cdp_port=""
	if pidof sing-box >/dev/null 2>&1; then
		_cdp_port="$(jsonfilter -i /etc/sing-box/config.json \
			-e '@.inbounds[@.type="mixed"].listen_port' 2>/dev/null | head -n 1)"
	elif pidof mihomo >/dev/null 2>&1 || pidof clash-meta >/dev/null 2>&1 || pidof smart >/dev/null 2>&1; then
		# prefer mixed-port (HTTP+SOCKS) over plain port; a single two-pattern
		# sed would return whichever appears first by line order, so loop by key
		for _cdp_key in mixed-port port socks-port; do
			_cdp_port="$(sed -n "s/^[[:space:]]*${_cdp_key}:[[:space:]]*\([0-9][0-9]*\).*/\1/p" \
				/etc/clashoo/config.yaml 2>/dev/null | head -n 1)"
			[ -n "$_cdp_port" ] && break
		done
	else
		return 0
	fi
	[ -n "$_cdp_port" ] || _cdp_port="$(uci -q get clashoo.config.mixed_port 2>/dev/null)"
	[ -n "$_cdp_port" ] || return 0
	printf 'http://127.0.0.1:%s' "$_cdp_port"
}
