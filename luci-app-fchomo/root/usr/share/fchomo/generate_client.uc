#!/usr/bin/ucode

'use strict';

import { readfile, writefile } from 'fs';
import { connect } from 'ubus';
import { cursor } from 'uci';

import { urldecode, urlencode } from 'luci.http';

import {
	isEmpty, strToBool, strToInt, bytesizeToByte, durationToSecond,
	arrToObj, removeBlankAttrs,
	HM_DIR, RUN_DIR, PRESET_OUTBOUND, RULES_LOGICAL_TYPE
} from 'fchomo';

const ubus = connect();

/* UCI config START */
const uci = cursor();

const uciconf = 'fchomo';
uci.load(uciconf);

const ucifchm = 'config',
      ucires = 'resources',
      uciroute = 'routing';

const uciglobal = 'global',
      uciinbound = 'inbound',
      ucitls = 'tls',
      uciapi = 'api',
      ucisniffer = 'sniffer',
      ucidns = 'dns',
      uciexpr = 'experimental';

const ucisniff = 'sniff',
      ucidnser = 'dns_server',
      ucidnspoli = 'dns_policy',
      ucipgrp = 'proxy_group',
      ucinode = 'node',
      uciprov = 'provider',
      ucichain = 'dialer_proxy',
      ucirule = 'ruleset',
      ucirout = 'rules',
      ucisubro = 'subrules';

/* Hardcode options */
const port_presets = {
      	common_tcpport: uci.get(uciconf, ucifchm, 'common_tcpport') || '20-21,22,53,80,110,143,443,853,873,993,995,5222,8080,8443,9418',
      	common_udpport: uci.get(uciconf, ucifchm, 'common_udpport') || '20-21,22,53,80,110,143,443,853,993,995,8080,8443,9418',
      	smtp_tcpport: uci.get(uciconf, ucifchm, 'smtp_tcpport') || '465,587',
      	stun_port: uci.get(uciconf, ucifchm, 'stun_port') || '3478,19302',
      	turn_port: uci.get(uciconf, ucifchm, 'turn_port') || '5349',
		google_fcm_port: uci.get(uciconf, ucifchm, 'google_fcm_port') || '443,5228-5230',
      	steam_client_port: uci.get(uciconf, ucifchm, 'steam_client_port') || '27015-27050',
      	steam_p2p_udpport: uci.get(uciconf, ucifchm, 'steam_p2p_udpport') || '3478,4379,4380,27000-27100',
      },
      tun_name = uci.get(uciconf, ucifchm, 'tun_name') || 'hmtun0',
      tun_addr4 = uci.get(uciconf, ucifchm, 'tun_addr4') || '198.19.0.1/30',
      tun_addr6 = uci.get(uciconf, ucifchm, 'tun_addr6') || 'fdfe:dcba:9877::1/126',
      route_table_id = strToInt(uci.get(uciconf, ucifchm, 'route_table_id')) || 2022, // global.js
      route_rule_pref = strToInt(uci.get(uciconf, ucifchm, 'route_rule_pref')) || 9000, // global.js
      redirect_gate_mark = strToInt(uci.get(uciconf, ucifchm, 'redirect_gate_mark')) || 2023,
      redirect_pass_mark = strToInt(uci.get(uciconf, ucifchm, 'redirect_pass_mark')) || 2024,
      self_mark = strToInt(uci.get(uciconf, ucifchm, 'self_mark')) || 200, // global.js
      tproxy_mark = strToInt(uci.get(uciconf, ucifchm, 'tproxy_mark')) || 201, // global.js
      tun_mark = strToInt(uci.get(uciconf, ucifchm, 'tun_mark')) || 202, // global.js
      posh = 'c2luZ2JveA'; // Yes. Is true.

