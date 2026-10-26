#!/usr/bin/ucode
/*
 * SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2023-2025 ImmortalWrt.org
 */

'use strict';

import { readfile, writefile } from 'fs';
import { connect } from 'ubus';
import { cursor } from 'uci';

import {
	addECHDNS, createNodeOutboundTags, filterExistingNodes, findDomainGroupConflict,
	isEmpty, normalizeDomainList, normalizeList, parseURL,
	domainListPath, resolveLanPolicy, splitDomainList,
	strToBool, strToInt, strToTime,
	removeBlankAttrs, renderEndpoint, renderOutbound, validation, HP_DIR, RUN_DIR
} from 'homeproxy';

const ubus = connect();

/* UCI config start */
const uci = cursor();

const uciconfig = 'homeproxy';
uci.load(uciconfig);

const uciinfra = 'infra',
      ucimain = 'config',
      ucicontrol = 'control',
      ucitalscale = 'tailscale';

const routing_mode = uci.get(uciconfig, ucimain, 'routing_mode') || 'bypass_mainland_china';

if (!(routing_mode in ['bypass_mainland_china', 'global']))
	die('Unsupported routing mode. Select bypass_mainland_china or global.');

const lan_policy = resolveLanPolicy(uci, uciconfig);

const node_outbound_tags = createNodeOutboundTags(uci, uciconfig);
function get_node_outbound_tag(section_id) {
	return node_outbound_tags[section_id] || `cfg-${section_id}-out`;
}

function domain_rule_set_tag(group, type) {
	return `domain-${group.id}-${type}`;
}

function add_inline_domain_rule_set(rule_sets, group, type) {
	const domains = type === 'suffix' ? group.suffixes : group.keywords;
	if (!length(domains))
		return;

	push(rule_sets, {
		type: 'inline',
		tag: domain_rule_set_tag(group, type),
		rules: [type === 'suffix' ? { domain_suffix: domains } : { domain_keyword: domains }]
	});
}

let wan_dns = ubus.call('network.interface', 'status', {'interface': 'wan'})?.['dns-server']?.[0];
if (!wan_dns)
	wan_dns = (routing_mode === 'global') ? '9.9.9.9' : '223.5.5.5';

const dns_port = uci.get(uciconfig, uciinfra, 'dns_port') || '5333';

const ntp_server = uci.get(uciconfig, uciinfra, 'ntp_server') || 'time.apple.com';

const ipv6_support = uci.get(uciconfig, ucimain, 'ipv6_support') || '0';

const main_node = uci.get(uciconfig, ucimain, 'main_node') || 'nil';

const tailscale_tag = 'tailscale-out';
const tailscale_enabled = uci.get(uciconfig, ucitalscale, 'enabled') === '1';
const tailscale_auth_key = uci.get(uciconfig, ucitalscale, 'auth_key');
const tailscale_control_url = uci.get(uciconfig, ucitalscale, 'control_url');
const tailscale_hostname = uci.get(uciconfig, ucitalscale, 'hostname');
const tailscale_accept_routes = uci.get(uciconfig, ucitalscale, 'accept_routes') === '1';
const tailscale_exit_node = uci.get(uciconfig, ucitalscale, 'exit_node');
const tailscale_exit_node_allow_lan_access =
	uci.get(uciconfig, ucitalscale, 'exit_node_allow_lan_access') === '1';
const tailscale_advertise_routes =
	normalizeList(uci.get(uciconfig, ucitalscale, 'advertise_routes'));
const tailscale_advertise_exit_node =
	uci.get(uciconfig, ucitalscale, 'advertise_exit_node') === '1';
const tailscale_listen_port = uci.get(uciconfig, ucitalscale, 'listen_port');

if (tailscale_enabled && isEmpty(main_node))
	die('Tailscale requires an enabled main node.');
if (tailscale_enabled && !isEmpty(tailscale_exit_node) && tailscale_advertise_exit_node)
	die('Tailscale cannot use and advertise an exit node at the same time.');

let dns_server = uci.get(uciconfig, ucimain, 'dns_server');
if (isEmpty(dns_server) || dns_server === 'wan')
	dns_server = wan_dns;

