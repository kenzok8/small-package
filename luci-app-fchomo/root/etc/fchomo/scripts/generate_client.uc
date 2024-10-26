#!/usr/bin/ucode

'use strict';

import { readfile, writefile } from 'fs';
import { connect } from 'ubus';
import { cursor } from 'uci';

import { urldecode, urlencode } from 'luci.http';

import {
	isEmpty, strToBool, strToInt,
	removeBlankAttrs,
	HM_DIR, RUN_DIR, PRESET_OUTBOUND
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
      uciprov = 'provider',
      ucirule = 'ruleset',
      ucirout = 'rules';

/* Hardcode options */
const common_tcpport = uci.get(uciconf, ucifchm, 'common_tcpport') || '20-21,22,53,80,110,143,443,465,853,873,993,995,8080,8443,9418',
      common_udpport = uci.get(uciconf, ucifchm, 'common_udpport') || '20-21,22,53,80,110,143,443,853,993,995,8080,8443,9418',
      stun_port = uci.get(uciconf, ucifchm, 'stun_port') || '3478,19302',
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
      default_proxy = uci.get(uciconf, uciroute, 'default_proxy') || null,
      routing_tcpport = uci.get(uciconf, uciroute, 'routing_tcpport') || null,
      routing_udpport = uci.get(uciconf, uciroute, 'routing_udpport') || null,
      routing_mode = uci.get(uciconf, uciroute, 'routing_mode') || null,
      routing_domain = strToBool(uci.get(uciconf, uciroute, 'routing_domain')),
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

function parse_time_duration(time) {
	if (isEmpty(time))
		return null;

	let seconds = 0;
	let arr = match(time, /^(\d+)(s|m|h|d)?$/);
	if (arr) {
		if (arr[2] === 's') {
			seconds = strToInt(arr[1]);
		} else if (arr[2] === 'm') {
			seconds = strToInt(arr[1]) * 60;
		} else if (arr[2] === 'h') {
			seconds = strToInt(arr[1]) * 3600;
		} else if (arr[2] === 'd') {
			seconds = strToInt(arr[1]) * 86400;
		} else
			seconds = strToInt(arr[1]);
	}

	return seconds;
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
		return 'rcode://name_error';

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
/* Config helper END */

/* Main */
const config = {};

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
config["keep-alive-interval"] = parse_time_duration(uci.get(uciconf, uciglobal, 'keep_alive_interval')) || 30;
config["keep-alive-idle"] = parse_time_duration(uci.get(uciconf, uciglobal, 'keep_alive_idle')) || 600;
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
	"private-key": uci.get(uciconf, ucitls, 'tls_key_path')
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
		ports: map(cfg.ports, (ports) => {
			return strToInt(ports); // DEBUG ERROR data type *utils.IntRanges[uint16]
		}),
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
	port: strToInt(uci.get(uciconf, uciinbound, 'mixed_port')) || '7890',
	listen: '::',
	udp: true
});
if (match(proxy_mode, /redir/))
	push(config.listeners, {
		name: 'redir-in',
		type: 'redir',
		port: strToInt(uci.get(uciconf, uciinbound, 'redir_port')) || '7891',
		listen: '::'
	});
if (match(proxy_mode, /tproxy/))
	push(config.listeners, {
		name: 'tproxy-in',
		type: 'tproxy',
		port: strToInt(uci.get(uciconf, uciinbound, 'tproxy_port')) || '7892',
		listen: '::',
		udp: true
	});
push(config.listeners, {
	name: 'dns-in',
	type: 'tunnel',
	port: strToInt(uci.get(uciconf, uciinbound, 'tunnel_port')) || '7893',
	listen: '::',
	network: ['tcp', 'udp'],
	target: '1.1.1.1:53'
});
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
		"udp-timeout": parse_time_duration(uci.get(uciconf, uciinbound, 'tun_udp_timeout')) || 300,
		"endpoint-independent-nat": strToBool(uci.get(uciconf, uciinbound, 'tun_endpoint_independent_nat')),
		"auto-detect-interface": true
	});
/* Inbound END */