const listen_interfaces = uci.get(uciconf, uciroute, 'listen_interfaces') || null,
      bind_interface = uci.get(uciconf, uciroute, 'bind_interface') || null,
      lan_filter = uci.get(uciconf, uciroute, 'lan_filter') || null,
      lan_direct_ipv4_ips = uci.get(uciconf, uciroute, 'lan_direct_ipv4_ips') || null,
      lan_direct_ipv6_ips = uci.get(uciconf, uciroute, 'lan_direct_ipv6_ips') || null,
      lan_direct_mac_addrs = uci.get(uciconf, uciroute, 'lan_direct_mac_addrs') || null,
      lan_proxy_ipv4_ips = uci.get(uciconf, uciroute, 'lan_proxy_ipv4_ips') || null,
      lan_proxy_ipv6_ips = uci.get(uciconf, uciroute, 'lan_proxy_ipv6_ips') || null,
      lan_proxy_mac_addrs = uci.get(uciconf, uciroute, 'lan_proxy_mac_addrs') || null,
      proxy_router = (uci.get(uciconf, uciroute, 'proxy_router') === '0') ? null : true,
      top_upstream = (uci.get(uciconf, uciroute, 'top_upstream') === '1') || null,
      client_enabled = uci.get(uciconf, uciroute, 'client_enabled' === '1') || null,
      routing_tcpport = uci.get(uciconf, uciroute, 'routing_tcpport') || [],
      routing_udpport = uci.get(uciconf, uciroute, 'routing_udpport') || [],
      routing_mode = uci.get(uciconf, uciroute, 'routing_mode') || null,
      routing_domain = strToBool(uci.get(uciconf, uciroute, 'routing_domain')),
      routing_dscp_mode = uci.get(uciconf, uciroute, 'routing_dscp_mode') || null,
      routing_dscp_list = uci.get(uciconf, uciroute, 'routing_dscp_list') || null,
      tposh = 'c2luZ2JveA';

/* WAN DNS server array */
let wan_dns = ubus.call('network.interface', 'status', {'interface': 'wan'})?.['dns-server'];
if (length(wan_dns) === 0)
	wan_dns = ['223.5.5.5'];

/* All DNS server object */
const dnsservers = {};
uci.foreach(uciconf, ucidnser, (cfg) => {
	if (cfg.enabled === '0')
		return;

	dnsservers[cfg['.name']] = {
		label: cfg.label,
		address: cfg.address
	};
});

/* UCI config END */

/* Config helper START */
function parse_filter(cfg) {
	if (isEmpty(cfg))
		return null;

	if (type(cfg) === 'array')
		return join('|', cfg);
	else
		return cfg;
}

function get_proxynode(cfg) {
	if (isEmpty(cfg))
		return null;

	const label = uci.get(uciconf, cfg, 'label');
	if (isEmpty(label))
		die(sprintf("%s's label is missing, please check your configuration.", cfg));
	else
		return label;
}

function get_proxygroup(cfg) {
	if (isEmpty(cfg))
		return null;

	if (cfg in PRESET_OUTBOUND)
		return cfg;

	const label = uci.get(uciconf, cfg, 'label');
	if (isEmpty(label))
		die(sprintf("%s's label is missing, please check your configuration.", cfg));
	else
		return label;
}

function get_nameserver(cfg, detour) {
	if (isEmpty(cfg))
		return [];

	if ('block-dns' in cfg)
		//https://github.com/MetaCubeX/mihomo/blob/0128a0bb1fce17d39158c745a912d7b2b87cf975/config/config.go#L1131
		return 'rcode://refused';

	let servers = [];
	for (let k in cfg) {
		if (k === 'system-dns') {
			push(servers, 'system');
		} else if (k === 'default-dns') {
			map(wan_dns, (dns) => {
				push(servers, dns + '#DIRECT');
			});
		} else
			push(servers, replace(dnsservers[k]?.address || '', /#detour=([^&]+)/, (m, c1) => {
				return '#' + urlencode(get_proxygroup(detour || c1));
			}));
	}

	return servers;
}

function parse_entry(cfg) {
	if (isEmpty(cfg))
		return null;

	let rule = json(cfg);
	if (rule.detour)
		rule.detour = get_proxygroup(rule.detour);

	function _payloadStrategy(payload) {
		// LOGIC_TYPE,((payload1),(payload2))
		if (payload.factor === null || (type(payload.factor) in ['bool', 'int', 'string'])) {
			return sprintf(payload.deny ? 'NOT,((%s))' : '%s', join(',', [payload.type, payload.factor ?? '']));
		} else if (type(payload.factor) === 'array') {
			return sprintf(`${payload.type},(%s)`, join(',', map(payload.factor, p => `(${_payloadStrategy(p)})`)));
		} else if (type(payload.factor) === 'object') {
			die(sprintf(`Factor type cannot be an object: '%J'`, payload.factor));
		} else
			die(`Factor type is incorrect: '${payload.factor}'`);
	}

	// toMihomo
	let logical = (rule.type in RULES_LOGICAL_TYPE);
	let payload = _payloadStrategy(logical ? {type: rule.type, factor: rule.payload} : rule.payload[0]);

	if (rule.subrule)
		return sprintf('SUB-RULE,(%s),%s', payload, rule.subrule);
	else
		if (rule.type === 'MATCH')
			return join(',', [rule.type, rule.detour]);
		else
			return join(',', [...[payload, rule.detour],
				...(rule.params ? keys(rule.params) : [])
			]);
}
/* Config helper END */