let china_dns_server;
if (routing_mode === 'bypass_mainland_china') {
	china_dns_server = uci.get(uciconfig, ucimain, 'china_dns_server');
	if (isEmpty(china_dns_server) || type(china_dns_server) !== 'string' || china_dns_server === 'wan')
		china_dns_server = wan_dns;
}
const dns_default_strategy = (ipv6_support === '1') ? 'prefer_ipv6' : 'prefer_ipv4';

function make_domain_resolver(server) {
	return {
		server: server || 'default-dns',
		strategy: dns_default_strategy
	};
}

/* Budget for the proxied probe query: the sing-box default of 10s is far too long
   to stall on when the main DNS is unreachable, since the probe falls back anyway. */
const dns_evaluate_timeout = '3s';

let domain_groups = [];

function add_domain_group(id, kind, node) {
	const domains = normalizeDomainList(readfile(domainListPath(id)));
	if (!length(domains))
		return;

	const split_domains = splitDomainList(domains);
	push(domain_groups, { id, kind, node, ...split_domains });
}

add_domain_group('direct', 'direct');
if (routing_mode === 'bypass_mainland_china')
	add_domain_group('proxy', 'main');

uci.foreach(uciconfig, 'domain_route', (cfg) => {
	if (cfg.enabled === '0')
		return;
	const id = cfg['.name'];
	if (!match(id, /^[A-Za-z0-9_]+$/) || (id in ['direct', 'proxy']))
		die(`Invalid diversion group identifier ${id}.`);

	const domains = normalizeDomainList(readfile(domainListPath(id)));
	if (!length(domains))
		return;

	const split_domains = splitDomainList(domains);
	if (cfg.node === 'tailscale') {
		if (!tailscale_enabled) {
			warn(`Diversion group ${id} selects disabled Tailscale; using the main node.\n`);
			push(domain_groups, { id, kind: 'main', ...split_domains });
			return;
		}
		push(domain_groups, { id, kind: 'tailscale', ...split_domains });
		return;
	}
	if (isEmpty(cfg.node) || isEmpty(uci.get_all(uciconfig, cfg.node))) {
		warn(`Diversion group ${id} selects an unavailable node; using the main node.\n`);
		push(domain_groups, { id, kind: 'main', ...split_domains });
		return;
	}
	push(domain_groups, { id, kind: 'node', node: cfg.node, ...split_domains });
});

const domain_group_conflict = findDomainGroupConflict(domain_groups);
if (domain_group_conflict)
	die(`Domain rule ${domain_group_conflict.left.value} conflicts with ${domain_group_conflict.right.value}.`);

function domain_group_outbound_tag(group) {
	if (group.kind === 'direct')
		return 'direct-out';
	if (group.kind === 'main')
		return 'main-out';
	if (group.kind === 'tailscale')
		return tailscale_tag;
	if (group.node === main_node && main_node !== 'urltest')
		return 'main-out';
	return get_node_outbound_tag(group.node);
}

const default_interface = uci.get(uciconfig, ucicontrol, 'bind_interface'),
      listen_interfaces = normalizeList(uci.get(uciconfig, ucicontrol, 'listen_interfaces'));

const mixed_port = uci.get(uciconfig, uciinfra, 'mixed_port') || '5330';
const clash_api_port = strToInt(uci.get(uciconfig, uciinfra, 'clash_api_port'));

const tun_name = uci.get(uciconfig, uciinfra, 'tun_name') || 'singtun0';
const tun_addr4 = uci.get(uciconfig, uciinfra, 'tun_addr4') || '172.19.0.1/30';
const tun_addr6 = uci.get(uciconfig, uciinfra, 'tun_addr6') || 'fdfe:dcba:9876::1/126';
const tun_mtu = uci.get(uciconfig, uciinfra, 'tun_mtu') || '9000';
const multi_queue = uci.get(uciconfig, ucimain, 'multi_queue') === '1';
const udp_timeout_option = uci.get(uciconfig, uciinfra, 'udp_timeout');
/* 5m is sing-box's default, so only pass through an explicit override. */
const udp_timeout = (udp_timeout_option !== '300') ? strToTime(udp_timeout_option) : null;