/* DNS START */
/* DNS settings */
config.dns = {
	enable: true,
	"prefer-h3": false,
	listen: '[::]:' + (uci.get(uciconf, ucidns, 'port') || '7853'),
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
		tolerance: (cfg.type === 'url-test') ? strToInt(cfg.tolerance) || 150 : null,
		// Load-balance fields
		strategy: cfg.strategy,
		// Override fields
		"disable-udp": strToBool(cfg.disable_udp) || false,
		["interface-name"]: cfg.interface_name,
		["routing-mark"]: strToInt(cfg.routing_mark),
		// Health fields
		url: cfg.url,
		interval: cfg.url ? parse_time_duration(cfg.interval) || 600 : null,
		timeout: cfg.url ? strToInt(cfg.timeout) || 5000 : null,
		lazy: (cfg.lazy === '0') ? false : null,
		"expected-status": cfg.url ? cfg.expected_status || '204' : null,
		"max-failed-times": cfg.url ? strToInt(cfg.max_failed_times) || 5 : null,
		filter: parse_filter(cfg.filter),
		"exclude-filter": parse_filter(cfg.exclude_filter),
		"exclude-type": parse_filter(cfg.exclude_type)
	});
});
/* Proxy Group END */

/* Provider START */
/* Provider settings */
config["proxy-providers"] = {};
uci.foreach(uciconf, uciprov, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	/* General fields */
	config["proxy-providers"][cfg['.name']] = {
		type: cfg.type,
		path: HM_DIR + '/provider/' + cfg['.name'],
		url: cfg.url,
		interval: (cfg.type === 'http') ? parse_time_duration(cfg.interval) || 86400 : null,
		proxy: get_proxygroup(cfg.proxy),
		header: cfg.header ? json(cfg.header) : null,
		"health-check": {},
		override: {},
		filter: parse_filter(cfg.filter),
		"exclude-filter": parse_filter(cfg.exclude_filter),
		"exclude-type": parse_filter(cfg.exclude_type)
	};

	/* Override fields */
	config["proxy-providers"][cfg['.name']].override = {
		["additional-prefix"]: cfg.override_prefix,
		["additional-suffix"]: cfg.override_suffix,
		["proxy-name"]: isEmpty(cfg.override_replace) ? null : map(cfg.override_replace, (obj) => json(obj)),
		// Configuration Items
		tfo: strToBool(cfg.override_tfo),
		mptcp: strToBool(cfg.override_mptcp),
		udp: (cfg.override_udp === '0') ? false : true,
		"udp-over-tcp": strToBool(cfg.override_uot),
		up: cfg.override_up ? cfg.override_up + ' Mbps' : null,
		down: cfg.override_down ? cfg.override_down + ' Mbps' : null,
		["skip-cert-verify"]: strToBool(cfg.override_skip_cert_verify) || false,
		// dev: Features under development
		["dialer-proxy"]: null, //cfg.override_dialer_proxy,
		["interface-name"]: cfg.override_interface_name,
		["routing-mark"]: strToInt(cfg.override_routing_mark),
		["ip-version"]: cfg.override_ip_version
	};

	/* Health fields */
	if (cfg.health_enable === '0') {
		config["proxy-providers"][cfg['.name']]["health-check"] = null;
	} else {
		config["proxy-providers"][cfg['.name']]["health-check"] = {
			enable: true,
			url: cfg.health_url,
			interval: parse_time_duration(cfg.health_interval) || 600,
			timeout: strToInt(cfg.health_timeout) || 5000,
			lazy: (cfg.health_lazy === '0') ? false : null,
			"expected-status": cfg.health_expected_status || '204'
		};
	}
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
		path: HM_DIR + '/ruleset/' + cfg['.name'],
		url: cfg.url,
		interval: (cfg.type === 'http') ? parse_time_duration(cfg.interval) || 259200 : null,
		proxy: get_proxygroup(cfg.proxy)
	};
});
/* Rule set END */

/* Routing rules START */
/* Routing rules */
config.rules = [
	"IN-NAME,dns-in,dns-out",
	"DST-PORT,53,dns-out"
];
uci.foreach(uciconf, ucirout, (cfg) => {
	if (cfg.enabled === '0')
		return null;

	push(config.rules, function(arr) {
			arr[1] = replace(arr[1], /ꓹ|‚/g, ','); // U+A4F9 | U+201A
			arr[2] = get_proxygroup(arr[2]);
			return join(',', arr);
		}(split(cfg.entry, ','))
	);
});
push(config.rules, 'MATCH,' + get_proxygroup(default_proxy));
/* Routing rules END */

printf('%.J\n', removeBlankAttrs(config));