/* Main */
const config = {};

/* All Proxy chain object */
const dialerproxy = {};
uci.foreach(uciconf, ucichain, (cfg) => {
	if (cfg.enabled === '0')
		return;

	let identifier = '';
	if (cfg.type === 'provider')
		identifier = cfg.chain_head_sub;
	else if (cfg.type === 'node')
		identifier = cfg.chain_head;
	else
		return;

	dialerproxy[identifier] = {
		detour: get_proxygroup(cfg.chain_tail_group) || get_proxynode(cfg.chain_tail)
	};
});

/* General START */
/* General settings */
config["global-ua"] = 'clash.meta';
config.mode = uci.get(uciconf, uciglobal, 'mode') || 'rule';
config["find-process-mode"] = uci.get(uciconf, uciglobal, 'find_process_mode') || 'off';
config["log-level"] = uci.get(uciconf, uciglobal, 'log_level') || 'warning';
config["etag-support"] = (uci.get(uciconf, uciglobal, 'etag_support') === '0') ? false : true;
config.ipv6 = (uci.get(uciconf, uciglobal, 'ipv6') === '0') ? false : true;
config["unified-delay"] = strToBool(uci.get(uciconf, uciglobal, 'unified_delay')) || false;
config["tcp-concurrent"] = strToBool(uci.get(uciconf, uciglobal, 'tcp_concurrent')) || false;
config["keep-alive-interval"] = durationToSecond(uci.get(uciconf, uciglobal, 'keep_alive_interval')) || 30;
config["keep-alive-idle"] = durationToSecond(uci.get(uciconf, uciglobal, 'keep_alive_idle')) || 600;
/* ACL settings */
config["interface-name"] = bind_interface;
config["routing-mark"] = self_mark;
/* Global Authentication */
config.authentication = uci.get(uciconf, uciglobal, 'authentication');
config["skip-auth-prefixes"] = uci.get(uciconf, uciglobal, 'skip_auth_prefixes');
/* General END */

/* GEOX START */
/* GEOX settings */
config["geodata-mode"] = true;
config["geodata-loader"] = 'memconservative';
config["geo-auto-update"] = false;
/* GEOX END */

/* TLS START */
/* TLS settings */
config["global-client-fingerprint"] = uci.get(uciconf, ucitls, 'global_client_fingerprint');
config.tls = {
	"certificate": uci.get(uciconf, ucitls, 'tls_cert_path'),
	"private-key": uci.get(uciconf, ucitls, 'tls_key_path'),
	"client-auth-type": uci.get(uciconf, ucitls, 'tls_client_auth_type'),
	"client-auth-cert": uci.get(uciconf, ucitls, 'tls_client_auth_cert_path'),
	"ech-key": uci.get(uciconf, ucitls, 'tls_ech_key')
};
/* TLS END */

/* API START */
const api_port = uci.get(uciconf, uciapi, 'external_controller_port');
const api_tls_port = uci.get(uciconf, uciapi, 'external_controller_tls_port');
/* API settings */
config["external-controller-cors"] = {
	"allow-origins": uci.get(uciconf, uciapi, 'external_controller_cors_allow_origins') || ['*'],
	"allow-private-network" : (uci.get(uciconf, uciapi, 'external_controller_cors_allow_private_network') === '0') ? false : true
};
config["external-controller"] = api_port ? '[::]:' + api_port : null;
config["external-controller-tls"] = api_tls_port ? '[::]:' + api_tls_port : null;
config["external-doh-server"] = uci.get(uciconf, uciapi, 'external_doh_server');
config.secret = uci.get(uciconf, uciapi, 'secret') || trim(readfile('/proc/sys/kernel/random/uuid'));
config["external-ui"] = RUN_DIR + '/ui';
config["external-ui-url"] = `https://codeload.github.com/${uci.get(uciconf, uciapi, 'dashboard_repo')}/zip/refs/heads/gh-pages`;
/* API END */