const log_level = uci.get(uciconfig, ucimain, 'log_level') || 'warn';
const dashboard_path = HP_DIR + '/dashboard';
const dashboard_enabled = uci.get(uciconfig, ucimain, 'dashboard_enabled') === '1' &&
      !isEmpty(readfile(dashboard_path + '/index.html')),
      dashboard_port = strToInt(uci.get(uciconfig, ucimain, 'dashboard_port')),
      dashboard_secret = uci.get(uciconfig, ucimain, 'dashboard_secret');
/* UCI config end */

/* Config helper start */
function merge_control_options(options) {
	let values = [];
	for (let option in options) {
		if (!option)
			continue;
		values = [...values, ...normalizeList(uci.get(uciconfig, ucicontrol, option))];
	}
	return values;
}

function normalize_cidrs(values) {
	return map(values, (value) => match(value, /\//) ? value : `${value}/${match(value, /:/) ? 128 : 32}`);
}

function source_match(ipv4_option, ipv6_option, mac_option) {
	const ips = normalize_cidrs(merge_control_options([ipv4_option, ipv6_option]));
	const macs = merge_control_options([mac_option]);
	let rules = [];

	if (length(ips))
		push(rules, { source_ip_cidr: ips });
	if (length(macs))
		push(rules, { source_mac_address: macs });

	if (length(rules) === 1)
		return rules[0];
	if (length(rules) > 1)
		return { type: 'logical', mode: 'or', rules };
	return null;
}

function destination_match(ipv4_option, ipv6_option) {
	const ips = normalize_cidrs(merge_control_options([ipv4_option, ipv6_option]));
	return length(ips) ? { ip_cidr: ips } : null;
}

function routing_port_match() {
	let value = uci.get(uciconfig, ucimain, 'routing_port');
	if (value === 'common')
		value = uci.get(uciconfig, uciinfra, 'common_port');
	if (isEmpty(value))
		return null;

	let ports = [], ranges = [], rules = [];
	for (let item in split(value, ',')) {
		item = trim(item);
		if (match(item, /-/))
			push(ranges, replace(item, '-', ':'));
		else if (item)
			push(ports, int(item));
	}
	if (length(ports))
		push(rules, { port: ports });
	if (length(ranges))
		push(rules, { port_range: ranges });

	if (length(rules) === 1)
		return rules[0];
	if (length(rules) > 1)
		return { type: 'logical', mode: 'or', rules };
	return null;
}

function push_route(rules, match_rule, outbound, invert) {
	if (!match_rule)
		return;
	push(rules, {
		...match_rule,
		invert: invert ? true : match_rule.invert,
		action: 'route',
		outbound
	});
}

function push_bypass(rules, match_rule) {
	if (!match_rule)
		return;
	/* A socket routed through the TUN fallback table can already have a TUN
	   source address, notably with source-specific IPv6 WAN defaults. Kernel
	   bypass cannot restore a WAN source; leave these flows to normal routing. */
	push(rules, {
		type: 'logical',
		mode: 'and',
		rules: [
			match_rule,
			{ source_ip_cidr: [tun_addr4, tun_addr6], invert: true }
		],
		action: 'bypass'
	});
}

function tun_match(match_rule) {
	if (!match_rule)
		return null;
	return {
		type: 'logical',
		mode: 'and',
		rules: [
			{ inbound: 'tun-in' },
			match_rule
		]
	};
}

function tun_unlisted_match(match_rule) {
	if (!match_rule)
		return { inbound: 'tun-in' };

	return tun_match({ ...match_rule, invert: !match_rule.invert });
}

function merge_matches(matches) {
	const rules = filter(matches, (rule) => rule);
	if (length(rules) === 1)
		return rules[0];
	if (length(rules) > 1)
		return { type: 'logical', mode: 'or', rules };
	return null;
}

function get_control_matches() {
	const included_ports = routing_port_match();
	const proxy_source = lan_policy.use_proxy_list ?
		source_match('lan_proxy_ipv4_ips', null, 'lan_proxy_mac_addrs') : null;
	const auto_source = lan_policy.use_rule_proxy_list ?
		source_match('lan_auto_proxy_ipv4_ips', null, 'lan_auto_proxy_mac_addrs') : null;

	return {
		restrict_to_list: lan_policy.restrict_to_list,
		direct_source: lan_policy.use_direct_list ?
			source_match('lan_direct_ipv4_ips', null, 'lan_direct_mac_addrs') : null,
		proxy_source,
		auto_source,
		listed_source: lan_policy.restrict_to_list ? merge_matches([auto_source, proxy_source]) : null,
		wan_proxy: lan_policy.use_proxy_list ? destination_match('wan_proxy_ipv4_ips', 'wan_proxy_ipv6_ips') : null,
		wan_direct: destination_match('wan_direct_ipv4_ips', 'wan_direct_ipv6_ips'),
		bypass_ports: included_ports ? { ...included_ports, invert: true } : null
	};
}

function add_control_pre_match_policy_rules(rules, proxy_outbound) {
	const control = get_control_matches();

	if (control.restrict_to_list)
		push_bypass(rules, tun_unlisted_match(control.listed_source));
	else
		push_bypass(rules, tun_match(control.direct_source));

	if (proxy_outbound) {
		push_route(rules, tun_match(control.proxy_source), proxy_outbound);
		push_route(rules, tun_match(control.wan_proxy), proxy_outbound);
	}
	push_bypass(rules, tun_match(control.wan_direct));
	return control;
}

function add_control_pre_match_fallback_rules(rules, control) {
	push_bypass(rules, tun_match({ ip_is_private: true }));
	push_bypass(rules, tun_match(control.bypass_ports));
}

function add_control_policy_rules(rules, proxy_outbound) {
	const control = get_control_matches();

	/* A `bypass` rule without `outbound` only matches in auto-redirect pre-match
	   and is skipped for established or non-auto-redirect connections, so list
	   mode needs a normal-path counterpart: otherwise traffic from devices that
	   are not in either list falls through to the proxied final outbound. */
	if (control.restrict_to_list)
		push_route(rules, tun_unlisted_match(control.listed_source), 'direct-out');

	push_route(rules, control.direct_source, 'direct-out');

	if (proxy_outbound) {
		push_route(rules, control.proxy_source, proxy_outbound);
		push_route(rules, control.wan_proxy, proxy_outbound);
	}
	push_route(rules, control.wan_direct, 'direct-out');
	return control;
}

function add_control_fallback_rules(rules, control) {
	push(rules, { ip_is_private: true, action: 'route', outbound: 'direct-out' });
	push_route(rules, control.bypass_ports, 'direct-out');
}

function has_mac_control() {
	return length(merge_control_options([
		lan_policy.use_direct_list ? 'lan_direct_mac_addrs' : null,
		lan_policy.use_proxy_list ? 'lan_proxy_mac_addrs' : null,
		lan_policy.use_rule_proxy_list ? 'lan_auto_proxy_mac_addrs' : null
	])) > 0;
}

function add_mainland_rule_sets(rule_sets) {
	push(rule_sets, {
		type: 'local',
		tag: 'geoip-cn',
		format: 'binary',
		path: HP_DIR + '/resources/geoip_cn.srs'
	});
	push(rule_sets, {
		type: 'local',
		tag: 'geosite-cn',
		format: 'binary',
		path: HP_DIR + '/resources/geosite_cn.srs'
	});
}

function parse_dnsserver(server_addr, default_protocol) {
	if (isEmpty(server_addr))
		return null;

	if (!match(server_addr, /:\/\//))
		server_addr = (default_protocol || 'udp') + '://' + (validation('ip6addr', server_addr) ? `[${server_addr}]` : server_addr);
	server_addr = parseURL(server_addr);

	return {
		type: server_addr.protocol,
		server: server_addr.hostname,
		server_port: strToInt(server_addr.port),
		path: (server_addr.pathname !== '/') ? server_addr.pathname : null,
	}
}

function generate_outbound(node) {
	const outbound = renderOutbound(node);
	if (outbound && node['.name'])
		outbound.tag = get_node_outbound_tag(node['.name']);
	return outbound;
}

function generate_endpoint(node) {
	const endpoint = renderEndpoint(node);
	if (endpoint && node['.name'])
		endpoint.tag = get_node_outbound_tag(node['.name']);
	return endpoint;
}

/* Config helper end */

const config = {};

/* Log */
config.log = {
	disabled: false,
	level: log_level,
	output: RUN_DIR + '/sing-box-c.log',
	timestamp: true
};

/* HTTP clients */
config.http_clients = [
	{
		tag: 'direct-http'
	}
];

/* NTP */
if (!isEmpty(ntp_server))
	config.ntp = {
		enabled: true,
		server: ntp_server,
		detour: 'direct-out',
		domain_resolver: make_domain_resolver(),
	};

/* DNS start */
/* Default settings */
config.dns = {
	servers: [
		{
			tag: 'default-dns',
			type: 'udp',
			server: wan_dns,
			detour: null
		}
	],
	rules: [],
	reverse_mapping: true,
	strategy: dns_default_strategy
};

if (!isEmpty(main_node)) {
	/* Main DNS */
	push(config.dns.servers, {
		tag: 'main-dns',
		domain_resolver: make_domain_resolver(),
		detour: 'main-out',
		...parse_dnsserver(dns_server, 'tcp')
	});
	/* Bypass mode resolves everything unmatched through the mainland server. */
	config.dns.final = (routing_mode === 'bypass_mainland_china') ? 'china-dns' : 'main-dns';

	if (tailscale_enabled) {
		push(config.dns.servers, {
			type: 'tailscale',
			tag: 'tailscale-dns',
			endpoint: tailscale_tag
		});
		push(config.dns.rules, {
			preferred_by: 'tailscale-dns',
			action: 'route',
			server: 'tailscale-dns'
		});
	}

	let diversion_dns_servers = {};
	function domain_group_dns_server(group) {
		if (group.kind === 'direct')
			return (routing_mode === 'bypass_mainland_china') ? 'china-dns' : 'default-dns';
		if (group.kind === 'main' || domain_group_outbound_tag(group) === 'main-out')
			return 'main-dns';

		const outbound = domain_group_outbound_tag(group);
		if (outbound in diversion_dns_servers)
			return diversion_dns_servers[outbound];

		const tag = `domain-${group.id}-dns`;
		diversion_dns_servers[outbound] = tag;
		push(config.dns.servers, {
			tag,
			domain_resolver: make_domain_resolver(),
			detour: outbound,
			...parse_dnsserver(dns_server, 'tcp')
		});
		return tag;
	}

	function add_domain_dns_rules(group) {
		const server = domain_group_dns_server(group);
		if (length(group.suffixes))
			push(config.dns.rules, {
				rule_set: domain_rule_set_tag(group, 'suffix'),
				action: 'route',
				server
			});
		if (length(group.keywords))
			push(config.dns.rules, {
				rule_set: domain_rule_set_tag(group, 'keyword'),
				action: 'route',
				server
			});
	}

	for (let group in domain_groups)
		add_domain_dns_rules(group);

	if (routing_mode === 'bypass_mainland_china') {
		push(config.dns.servers, {
			tag: 'china-dns',
			domain_resolver: make_domain_resolver(),
			detour: null,
			...parse_dnsserver(china_dns_server)
		});

		push(config.dns.rules, {
			rule_set: 'geosite-cn',
			action: 'route',
			server: 'china-dns'
		});
		push(config.dns.rules, {
			action: 'evaluate',
			server: 'main-dns',
			timeout: dns_evaluate_timeout
		});
		push(config.dns.rules, {
			rule_set: 'geoip-cn',
			match_response: true,
			action: 'route',
			server: 'china-dns'
		});
		push(config.dns.rules, {
			match_response: true,
			action: 'respond'
		});
	}
}
/* DNS end */

/* Inbound start */
config.inbounds = [];

push(config.inbounds, {
	type: 'direct',
	tag: 'dns-in',
	listen: '::',
	listen_port: int(dns_port)
});

push(config.inbounds, {
	type: 'mixed',
	tag: 'mixed-in',
	listen: '::',
	listen_port: int(mixed_port),
	udp_timeout,
	set_system_proxy: false
});

push(config.inbounds, {
	type: 'tun',
	tag: 'tun-in',

	interface_name: tun_name,
	address: [tun_addr4, tun_addr6],
	mtu: strToInt(tun_mtu),
	auto_route: true,
	auto_redirect: true,
	include_interface: length(listen_interfaces) ? listen_interfaces : null,
	udp_timeout,
	multi_queue
});
/* Inbound end */

/* Outbound start */
config.endpoints = [];

if (tailscale_enabled)
	push(config.endpoints, {
		type: 'tailscale',
		tag: tailscale_tag,
		state_directory: HP_DIR + '/tailscale',
		taildrop_directory: HP_DIR + '/tailscale/taildrop',
		auth_key: tailscale_auth_key,
		control_url: tailscale_control_url,
		hostname: tailscale_hostname,
		accept_routes: tailscale_accept_routes,
		exit_node: tailscale_exit_node,
		exit_node_allow_lan_access: !isEmpty(tailscale_exit_node) ?
			tailscale_exit_node_allow_lan_access : null,
		advertise_routes: tailscale_advertise_routes,
		advertise_exit_node: tailscale_advertise_exit_node,
		listen_port: strToInt(tailscale_listen_port)
	});

/* Default outbounds */
config.outbounds = [
	{
		type: 'direct',
		tag: 'direct-out'
	}
];

/* Main outbounds */
if (!isEmpty(main_node)) {
	let emitted_nodes = {}, urltest_nodes = [];
	function append_required_node(section_id, tag) {
		if (section_id in emitted_nodes)
			return;

		const node = uci.get_all(uciconfig, section_id) || {};
		if (isEmpty(node))
			die(`Node ${section_id} is unavailable.`);

		emitted_nodes[section_id] = true;
		if (node.type === 'wireguard') {
			const endpoint = generate_endpoint(node);
			if (endpoint) {
				endpoint.tag = tag || get_node_outbound_tag(section_id);
				push(config.endpoints, endpoint);
			}
		} else {
			const outbound = generate_outbound(node);
			if (outbound) {
				addECHDNS(config, node, make_domain_resolver());
				outbound.tag = tag || get_node_outbound_tag(section_id);
				push(config.outbounds, outbound);
			}
		}
	}

	if (main_node === 'urltest') {
		urltest_nodes = filterExistingNodes(
			uci, uciconfig, uci.get(uciconfig, ucimain, 'main_urltest_nodes')
		);
		if (!length(urltest_nodes))
			die('Main URLTest group has no available nodes.');
		const main_urltest_interval = uci.get(uciconfig, ucimain, 'main_urltest_interval') || '60';
		const tolerance_value = uci.get(uciconfig, ucimain, 'main_urltest_tolerance') || '60';
		if (!match(tolerance_value, /^[0-9]{1,5}$/) || int(tolerance_value) > 65535)
			die('Main URLTest tolerance must be an integer from 0 to 65535 milliseconds.');
		const main_urltest_tolerance = int(tolerance_value);
		const main_urltest_interrupt = uci.get(uciconfig, ucimain, 'main_urltest_interrupt_exist_connections') || '0';

		push(config.outbounds, {
			type: 'urltest',
			tag: 'main-out',
			outbounds: map(urltest_nodes, (k) => get_node_outbound_tag(k)),
			interval: strToTime(main_urltest_interval),
			tolerance: main_urltest_tolerance,
			idle_timeout: (strToInt(main_urltest_interval) > 1800) ? `${main_urltest_interval * 2}s` : null,
			interrupt_exist_connections: strToBool(main_urltest_interrupt)
		});
	} else {
		append_required_node(main_node, 'main-out');
	}

	for (let i in urltest_nodes) {
		append_required_node(i);
	}

	for (let group in domain_groups)
		if (group.kind === 'node' && !(group.node === main_node && main_node !== 'urltest'))
			append_required_node(group.node);
}

if (isEmpty(config.endpoints))
	config.endpoints = null;
/* Outbound end */

/* Routing rules start */
/* Default settings */
config.route = {
	rules: [
		{
			inbound: 'dns-in',
			action: 'hijack-dns'
		}
	],
	rule_set: [],
	auto_detect_interface: isEmpty(default_interface) ? true : null,
	default_interface: default_interface,
	find_neighbor: has_mac_control() ? true : null
};
config.route.default_http_client = 'direct-http';

/* Routing rules */
if (!isEmpty(main_node)) {
	/* Avoid DNS loop */
	config.route.default_domain_resolver = make_domain_resolver(
		(routing_mode === 'bypass_mainland_china') ? 'china-dns' : 'default-dns'
	);

	/* Native auto_redirect pre-match: handle device and address exceptions first. */
	const pre_match_control = add_control_pre_match_policy_rules(config.route.rules, 'main-out');

	for (let group in domain_groups) {
		const outbound = domain_group_outbound_tag(group);
		for (let type in ['suffix', 'keyword']) {
			const domains = type === 'suffix' ? group.suffixes : group.keywords;
			if (!length(domains))
				continue;

			const match_rule = tun_match({ rule_set: domain_rule_set_tag(group, type) });
			if (group.kind === 'direct')
				push_bypass(config.route.rules, match_rule);
			else
				push_route(config.route.rules, match_rule, outbound);
		}
	}

	if (tailscale_enabled) {
		push_route(config.route.rules, { inbound: tailscale_tag }, 'direct-out');
		push_route(config.route.rules, { preferred_by: tailscale_tag }, tailscale_tag);
	}
	add_control_pre_match_fallback_rules(config.route.rules, pre_match_control);

	if (routing_mode === 'bypass_mainland_china') {
		push_bypass(config.route.rules, tun_match({ rule_set: 'geosite-cn' }));
		push_bypass(config.route.rules, tun_match({ rule_set: 'geoip-cn' }));
	}

	push(config.route.rules, { action: 'sniff' });
	const control = add_control_policy_rules(config.route.rules, 'main-out');

	for (let group in domain_groups) {
		const outbound = domain_group_outbound_tag(group);
		if (length(group.suffixes))
			push(config.route.rules, {
				rule_set: domain_rule_set_tag(group, 'suffix'),
				action: 'route',
				outbound
			});
		if (length(group.keywords))
			push(config.route.rules, {
				rule_set: domain_rule_set_tag(group, 'keyword'),
				action: 'route',
				outbound
			});
	}

	if (tailscale_enabled)
		push_route(config.route.rules, { preferred_by: tailscale_tag }, tailscale_tag);
	add_control_fallback_rules(config.route.rules, control);

	if (routing_mode === 'bypass_mainland_china') {
		push(config.route.rules, {
			rule_set: 'geosite-cn',
			action: 'route',
			outbound: 'direct-out'
		});
		push(config.route.rules, {
			rule_set: 'geoip-cn',
			action: 'route',
			outbound: 'direct-out'
		});
	}

	config.route.final = 'main-out';

	for (let group in domain_groups) {
		add_inline_domain_rule_set(config.route.rule_set, group, 'suffix');
		add_inline_domain_rule_set(config.route.rule_set, group, 'keyword');
	}

	if (routing_mode === 'bypass_mainland_china') {
		add_mainland_rule_sets(config.route.rule_set);
	}

	if (isEmpty(config.route.rule_set))
		config.route.rule_set = null;
}
/* Routing rules end */

/* Experimental start */
/* The cache file only persists Clash API state such as the clash mode and the
   selected group member, so it is only worth writing while the API is enabled. */
const enable_clash_api = main_node === 'urltest';
if (enable_clash_api) {
	config.experimental = {
		clash_api: {
			external_controller: `127.0.0.1:${clash_api_port}`
		},
		cache_file: {
			enabled: true,
			path: HP_DIR + '/cache/cache.db',
			store_dns: false
		}
	};
}
/* Experimental end */

/* Services */
if (dashboard_enabled || tailscale_enabled)
	config.services = [
		{
			type: 'api',
			tag: 'api',
			listen: dashboard_enabled ? '::' : '127.0.0.1',
			listen_port: dashboard_port,
			secret: dashboard_secret,
			dashboard: dashboard_enabled ? {
				enabled: true,
				path: dashboard_path
			} : null
		}
	];

system('mkdir -p ' + RUN_DIR);
if (!writefile(RUN_DIR + '/sing-box-c.json.new', sprintf('%.J\n', removeBlankAttrs(config))))
	exit(1);