/* Cache START */
/* Cache settings */
config.profile = {
	"store-selected": true,
	"store-fake-ip": false
};
/* Cache END */

/* Experimental START */
/* Experimental settings */
config.experimental = {
	"quic-go-disable-gso": strToBool(uci.get(uciconf, uciexpr, 'quic_go_disable_gso')),
	"quic-go-disable-ecn": strToBool(uci.get(uciconf, uciexpr, 'quic_go_disable_ecn')),
	"dialer-ip4p-convert": strToBool(uci.get(uciconf, uciexpr, 'dialer_ip4p_convert'))
};
/* Experimental END */

/* Sniffer START */
/* Sniffer settings */
config.sniffer = {
	enable: true,
	"force-dns-mapping": true,
	"parse-pure-ip": true,
	"override-destination": (uci.get(uciconf, ucisniffer, 'override_destination') === '0') ? false : true,
	sniff: {},
	"force-domain": uci.get(uciconf, ucisniffer, 'force_domain'),
	"skip-domain": uci.get(uciconf, ucisniffer, 'skip_domain'),
	"skip-src-address": uci.get(uciconf, ucisniffer, 'skip_src_address'),
	"skip-dst-address": uci.get(uciconf, ucisniffer, 'skip_dst_address')
};
/* Sniff protocol settings */
uci.foreach(uciconf, ucisniff, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	config.sniffer.sniff[cfg.protocol] = {
		ports: map(cfg.ports, ports => strToInt(ports) || null), // @DEBUG ERROR data type *utils.IntRanges[uint16]
		"override-destination": (cfg.override_destination === '0') ? false : true
	};
});
/* Sniffer END */

/* Inbound START */
const proxy_mode = uci.get(uciconf, uciinbound, 'proxy_mode') || 'redir_tproxy';
/* Listen ports */
config.listeners = [];
push(config.listeners, {
	name: 'mixed-in',
	type: 'mixed',
	port: strToInt(uci.get(uciconf, uciinbound, 'mixed_port')) || 7890,
	listen: '::',
	udp: true
});
if (match(proxy_mode, /redir/))
	push(config.listeners, {
		name: 'redir-in',
		type: 'redir',
		port: strToInt(uci.get(uciconf, uciinbound, 'redir_port')) || 7891,
		listen: '::'
	});
if (match(proxy_mode, /tproxy/))
	push(config.listeners, {
		name: 'tproxy-in',
		type: 'tproxy',
		port: strToInt(uci.get(uciconf, uciinbound, 'tproxy_port')) || 7892,
		listen: '::',
		udp: true
	});
push(config.listeners, {
	name: 'dns-in',
	type: 'tunnel',
	port: strToInt(uci.get(uciconf, uciinbound, 'tunnel_port')) || 7893,
	listen: '::',
	network: ['tcp', 'udp'],
	target: '1.1.1.1:53'
}); // @Not required for v1.19.2+
/* Tun settings */
if (match(proxy_mode, /tun/))
	push(config.listeners, {
		name: 'tun-in',
		type: 'tun',

		device: tun_name,
		stack: uci.get(uciconf, uciinbound, 'tun_stack') || 'system',
		"dns-hijack": ['udp://[::]:53', 'tcp://[::]:53'],
		"inet4-address": [ tun_addr4 ],
		"inet6-address": [ tun_addr6 ],
		mtu: strToInt(uci.get(uciconf, uciinbound, 'tun_mtu')) || 9000,
		gso: strToBool(uci.get(uciconf, uciinbound, 'tun_gso')) || false,
		"gso-max-size": strToInt(uci.get(uciconf, uciinbound, 'tun_gso_max_size')) || 65536,
		"auto-route": false,
		"iproute2-table-index": route_table_id,
		"iproute2-rule-index": route_rule_pref,
		"auto-redirect": false,
		"auto-redirect-input-mark": redirect_gate_mark,
		"auto-redirect-output-mark": redirect_pass_mark,
		"strict-route": false,
		"route-address": [
			"0.0.0.0/1",
			"128.0.0.0/1",
			"::/1",
			"8000::/1"
		],
		"route-exclude-address": [
			"192.168.0.0/16",
			"fc00::/7"
		],
		"route-address-set": [],
		"route-exclude-address-set": [],
		"include-interface": [],
		"exclude-interface": [],
		"udp-timeout": durationToSecond(uci.get(uciconf, uciinbound, 'tun_udp_timeout')) || 300,
		"endpoint-independent-nat": strToBool(uci.get(uciconf, uciinbound, 'tun_endpoint_independent_nat')),
		"disable-icmp-forwarding": (uci.get(uciconf, uciinbound, 'tun_disable_icmp_forwarding') === '0') ? false : true,
		"auto-detect-interface": true
	});
/* Inbound END */

/* DNS START */
/* DNS settings */
config.dns = {
	enable: true,
	"prefer-h3": false,
	listen: '[::]:' + (uci.get(uciconf, ucidns, 'dns_port') || '7853'),
	ipv6: (uci.get(uciconf, ucidns, 'ipv6') === '0') ? false : true,
	"enhanced-mode": 'redir-host',
	"use-hosts": true,
	"use-system-hosts": true,
	"respect-rules": true,
	"default-nameserver": get_nameserver(uci.get(uciconf, ucidns, 'boot_server')),
	"proxy-server-nameserver": get_nameserver(uci.get(uciconf, ucidns, 'bootnode_server')),
	nameserver: get_nameserver(uci.get(uciconf, ucidns, 'default_server')),
	fallback: get_nameserver(uci.get(uciconf, ucidns, 'fallback_server')),
	"nameserver-policy": {},
	"fallback-filter": {
		geoip: false
	}
};
/* DNS policy */
uci.foreach(uciconf, ucidnspoli, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	let key;
	if (cfg.type === 'domain') {
		key = isEmpty(cfg.domain) ? null : join(',', cfg.domain);
	} else if (cfg.type === 'geosite') {
		key = isEmpty(cfg.geosite) ? null : 'geosite:' + join(',', cfg.geosite);
	} else if (cfg.type === 'rule_set') {
		key = isEmpty(cfg.rule_set) ? null : 'rule-set:' + join(',', cfg.rule_set);
	};

	if (!key)
		return null;

	config.dns["nameserver-policy"][key] = get_nameserver(cfg.server, cfg.proxy);
});
/* Fallback filter */
if (!isEmpty(config.dns.fallback))
	config.dns["fallback-filter"] = {
		geoip: (uci.get(uciconf, ucidns, 'fallback_filter_geoip') === '0') ? false : true,
		"geoip-code": uci.get(uciconf, ucidns, 'fallback_filter_geoip_code') || 'cn',
		geosite: uci.get(uciconf, ucidns, 'fallback_filter_geosite') || [],
		ipcidr: uci.get(uciconf, ucidns, 'fallback_filter_ipcidr') || [],
		domain: uci.get(uciconf, ucidns, 'fallback_filter_domain') || [],
	};
/* DNS END */

/* Hosts START */
/* Hosts */
config.hosts = {};
/* Hosts END */

/* Proxy Node START */
/* Proxy Node */
config.proxies = [
	/*{
		name: 'direct-out',
		type: 'direct',
		udp: true,
		"ip-version": undefined,
		"interface-name": undefined,
		"routing-mark": undefined
	},*/
	{
		name: 'dns-out',
		type: 'dns'
	}
];
uci.foreach(uciconf, ucinode, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	push(config.proxies, {
		name: cfg.label,
		type: cfg.type,

		server: cfg.server,
		port: strToInt(cfg.port) || null,

		/* Dial fields */
		tfo: strToBool(cfg.tfo),
		mptcp: strToBool(cfg.mptcp),
		"dialer-proxy": dialerproxy[cfg['.name']]?.detour,
		"interface-name": cfg.interface_name,
		"routing-mark": strToInt(cfg.routing_mark) || null,
		"ip-version": cfg.ip_version,

		/* HTTP / SOCKS / Shadowsocks / VMess / VLESS / Trojan / hysteria2 / TUIC / SSH / WireGuard */
		username: cfg.username,
		uuid: cfg.vmess_uuid || cfg.uuid,
		cipher: cfg.vmess_chipher || cfg.shadowsocks_chipher,
		password: cfg.shadowsocks_password || cfg.password,
		headers: cfg.headers ? json(cfg.headers) : null,
		"private-key": cfg.wireguard_private_key || cfg.ssh_priv_key,

		/* Hysteria / Hysteria2 */
		ports: isEmpty(cfg.hysteria_ports) ? null : join(',', cfg.hysteria_ports),
		up: cfg.hysteria_up_mbps ? cfg.hysteria_up_mbps + ' Mbps' : null,
		down: cfg.hysteria_down_mbps ? cfg.hysteria_down_mbps + ' Mbps' : null,
		obfs: cfg.hysteria_obfs_type,
		"obfs-password": cfg.hysteria_obfs_password,

		/* SSH */
		"private-key-passphrase": cfg.ssh_priv_key_passphrase,
		"host-key-algorithms": cfg.ssh_host_key_algorithms,
		"host-key": cfg.ssh_host_key,

		/* Shadowsocks */

		/* Mieru */
		"port-range": cfg.mieru_port_range,
		transport: cfg.mieru_transport,
		multiplexing: cfg.mieru_multiplexing,
		"handshake-mode": cfg.mieru_handshake_mode,

		/* Snell */
		psk: cfg.snell_psk,
		version: cfg.snell_version,
		"obfs-opts": cfg.type === 'snell' ? {
			mode: cfg.plugin_opts_obfsmode,
			host: cfg.plugin_opts_host,
		} : null,

		/* TUIC */
		ip: cfg.tuic_ip,
		"congestion-controller": cfg.tuic_congestion_controller,
		"udp-relay-mode": cfg.tuic_udp_relay_mode,
		"udp-over-stream": strToBool(cfg.tuic_udp_over_stream),
		"udp-over-stream-version": cfg.tuic_udp_over_stream_version,
		"max-udp-relay-packet-size": strToInt(cfg.tuic_max_udp_relay_packet_size) || null,
		"reduce-rtt": strToBool(cfg.tuic_reduce_rtt),
		"heartbeat-interval": strToInt(cfg.tuic_heartbeat) || null,
		"request-timeout": strToInt(cfg.tuic_request_timeout) || null,
		// @"fast-open": true,
		"max-open-streams": strToInt(cfg.tuic_max_open_streams) || null,

		/* Trojan */
		"ss-opts": cfg.trojan_ss_enabled === '1' ? {
			enabled: true,
			method: cfg.trojan_ss_chipher,
			password: cfg.trojan_ss_password
		} : null,

		/* AnyTLS */
		"idle-session-check-interval": durationToSecond(cfg.anytls_idle_session_check_interval),
		"idle-session-timeout": durationToSecond(cfg.anytls_idle_session_timeout),
		"min-idle-session": strToInt(cfg.anytls_min_idle_session),

		/* VMess / VLESS */
		flow: cfg.vless_flow,
		alterId: strToInt(cfg.vmess_alterid),
		"global-padding": cfg.type === 'vmess' ? (cfg.vmess_global_padding === '0' ? false : true) : null,
		"authenticated-length": strToBool(cfg.vmess_authenticated_length),
		"packet-encoding": cfg.vmess_packet_encoding,
		encryption: cfg.vless_encryption === '1' ? cfg.vless_encryption_encryption : null,

		/* WireGuard */
		ip: cfg.wireguard_ip,
		ipv6: cfg.wireguard_ipv6,
		"public-key": cfg.wireguard_peer_public_key,
		"pre-shared-key": cfg.wireguard_pre_shared_key,
		"allowed-ips": cfg.wireguard_allowed_ips,
		reserved: cfg.wireguard_reserved,
		mtu: strToInt(cfg.wireguard_mtu) || null,
		"remote-dns-resolve": strToBool(cfg.wireguard_remote_dns_resolve),
		dns: cfg.wireguard_dns,

		/* Plugin fields */
		plugin: cfg.plugin,
		"plugin-opts": cfg.plugin ? {
			mode: cfg.plugin_opts_obfsmode,
			host: cfg.plugin_opts_host,
			password: cfg.plugin_opts_thetlspassword,
			version: strToInt(cfg.plugin_opts_shadowtls_version),
			"version-hint": cfg.plugin_opts_restls_versionhint,
			"restls-script": cfg.plugin_opts_restls_script
		} : null,

		/* Extra fields */
		udp: strToBool(cfg.udp),
		"udp-over-tcp": strToBool(cfg.uot),
		"udp-over-tcp-version": cfg.uot_version,

		/* TLS fields */
		tls: (cfg.type in ['trojan', 'anytls', 'hysteria', 'hysteria2', 'tuic']) ? null : strToBool(cfg.tls),
		"disable-sni": strToBool(cfg.tls_disable_sni),
		...arrToObj([[(cfg.type in ['vmess', 'vless']) ? 'servername' : 'sni', cfg.tls_sni]]),
		fingerprint: cfg.tls_fingerprint,
		alpn: cfg.tls_alpn, // Array
		"skip-cert-verify": strToBool(cfg.tls_skip_cert_verify),
		certificate: cfg.tls_cert_path, // mTLS
		"private-key": cfg.tls_key_path, // mTLS
		"client-fingerprint": cfg.tls_client_fingerprint,
		"ech-opts": cfg.tls_ech === '1' ? {
			enable: true,
			config: cfg.tls_ech_config
		} : null,
		"reality-opts": cfg.tls_reality === '1' ? {
			"public-key": cfg.tls_reality_public_key,
			"short-id": cfg.tls_reality_short_id,
			"support-x25519mlkem768": strToBool(cfg.tls_reality_support_x25519mlkem768)
		} : null,

		/* Transport fields */
		// https://github.com/muink/mihomo/blob/3e966e82c793ca99e3badc84bf3f2907b100edae/adapter/outbound/vmess.go#L74
		...(cfg.transport_enabled === '1' ? {
			network: cfg.transport_type,
			"http-opts": cfg.transport_type === 'http' ? {
				method: cfg.transport_http_method,
				path: isEmpty(cfg.transport_paths) ? ['/'] : cfg.transport_paths, // Array
				headers: cfg.transport_http_headers ? json(cfg.transport_http_headers) : null,
			} : null,
			"h2-opts": cfg.transport_type === 'h2' ? {
				host: cfg.transport_hosts, // Array
				path: cfg.transport_path || '/',
			} : null,
			"grpc-opts": cfg.transport_type === 'grpc' ? {
				"grpc-service-name": cfg.transport_grpc_servicename
			} : null,
			"ws-opts": cfg.transport_type === 'ws' ? {
				path: cfg.transport_path || '/',
				headers: cfg.transport_http_headers ? json(cfg.transport_http_headers) : null,
				"max-early-data": strToInt(cfg.transport_ws_max_early_data) || null,
				"early-data-header-name": cfg.transport_ws_early_data_header,
				"v2ray-http-upgrade": strToBool(cfg.transport_ws_v2ray_http_upgrade),
				"v2ray-http-upgrade-fast-open": strToBool(cfg.transport_ws_v2ray_http_upgrade_fast_open)
			} : null
		} : {}),

		/* Multiplex fields */
		smux: cfg.smux_enabled === '1' ? {
			enabled: true,
			protocol: cfg.smux_protocol,
			"max-connections": strToInt(cfg.smux_max_connections) || null,
			"min-streams": strToInt(cfg.smux_min_streams) || null,
			"max-streams": strToInt(cfg.smux_max_streams) || null,
			statistic: strToBool(cfg.smux_statistic),
			"only-tcp": strToBool(cfg.smux_only_tcp),
			padding: strToBool(cfg.smux_padding),
			"brutal-opts": cfg.smux_brutal === '1' ? {
				enabled: true,
				up: strToInt(cfg.smux_brutal_up) || null, // Mbps
				down: strToInt(cfg.smux_brutal_down) || null // Mbps
			} : null
		} : null
	});
});
/* Proxy Node END */

/* Proxy Group START */
/* Proxy Group */
config["proxy-groups"] = [];
uci.foreach(uciconf, ucipgrp, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	push(config["proxy-groups"], {
		name: cfg.label,
		type: cfg.type,
		proxies: [
			...map(cfg.groups || [], cfg => get_proxygroup(cfg)),
			...map(cfg.proxies || [], cfg => get_proxynode(cfg))
		],
		use: cfg.use,
		"include-all": strToBool(cfg.include_all),
		"include-all-proxies": strToBool(cfg.include_all_proxies),
		"include-all-providers": strToBool(cfg.include_all_providers),
		// Url-test fields
		tolerance: (cfg.type === 'url-test') ? strToInt(cfg.tolerance) ?? 150 : null,
		// Load-balance fields
		strategy: cfg.strategy,
		// Override fields
		"disable-udp": strToBool(cfg.disable_udp) || false,
		// Health fields
		url: cfg.url,
		interval: cfg.url ? durationToSecond(cfg.interval) ?? 600 : null,
		timeout: cfg.url ? strToInt(cfg.timeout) || 5000 : null,
		lazy: (cfg.lazy === '0') ? false : null,
		"expected-status": cfg.url ? cfg.expected_status || '204' : null,
		"max-failed-times": cfg.url ? strToInt(cfg.max_failed_times) ?? 5 : null,
		// General fields
		filter: parse_filter(cfg.filter),
		"exclude-filter": parse_filter(cfg.exclude_filter),
		"exclude-type": parse_filter(cfg.exclude_type),
		hidden: strToBool(cfg.hidden),
		icon: cfg.icon
	});
});
/* Proxy Group END */

/* Provider START */
/* Provider settings */
config["proxy-providers"] = {};
uci.foreach(uciconf, uciprov, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	config["proxy-providers"][cfg['.name']] = {
		type: cfg.type,
		...(cfg.type === 'inline' ? {
			"dialer-proxy": dialerproxy[cfg['.name']]?.detour,
			payload: trim(cfg.payload)
		} : {
			path: HM_DIR + '/provider/' + cfg['.name'],
			url: cfg.url,
			"size-limit": bytesizeToByte(cfg.size_limit) || null,
			interval: (cfg.type === 'http') ? durationToSecond(cfg.interval) ?? 86400 : null,
			proxy: get_proxygroup(cfg.proxy),
			header: cfg.header ? json(cfg.header) : null,
			/* Health fields */
			"health-check": cfg.health_enable === '0' ? {enable: false} : {
				enable: true,
				url: cfg.health_url,
				interval: durationToSecond(cfg.health_interval) ?? 600,
				timeout: strToInt(cfg.health_timeout) || 5000,
				lazy: (cfg.health_lazy === '0') ? false : null,
				"expected-status": cfg.health_expected_status || '204'
			},
			/* Override fields */
			override: {
				"additional-prefix": cfg.override_prefix,
				"additional-suffix": cfg.override_suffix,
				"proxy-name": isEmpty(cfg.override_replace) ? null : map(cfg.override_replace, (obj) => json(obj)),
				// Configuration Items
				tfo: strToBool(cfg.override_tfo),
				mptcp: strToBool(cfg.override_mptcp),
				udp: (cfg.override_udp === '0') ? false : true,
				"udp-over-tcp": strToBool(cfg.override_uot),
				up: cfg.override_up ? cfg.override_up + ' Mbps' : null,
				down: cfg.override_down ? cfg.override_down + ' Mbps' : null,
				"skip-cert-verify": strToBool(cfg.override_skip_cert_verify) || false,
				"dialer-proxy": dialerproxy[cfg['.name']]?.detour,
				"interface-name": cfg.override_interface_name,
				"routing-mark": strToInt(cfg.override_routing_mark) || null,
				"ip-version": cfg.override_ip_version
			},
			/* General fields */
			filter: parse_filter(cfg.filter),
			"exclude-filter": parse_filter(cfg.exclude_filter),
			"exclude-type": parse_filter(cfg.exclude_type)
		})
	};
});
/* Provider END */

/* Rule set START */
/* Rule set settings */
config["rule-providers"] = {};
uci.foreach(uciconf, ucirule, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	config["rule-providers"][cfg['.name']] = {
		type: cfg.type,
		format: cfg.format,
		behavior: cfg.behavior,
		...(cfg.type === 'inline' ? {
			payload: trim(cfg.payload)
		} : {
			path: HM_DIR + '/ruleset/' + cfg['.name'],
			url: cfg.url,
			"size-limit": bytesizeToByte(cfg.size_limit) || null,
			interval: (cfg.type === 'http') ? durationToSecond(cfg.interval) ?? 259200 : null,
			proxy: get_proxygroup(cfg.proxy)
		})
	};
});
/* Rule set END */

/* Routing rules START */
/* Routing rules */
config.rules = [
	"IN-NAME,dns-in,dns-out", // @Not required for v1.19.2+
	"DST-PORT,53,dns-out"
];
uci.foreach(uciconf, ucirout, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	push(config.rules, parse_entry(cfg.entry));
});
/* Routing rules END */

/* Sub rules START */
/* Sub rules */
config["sub-rules"] = {};
uci.foreach(uciconf, ucisubro, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	if (!config["sub-rules"][cfg.group])
		config["sub-rules"][cfg.group] = [];
	push(config["sub-rules"][cfg.group], parse_entry(cfg.entry));
});
/* Sub rules END */

printf('%.J\n', removeBlankAttrs(config));
